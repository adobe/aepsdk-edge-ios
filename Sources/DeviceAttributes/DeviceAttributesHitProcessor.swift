//
// Copyright 2026 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPCore
import AEPServices
import Foundation

/// Processes hits from the consent-independent device-attributes queue.
/// Fully separate from `EdgeHitProcessor`: it does not use `NetworkResponseHandler` and never dispatches Edge
/// response/error events. The response body is not parsed: the outcome is decided by the status code only, and response
/// handles such as `locationHint:result` and `state:store` are ignored, so the Edge location hint and stored payloads are
/// never updated by this flow. Every device attributes request event yields exactly one device attributes response event. Before each send attempt
/// the ECID queued with the hit is compared with the latest Edge Identity ECID; a hit whose ECID has changed is dropped.
class DeviceAttributesHitProcessor: HitProcessing {
    private let SELF_TAG = "DeviceAttributesHitProcessor"
    private let networkService: DeviceAttributesNetworkService
    private let sharedStateReader: SharedStateReader
    private let getImplementationDetails: () -> [String: Any]?
    private let getLocationHint: () -> String?
    private let getLatestIdentityMap: () -> [String: Any]?
    private let dispatch: (Event) -> Void
    private let storeDataStoreName: String
    private let entityRetryIntervalMapping = ThreadSafeDictionary<String, TimeInterval>()

    /// - Parameters:
    ///   - networkService: sender for the device-attributes request
    ///   - sharedStateReader: used to read the Assurance integration id
    ///   - getImplementationDetails: returns the current `implementationDetails`
    ///   - getLocationHint: returns the current Edge Network location hint
    ///   - getLatestIdentityMap: returns the latest Edge Identity XDM shared state (containing `identityMap`), or nil if unavailable
    ///   - dispatch: dispatches the device attributes response event
    ///   - storeDataStoreName: data store holding the `state:store` payloads sent as `meta.state`
    init(networkService: DeviceAttributesNetworkService = DeviceAttributesNetworkService(),
         sharedStateReader: SharedStateReader,
         getImplementationDetails: @escaping () -> [String: Any]?,
         getLocationHint: @escaping () -> String?,
         getLatestIdentityMap: @escaping () -> [String: Any]?,
         dispatch: @escaping (Event) -> Void,
         storeDataStoreName: String = EdgeConstants.DataStoreKeys.STORE_NAME) {
        self.networkService = networkService
        self.sharedStateReader = sharedStateReader
        self.getImplementationDetails = getImplementationDetails
        self.getLocationHint = getLocationHint
        self.getLatestIdentityMap = getLatestIdentityMap
        self.dispatch = dispatch
        self.storeDataStoreName = storeDataStoreName
    }

    // MARK: HitProcessing

    func retryInterval(for entity: DataEntity) -> TimeInterval {
        return entityRetryIntervalMapping[entity.uniqueIdentifier] ?? EdgeConstants.Defaults.RETRY_INTERVAL
    }

    func processHit(entity: DataEntity, completion: @escaping (Bool) -> Void) {
        guard let data = entity.data, let edgeEntity = try? JSONDecoder().decode(EdgeDataEntity.self, from: data) else {
            Log.error(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Dropping undecodable device attributes hit '\(entity.uniqueIdentifier)'.")
            dispatch(Event.createDeviceAttributesDroppedResponse(requestEventId: entity.uniqueIdentifier))
            complete(entity: entity, completion: completion)
            return
        }

        let event = edgeEntity.event
        let snapshotIdentity = AnyCodable.toAnyDictionary(dictionary: edgeEntity.identityMap)

        // Checked on every attempt so hits waiting in retry backoff or restored after relaunch are covered.
        guard let latestIdentity = getLatestIdentityMap() else {
            Log.debug(label: EdgeConstants.LOG_TAG,
                      "\(SELF_TAG) - Latest Identity shared state is unavailable, will retry device attributes hit '\(entity.uniqueIdentifier)'.")
            entityRetryIntervalMapping[entity.uniqueIdentifier] = nil
            completion(false)
            return
        }

        guard ecid(from: snapshotIdentity) == ecid(from: latestIdentity) else {
            Log.debug(label: EdgeConstants.LOG_TAG,
                      "\(SELF_TAG) - ECID changed since device attributes hit '\(entity.uniqueIdentifier)' was queued, dropping.")
            finish(entity: entity,
                   event: event,
                   response: event.createDeviceAttributesResponse(status: EdgeConstants.DeviceAttributes.Status.DROPPED,
                                                                  reason: EdgeConstants.DeviceAttributes.Reason.IDENTITY_CHANGED),
                   completion: completion)
            return
        }

        sendRequest(entity: entity, edgeEntity: edgeEntity, snapshotIdentity: snapshotIdentity, completion: completion)
    }

    // MARK: Private

    /// Builds and sends the device-attributes request for a hit that passed the ECID check.
    private func sendRequest(entity: DataEntity,
                             edgeEntity: EdgeDataEntity,
                             snapshotIdentity: [String: Any]?,
                             completion: @escaping (Bool) -> Void) {
        let event = edgeEntity.event
        let edgeConfig = edgeEntity.configuration.asAnyDictionary.compactMapValues { $0 as? String }
        guard let datastreamId = edgeConfig[EdgeConstants.SharedState.Configuration.CONFIG_ID], !datastreamId.isEmpty else {
            Log.warning(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Missing datastream id, dropping device attributes hit '\(entity.uniqueIdentifier)'.")
            finish(entity: entity,
                   event: event,
                   response: event.createDeviceAttributesResponse(status: EdgeConstants.DeviceAttributes.Status.DROPPED,
                                                                  reason: EdgeConstants.DeviceAttributes.Reason.MISSING_CONFIG),
                   completion: completion)
            return
        }

        let identityMap = snapshotIdentity?[EdgeConstants.SharedState.Identity.IDENTITY_MAP] as? [String: Any]
        let requestBuilder = DeviceAttributesRequestBuilder(dataStoreName: storeDataStoreName)
        let endpoint = EdgeEndpoint(requestType: .deviceAttributes,
                                    environmentType: EdgeEnvironmentType(optionalRawValue: edgeConfig[EdgeConstants.SharedState.Configuration.EDGE_ENVIRONMENT]),
                                    optionalDomain: edgeConfig[EdgeConstants.SharedState.Configuration.EDGE_DOMAIN],
                                    optionalPath: nil,
                                    locationHint: getLocationHint())
        guard let body = requestBuilder.buildRequestBody(eventData: event.data,
                                                         implementationDetails: getImplementationDetails(),
                                                         identityMap: identityMap),
              let url = networkService.buildUrl(endpoint: endpoint, datastreamId: datastreamId, requestId: UUID().uuidString) else {
            Log.warning(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Unable to build device attributes request, dropping hit '\(entity.uniqueIdentifier)'.")
            finish(entity: entity,
                   event: event,
                   response: event.createDeviceAttributesResponse(status: EdgeConstants.DeviceAttributes.Status.DROPPED,
                                                                  reason: EdgeConstants.DeviceAttributes.Reason.INVALID_PAYLOAD),
                   completion: completion)
            return
        }

        networkService.send(url: url, body: body, headers: getRequestHeaders(event)) { [weak self] result in
            guard let self = self else {
                completion(false)
                return
            }
            self.handleNetworkResult(result, entity: entity, event: event, completion: completion)
        }
    }

    private func handleNetworkResult(_ result: DeviceAttributesNetworkResult,
                                     entity: DataEntity,
                                     event: Event,
                                     completion: @escaping (Bool) -> Void) {
        switch result {
        case let .success(httpStatus):
            finish(entity: entity,
                   event: event,
                   response: event.createDeviceAttributesResponse(status: EdgeConstants.DeviceAttributes.Status.SUCCESS, httpStatus: httpStatus),
                   completion: completion)
        case let .retry(interval):
            entityRetryIntervalMapping[entity.uniqueIdentifier] = interval
            completion(false)
        case let .failed(httpStatus):
            finish(entity: entity,
                   event: event,
                   response: event.createDeviceAttributesResponse(status: EdgeConstants.DeviceAttributes.Status.FAILED,
                                                                  reason: EdgeConstants.DeviceAttributes.Reason.NETWORK,
                                                                  httpStatus: httpStatus),
                   completion: completion)
        }
    }

    /// Dispatches the device attributes response event and removes the hit from the queue.
    private func finish(entity: DataEntity, event: Event, response: Event, completion: @escaping (Bool) -> Void) {
        dispatch(response)
        complete(entity: entity, completion: completion)
    }

    private func complete(entity: DataEntity, completion: @escaping (Bool) -> Void) {
        entityRetryIntervalMapping[entity.uniqueIdentifier] = nil
        completion(true)
    }

    /// Returns `identityMap.ECID[0].id` from an Edge Identity XDM shared state. Index 0 is Edge Identity's current ECID;
    /// a legacy ECID, if any, follows it and is not compared.
    private func ecid(from identityState: [String: Any]?) -> String? {
        let identityMap = identityState?[EdgeConstants.SharedState.Identity.IDENTITY_MAP] as? [String: Any]
        let ecids = identityMap?[EdgeConstants.JsonKeys.ECID] as? [[String: Any]]
        return ecids?.first?["id"] as? String
    }

    /// Adds the Assurance integration id header when Assurance is enabled.
    private func getRequestHeaders(_ event: Event) -> [String: String] {
        var requestHeaders: [String: String] = [:]
        if let assuranceIntegrationId = sharedStateReader.getAssuranceIntegrationId(event: event) {
            requestHeaders[EdgeConstants.NetworkKeys.HEADER_KEY_AEP_VALIDATION_TOKEN] = assuranceIntegrationId
        }
        return requestHeaders
    }
}

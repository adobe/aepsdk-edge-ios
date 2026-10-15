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
/// response/error events. Every request event (E3) yields exactly one result event (E4), except hits queued
/// before an identities reset, which are discarded silently.
class DeviceAttributesHitProcessor: HitProcessing {
    private let SELF_TAG = "DeviceAttributesHitProcessor"
    private let networkService: DeviceAttributesNetworkService
    private let responseHandler: DeviceAttributesResponseHandler
    private let sharedStateReader: SharedStateReader
    private let getImplementationDetails: () -> [String: Any]?
    private let getLocationHint: () -> String?
    private let dispatch: (Event) -> Void
    private let storeDataStoreName: String
    private let edgeDataStore = NamedCollectionDataStore(name: EdgeConstants.EXTENSION_NAME)
    private let entityRetryIntervalMapping = ThreadSafeDictionary<String, TimeInterval>()

    /// - Parameters:
    ///   - networkService: sender for the device-attributes request
    ///   - sharedStateReader: used to read the Assurance integration id
    ///   - getImplementationDetails: returns the current `implementationDetails`
    ///   - getLocationHint: returns the current Edge Network location hint
    ///   - updateLocationHint: sets the Edge Network location hint received in the response
    ///   - dispatch: dispatches the result event (E4)
    ///   - storeDataStoreName: data store holding the `state:store` payloads
    init(networkService: DeviceAttributesNetworkService = DeviceAttributesNetworkService(),
         sharedStateReader: SharedStateReader,
         getImplementationDetails: @escaping () -> [String: Any]?,
         getLocationHint: @escaping () -> String?,
         updateLocationHint: @escaping (String, TimeInterval) -> Void,
         dispatch: @escaping (Event) -> Void,
         storeDataStoreName: String = EdgeConstants.DataStoreKeys.STORE_NAME) {
        self.networkService = networkService
        self.responseHandler = DeviceAttributesResponseHandler(dataStoreName: storeDataStoreName, updateLocationHint: updateLocationHint)
        self.sharedStateReader = sharedStateReader
        self.getImplementationDetails = getImplementationDetails
        self.getLocationHint = getLocationHint
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
            dispatch(Event.createBypassDropResult(requestEventId: entity.uniqueIdentifier))
            complete(entity: entity, completion: completion)
            return
        }

        let event = edgeEntity.event

        // Checked on every attempt so hits waiting in retry backoff or restored after relaunch are covered.
        if isQueuedBeforeIdentitiesReset(entity) {
            // Identity already reports the reset to the requester, so no result event is dispatched.
            Log.debug(label: EdgeConstants.LOG_TAG,
                      "\(SELF_TAG) - Discarding device attributes hit '\(entity.uniqueIdentifier)' queued before identities reset.")
            complete(entity: entity, completion: completion)
            return
        }

        let edgeConfig = edgeEntity.configuration.asAnyDictionary.compactMapValues { $0 as? String }
        guard let datastreamId = edgeConfig[EdgeConstants.SharedState.Configuration.CONFIG_ID], !datastreamId.isEmpty else {
            Log.warning(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Missing datastream id, dropping device attributes hit '\(entity.uniqueIdentifier)'.")
            finish(entity: entity,
                   event: event,
                   result: event.createBypassResult(status: EdgeConstants.BypassResult.Status.DROPPED,
                                                    reason: EdgeConstants.BypassResult.Reason.MISSING_CONFIG),
                   completion: completion)
            return
        }

        let identityMap = AnyCodable.toAnyDictionary(dictionary: edgeEntity.identityMap)?[EdgeConstants.SharedState.Identity.IDENTITY_MAP] as? [String: Any]
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
                   result: event.createBypassResult(status: EdgeConstants.BypassResult.Status.DROPPED,
                                                    reason: EdgeConstants.BypassResult.Reason.INVALID_PAYLOAD),
                   completion: completion)
            return
        }

        networkService.send(url: url, body: body, headers: getRequestHeaders(event)) { [weak self] result in
            guard let self = self else {
                completion(false)
                return
            }
            self.handle(result: result, entity: entity, event: event, completion: completion)
        }
    }

    // MARK: Private

    private func handle(result: DeviceAttributesNetworkResult, entity: DataEntity, event: Event, completion: @escaping (Bool) -> Void) {
        switch result {
        case let .success(httpStatus, body):
            // Mirrors the interact path: state:store from a request sent before a reset must not overwrite post-reset state.
            responseHandler.handle(responseBody: body, applyStorePayloads: !isQueuedBeforeIdentitiesReset(entity))
            finish(entity: entity,
                   event: event,
                   result: event.createBypassResult(status: EdgeConstants.BypassResult.Status.SUCCESS, httpStatus: httpStatus),
                   completion: completion)
        case let .retry(interval):
            entityRetryIntervalMapping[entity.uniqueIdentifier] = interval
            completion(false)
        case let .failed(httpStatus):
            finish(entity: entity,
                   event: event,
                   result: event.createBypassResult(status: EdgeConstants.BypassResult.Status.FAILED,
                                                    reason: EdgeConstants.BypassResult.Reason.NETWORK,
                                                    httpStatus: httpStatus),
                   completion: completion)
        }
    }

    /// Dispatches the terminal result event and removes the hit from the queue.
    private func finish(entity: DataEntity, event: Event, result: Event, completion: @escaping (Bool) -> Void) {
        dispatch(result)
        complete(entity: entity, completion: completion)
    }

    private func complete(entity: DataEntity, completion: @escaping (Bool) -> Void) {
        entityRetryIntervalMapping[entity.uniqueIdentifier] = nil
        completion(true)
    }

    /// Reads the identities reset date persisted by `NetworkResponseHandler.setLastReset` (read-only).
    private func isQueuedBeforeIdentitiesReset(_ entity: DataEntity) -> Bool {
        guard let resetTimestamp = edgeDataStore.getDouble(key: EdgeConstants.DataStoreKeys.RESET_IDENTITIES_DATE) else { return false }
        return entity.timestamp < Date(timeIntervalSince1970: resetTimestamp)
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

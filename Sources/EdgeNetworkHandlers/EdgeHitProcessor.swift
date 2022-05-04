//
// Copyright 2020 Adobe. All rights reserved.
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

/// A `HitProcessing` which handles the processing of `EdgeHit`s
class EdgeHitProcessor: HitProcessing {
    private let SELF_TAG = "EdgeHitProcessor"
    private var networkService: EdgeNetworkService
    private var networkResponseHandler: NetworkResponseHandler
    private var getSharedState: (String, Event?) -> SharedStateResult?
    private var getXDMSharedState: (String, Event?, Bool) -> SharedStateResult?
    private var readyForEvent: (Event) -> Bool
    private var getImplementationDetails: () -> [String: Any]?
    private var entityRetryIntervalMapping = ThreadSafeDictionary<String, TimeInterval>()

    init(networkService: EdgeNetworkService,
         networkResponseHandler: NetworkResponseHandler,
         getSharedState: @escaping (String, Event?) -> SharedStateResult?,
         getXDMSharedState: @escaping (String, Event?, Bool) -> SharedStateResult?,
         readyForEvent: @escaping (Event) -> Bool,
         getImplementationDetails: @escaping () -> [String: Any]?) {
        self.networkService = networkService
        self.networkResponseHandler = networkResponseHandler
        self.getSharedState = getSharedState
        self.getXDMSharedState = getXDMSharedState
        self.readyForEvent = readyForEvent
        self.getImplementationDetails = getImplementationDetails
    }

    // MARK: HitProcessing

    func retryInterval(for entity: DataEntity) -> TimeInterval {
        return entityRetryIntervalMapping[entity.uniqueIdentifier] ?? EdgeConstants.Defaults.RETRY_INTERVAL
    }

    func processHit(entity: DataEntity, completion: @escaping (Bool) -> Void) {
        guard let edgeEntity = decode(dataEntity: entity) else {
            // can't convert data to hit, unrecoverable error, move to next hit
            completion(true)
            return
        }

        let event = edgeEntity.event
        guard readyForEvent(event) else {
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Not ready for event, will retry hit with id '\(entity.uniqueIdentifier)'.")
            completion(false)
            return
        }

        // fetch config keys for Edge extension
        guard let edgeConfig = getEdgeConfig(event: event), let configId = edgeConfig[EdgeConstants.SharedState.Configuration.CONFIG_ID] else {
            completion(true)
            return // drop current event
        }

        // Build Request object
        let requestBuilder = RequestBuilder()
        // attach identity map
        let identityState = AnyCodable.toAnyDictionary(dictionary: edgeEntity.identityMap)
        requestBuilder.xdmPayloads[EdgeConstants.SharedState.Identity.IDENTITY_MAP] =
            AnyCodable(identityState?[EdgeConstants.SharedState.Identity.IDENTITY_MAP])

        // Enable response streaming for all events
        requestBuilder.enableResponseStreaming(recordSeparator: EdgeConstants.Defaults.RECORD_SEPARATOR,
                                               lineFeed: EdgeConstants.Defaults.LINE_FEED)

        if event.isExperienceEvent {
            guard let eventData = event.data, !eventData.isEmpty else {
                Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Failed to process Experience event, data was nil or empty")
                completion(true)
                return
            }

            if let implementationDetails = getImplementationDetails() {
                requestBuilder.xdmPayloads[EdgeConstants.JsonKeys.IMPLEMENTATION_DETAILS] = AnyCodable(implementationDetails)
            }

            // Build and send the network request to Experience Edge
            let listOfEvents: [Event] = [event]

            guard let requestPayload = requestBuilder.getPayloadWithExperienceEvents(listOfEvents) else {
                Log.debug(label: EdgeConstants.LOG_TAG,
                          "\(SELF_TAG) - Failed to build the request payload, dropping event '\(event.id.uuidString)'.")
                completion(true)
                return
            }

            let endpoint = buildEdgeEndpoint(config: edgeConfig, requestType: EdgeRequestType.interact)
            let edgeHit = ExperienceEventsEdgeHit(endpoint: endpoint, configId: configId, request: requestPayload)
            // NOTE: the order of these events needs to be maintained as they were sent in the network request
            // otherwise the response callback cannot be matched
            networkResponseHandler.addWaitingEvents(requestId: edgeHit.requestId,
                                                    batchedEvents: listOfEvents)
            sendHit(entityId: entity.uniqueIdentifier, edgeHit: edgeHit, headers: getRequestHeaders(event), completion: completion)
        } else if event.isUpdateConsentEvent {
            guard let eventData = event.data, !eventData.isEmpty else {
                Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Failed to process Consent event, data was nil or empty")
                completion(true)
                return
            }

            // Build and send the consent network request to Experience Edge
            guard let consentPayload = requestBuilder.getConsentPayload(event) else {
                Log.debug(label: EdgeConstants.LOG_TAG,
                          "\(SELF_TAG) - Failed to build the consent payload, dropping event '\(event.id.uuidString)'.")
                completion(true)
                return
            }

            let endpoint = buildEdgeEndpoint(config: edgeConfig, requestType: EdgeRequestType.consent)
            let edgeHit = ConsentEdgeHit(endpoint: endpoint, configId: configId, consents: consentPayload)
            networkResponseHandler.addWaitingEvent(requestId: edgeHit.requestId, event: event)
            sendHit(entityId: entity.uniqueIdentifier, edgeHit: edgeHit, headers: getRequestHeaders(event), completion: completion)
        } else if event.isResetIdentitiesEvent {
            // reset stored payloads as part of processing the reset hit
            let storeResponsePayloadManager = StoreResponsePayloadManager(EdgeConstants.DataStoreKeys.STORE_NAME)
            storeResponsePayloadManager.deleteAllStorePayloads()
            completion(true)
        }
    }

    /// Builds the endpoint based on the provided config info and `EdgeRequestType`
    /// - Parameters:
    ///   - config: configuration data, used to extract the environment and the custom domain, if any
    ///   - requestType: the `EdgeRequestType`
    private func buildEdgeEndpoint(config: [String: String], requestType: EdgeRequestType) -> EdgeEndpoint {
        return EdgeEndpoint(
            requestType: requestType,
            environmentType: EdgeEnvironmentType(optionalRawValue: config[EdgeConstants.SharedState.Configuration.EDGE_ENVIRONMENT]),
            optionalDomain: config[EdgeConstants.SharedState.Configuration.EDGE_DOMAIN])
    }

    private func decode(dataEntity: DataEntity) -> EdgeDataEntity? {
        guard let data = dataEntity.data, let edgeDataEntity = try? JSONDecoder().decode(EdgeDataEntity.self, from: data)
        else {

            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Failed to decode EdgeDataEntity with id '\(dataEntity.uniqueIdentifier)'.")
            return nil
        }

        return edgeDataEntity
    }

    /// Sends the `edgeHit` to the network service
    /// - Parameters:
    ///   - entityId: unique id of the `DataEntity`
    ///   - edgeHit: the hit to be sent
    ///   - headers: headers for the request
    ///   - completion: completion handler for the hit processor
    private func sendHit(entityId: String, edgeHit: EdgeHit, headers: [String: String], completion: @escaping (Bool) -> Void) {
        guard let url = networkService.buildUrl(endpoint: edgeHit.endpoint,
                                                configId: edgeHit.configId,
                                                requestId: edgeHit.requestId) else {
            Log.debug(label: EdgeConstants.LOG_TAG,
                      "\(SELF_TAG) - Failed to build the URL, dropping request with id '\(edgeHit.requestId)'.")
            completion(true)
            return
        }

        let callback = NetworkResponseCallback(requestId: edgeHit.requestId, responseHandler: networkResponseHandler)
        networkService.doRequest(url: url,
                                 requestBody: edgeHit.getPayload(),
                                 requestHeaders: headers,
                                 streaming: edgeHit.getStreamingSettings(),
                                 responseCallback: callback) { [weak self] success, retryInterval in
            // remove any retry interval if success, otherwise add to retry mapping
            self?.entityRetryIntervalMapping[entityId] = success ? nil : retryInterval
            completion(success)
        }
    }

    /// Extracts all the Edge configuration keys from the Configuration shared state
    /// - Parameter event: current event for which the configuration is required
    /// - Returns: the Edge configuration keys with values, nil if edge.configId was not found
    private func getEdgeConfig(event: Event) -> [String: String]? {
        guard let configSharedState =
                getSharedState(EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                               event)?.value else {
            Log.warning(label: EdgeConstants.LOG_TAG,
                        "\(SELF_TAG) - Unable to process the event '\(event.id.uuidString)', Configuration is nil.")
            return nil
        }

        guard let configId =
                configSharedState[EdgeConstants.SharedState.Configuration.CONFIG_ID] as? String,
              !configId.isEmpty else {
            Log.warning(label: EdgeConstants.LOG_TAG,
                        "\(SELF_TAG) - Unable to process the event '\(event.id.uuidString)' " +
                            "due to invalid edge.configId in configuration.")
            return nil
        }

        var config: [String: String] = [:]
        config[EdgeConstants.SharedState.Configuration.CONFIG_ID] = configId
        config[EdgeConstants.SharedState.Configuration.EDGE_ENVIRONMENT] = configSharedState[EdgeConstants.SharedState.Configuration.EDGE_ENVIRONMENT] as? String
        config[EdgeConstants.SharedState.Configuration.EDGE_DOMAIN] = configSharedState[EdgeConstants.SharedState.Configuration.EDGE_DOMAIN] as? String

        return config
    }

    /// Computes the request headers for provided `event`, including the `Assurance` integration identifier when `Assurance` is enabled
    /// - Returns: the network request headers as `[String: String]`
    private func getRequestHeaders(_ event: Event) -> [String: String] {
        // get Assurance integration id and include it in to the requestHeaders
        var requestHeaders: [String: String] = [:]
        if let assuranceSharedState = getSharedState(EdgeConstants.SharedState.Assurance.STATE_OWNER_NAME, event)?.value {
            if let assuranceIntegrationId = assuranceSharedState[EdgeConstants.SharedState.Assurance.INTEGRATION_ID] as? String {
                requestHeaders[EdgeConstants.NetworkKeys.HEADER_KEY_AEP_VALIDATION_TOKEN] = assuranceIntegrationId
            }
        }

        return requestHeaders
    }

}

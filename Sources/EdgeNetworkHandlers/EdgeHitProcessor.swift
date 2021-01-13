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
    private let LOG_TAG = "EdgeHitProcessor"
    private var networkService: EdgeNetworkService
    private var networkResponseHandler: NetworkResponseHandler
    private var getSharedState: (String, Event?) -> SharedStateResult?
    private var readyForEvent: (Event) -> Bool
    private var entityRetryIntervalMapping = ThreadSafeDictionary<String, TimeInterval>()

    init(networkService: EdgeNetworkService,
         networkResponseHandler: NetworkResponseHandler,
         getSharedState: @escaping (String, Event?) -> SharedStateResult?,
         readyForEvent: @escaping (Event) -> Bool) {
        self.networkService = networkService
        self.networkResponseHandler = networkResponseHandler
        self.getSharedState = getSharedState
        self.readyForEvent = readyForEvent
    }

    // MARK: HitProcessing

    func retryInterval(for entity: DataEntity) -> TimeInterval {
        return entityRetryIntervalMapping[entity.uniqueIdentifier] ?? EdgeConstants.Defaults.RETRY_INTERVAL
    }

    func processHit(entity: DataEntity, completion: @escaping (Bool) -> Void) {
        guard let data = entity.data, let event = try? JSONDecoder().decode(Event.self, from: data) else {
            // can't convert data to hit, unrecoverable error, move to next hit
            Log.debug(label: LOG_TAG, "processHit - Failed to decode edge hit with id '\(entity.uniqueIdentifier)'.")
            completion(true)
            return
        }

        guard readyForEvent(event) else {
            Log.debug(label: LOG_TAG, "processHit - readyForEvent returned false, will retry hit with id '\(entity.uniqueIdentifier)'.")
            completion(false)
            return
        }

        // fetch config shared state, this should be resolved based on readyForEvent check
        guard let configId = getEdgeConfigId(event: event) else {
            completion(true)
            return // drop current event
        }

        // get ECID from Identity shared state, this should be resolved based on readyForEvent check
        guard let identityState =
                getSharedState(EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                               event)?.value else {
            Log.warning(label: LOG_TAG,
                        "processHit - Unable to process the event '\(event.id.uuidString)', " +
                            "Identity shared state is nil.")
            completion(true)
            return // drop current event
        }

        // Build Request object
        let requestBuilder = RequestBuilder()
        requestBuilder.enableResponseStreaming(recordSeparator: EdgeConstants.Defaults.RECORD_SEPARATOR,
                                               lineFeed: EdgeConstants.Defaults.LINE_FEED)

        if let ecid = identityState[EdgeConstants.SharedState.Identity.ECID] as? String {
            requestBuilder.experienceCloudId = ecid
        } else {
            // This is not expected to happen. Continue without ECID
            Log.warning(label: LOG_TAG, "processHit - An unexpected error has occurred, ECID is nil.")
        }

        // Build and send the network request to Experience Edge
        let listOfEvents: [Event] = [event]
        guard let requestPayload = requestBuilder.getRequestPayload(listOfEvents) else {
            Log.debug(label: LOG_TAG,
                      "processHit - Failed to build the request payload, dropping current event '\(event.id.uuidString)'.")
            completion(true)
            return
        }

        // get Assurance integration id and include it in to the requestHeaders
        var requestHeaders: [String: String] = [:]
        if let assuranceSharedState = getSharedState(EdgeConstants.SharedState.Assurance.STATE_OWNER_NAME, event)?.value {
            if let assuranceIntegrationId = assuranceSharedState[EdgeConstants.SharedState.Assurance.INTEGRATION_ID] as? String {
                requestHeaders[EdgeConstants.NetworkKeys.HEADER_KEY_AEP_VALIDATION_TOKEN] = assuranceIntegrationId
            }
        }

        let edgeHit = EdgeHit(configId: configId, requestId: UUID().uuidString, request: requestPayload)
        // NOTE: the order of these events needs to be maintained as they were sent in the network request
        // otherwise the response callback cannot be matched
        networkResponseHandler.addWaitingEvents(requestId: edgeHit.requestId,
                                                batchedEvents: listOfEvents)
        sendHit(entityId: entity.uniqueIdentifier, edgeHit: edgeHit, headers: requestHeaders, completion: completion)
    }

    /// Sends the `edgeHit` to the network service
    /// - Parameters:
    ///   - entityId: unique id of the `DataEntity`
    ///   - edgeHit: the hit to be sent
    ///   - headers: headers for the request
    ///   - completion: completion handler for the hit processor
    private func sendHit(entityId: String, edgeHit: EdgeHit, headers: [String: String], completion: @escaping (Bool) -> Void) {
        guard let url = networkService.buildUrl(requestType: ExperienceEdgeRequestType.interact,
                                                configId: edgeHit.configId,
                                                requestId: edgeHit.requestId) else {
            Log.debug(label: LOG_TAG,
                      "handleExperienceEventRequest - Failed to build the URL, dropping current request with request id '\(edgeHit.requestId)'.")
            completion(true)
            return
        }

        let callback = NetworkResponseCallback(requestId: edgeHit.requestId, responseHandler: networkResponseHandler)
        networkService.doRequest(url: url,
                                 requestBody: edgeHit.request,
                                 requestHeaders: headers,
                                 responseCallback: callback) { [weak self] success, retryInterval in
            // remove any retry interval if success, otherwise add to retry mapping
            self?.entityRetryIntervalMapping[entityId] = success ? nil : retryInterval
            completion(success)
        }
    }

    /// Extracts the Edge Configuration identifier from the Configuration Shared State
    /// - Parameter event: current event for which the configuration is required
    /// - Returns: the Edge Configuration Id if found, nil otherwise
    private func getEdgeConfigId(event: Event) -> String? {
        guard let configSharedState =
                getSharedState(EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                               event)?.value else {
            Log.warning(label: LOG_TAG,
                        "getEdgeConfigId - Unable to process the event '\(event.id.uuidString)', Configuration shared state is nil.")
            return nil
        }

        guard let configId =
                configSharedState[EdgeConstants.SharedState.Configuration.CONFIG_ID] as? String,
              !configId.isEmpty else {
            Log.warning(label: LOG_TAG,
                        "getEdgeConfigId - Unable to process the event '\(event.id.uuidString)' " +
                            "because of invalid edge.configId in configuration.")
            return nil
        }

        return configId
    }

}

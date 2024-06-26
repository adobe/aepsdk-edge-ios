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
    private var sharedStateReader: SharedStateReader
    private var readyForEvent: (Event) -> Bool
    private var getImplementationDetails: () -> [String: Any]?
    private var getLocationHint: () -> String?
    private let entityRetryIntervalMapping = ThreadSafeDictionary<String, TimeInterval>()
    private let VALID_PATH_REGEX_PATTERN = "^\\/[/.a-zA-Z0-9-~_]+$"

    init(networkService: EdgeNetworkService,
         networkResponseHandler: NetworkResponseHandler,
         sharedStateReader: SharedStateReader,
         readyForEvent: @escaping (Event) -> Bool,
         getImplementationDetails: @escaping () -> [String: Any]?,
         getLocationHint: @escaping () -> String?) {
        self.networkService = networkService
        self.networkResponseHandler = networkResponseHandler
        self.sharedStateReader = sharedStateReader
        self.readyForEvent = readyForEvent
        self.getImplementationDetails = getImplementationDetails
        self.getLocationHint = getLocationHint
    }

    // MARK: HitProcessing

    func retryInterval(for entity: DataEntity) -> TimeInterval {
        return entityRetryIntervalMapping[entity.uniqueIdentifier] ?? EdgeConstants.Defaults.RETRY_INTERVAL
    }

    /// Processes DataEntity events in the order they were retrieved from the database. Upon decoding sends the necessary events to the corresponding endpoint (e.g. Experience or Consent events).
    /// - Parameters:
    ///   - entity: the `DataEntity` to be processed
    ///   - completion: completion handler to notify the caller about the hit response
    func processHit(entity: DataEntity, completion: @escaping (Bool) -> Void) {
        guard let edgeEntity = decode(dataEntity: entity) else {
            // can't convert data to hit, unrecoverable error, move to next hit
            completion(true)
            return
        }

        let event = edgeEntity.event
        var edgeConfig: [String: String]

        // Check which workflow is used to obtain configuration
        if !edgeEntity.configuration.isEmpty {
            // Current workflow includes needed configuration in EdgeDataEntity before queuing hit
            edgeConfig = AnyCodable.toAnyDictionary(dictionary: edgeEntity.configuration) as? [String: String] ?? [:]
        } else {
            // Older workflow is supported in cases where persisted hits were queued before upgrade, but processed after upgrade
            // These hits will not have configuration in EdgeDataEntity, so the Configuration shared state is queried
            guard readyForEvent(event) else {
                Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Not ready for event, will retry hit with id '\(entity.uniqueIdentifier)'.")
                completion(false)
                return
            }

            edgeConfig = sharedStateReader.getEdgeConfig(event: event)
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
            processExperienceEvent(entityId: entity.uniqueIdentifier, event: event, edgeConfig: edgeConfig, requestBuilder: requestBuilder, completion: completion)
        } else if event.isUpdateConsentEvent {
            processConsentEvents(entityId: entity.uniqueIdentifier, event: event, edgeConfig: edgeConfig, requestBuilder: requestBuilder, completion: completion)
        } else if event.isResetIdentitiesEvent {
            // reset stored payloads as part of processing the reset hit
            let storeResponsePayloadManager = StoreResponsePayloadManager(EdgeConstants.DataStoreKeys.STORE_NAME)
            storeResponsePayloadManager.deleteAllStorePayloads()
            completion(true)
        }
    }

    /// Processes events of type ExperienceEvent
    /// - Parameters:
    ///   - entityId: unique id of the `DataEntity` used when the hit needs to be retried.
    ///   - event: event to be processed.
    ///   - eventConfig: configuration data for this event.
    ///   - requestBuilder: the `RequestBuilder` object to build the request payload.
    ///   - completion: completion handler to notify the caller about the hit response.
    private func processExperienceEvent(entityId: String, event: Event, edgeConfig: [String: String], requestBuilder: RequestBuilder, completion: @escaping (Bool) -> Void) {
        guard var datastreamId = edgeConfig[EdgeConstants.SharedState.Configuration.CONFIG_ID], !datastreamId.isEmpty else {
            Log.warning(label: EdgeConstants.LOG_TAG,
                        "\(SELF_TAG) - Unable to process the event '\(event.id.uuidString)' " +
                            "due to missing or empty edge.configId in configuration.")
            completion(true)
            return // drop the current event
        }

        guard let eventData = event.data, !eventData.isEmpty else {
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Failed to process Experience event, data was nil or empty")
            completion(true)
            return
        }

        // Get location hint for request endpoint
        let locationHint = getLocationHint()

        if let implementationDetails = getImplementationDetails() {
            requestBuilder.xdmPayloads[EdgeConstants.JsonKeys.IMPLEMENTATION_DETAILS] = AnyCodable(implementationDetails)
        }

        // Check if datastream ID override is present
        if let datastreamIdOverride = event.config?[EdgeConstants.EventDataKeys.Config.DATASTREAM_ID_OVERRIDE] as? String, !datastreamIdOverride.isEmpty {
            // Attach original datastream ID to the outgoing request
            requestBuilder.sdkConfig = SDKConfig(datastream: Datastream(original: datastreamId))

            // Update datastream ID for request since valid override ID is present
            datastreamId = datastreamIdOverride
        }

        // Check if datastream config override is present
        if let datastreamConfigOverride = event.config?[EdgeConstants.EventDataKeys.Config.DATASTREAM_CONFIG_OVERRIDE] as? [String: Any], !datastreamConfigOverride.isEmpty {
            requestBuilder.configOverrides = AnyCodable.from(dictionary: datastreamConfigOverride)
        }

        // Build and send the network request to Experience Edge
        let listOfEvents: [Event] = [event]

        guard let requestPayload = requestBuilder.getPayloadWithExperienceEvents(listOfEvents) else {
            Log.debug(label: EdgeConstants.LOG_TAG,
                      "\(SELF_TAG) - Failed to build the request payload, dropping event '\(event.id.uuidString)'.")
            completion(true)
            return
        }

        let requestProperties = getRequestProperties(from: event)
        let endpoint = buildEdgeEndpoint(config: edgeConfig,
                                         requestType: EdgeRequestType.interact,
                                         requestProperties: requestProperties,
                                         locationHint: locationHint)

        let edgeHit = ExperienceEventsEdgeHit(endpoint: endpoint, datastreamId: datastreamId, request: requestPayload)
        // NOTE: the order of these events needs to be maintained as they were sent in the network request
        // otherwise the response callback cannot be matched
        networkResponseHandler.addWaitingEvents(requestId: edgeHit.requestId,
                                                batchedEvents: listOfEvents)
        sendHit(entityId: entityId, edgeHit: edgeHit, headers: getRequestHeaders(event), completion: completion)
    }

    /// Processes events of type Consent
    /// - Parameters:
    ///   - entityId: unique id of the `DataEntity`.
    ///   - event: event to be processed.
    ///   - edgeConfig: configuration data for this event.
    ///   - requestBuilder: the `RequestBuilder` object to build the request payload.
    ///   - completion: completion handler to notify the caller about the hit response.
    private func processConsentEvents(entityId: String, event: Event, edgeConfig: [String: String], requestBuilder: RequestBuilder, completion: @escaping (Bool) -> Void) {
        guard let datastreamId = edgeConfig[EdgeConstants.SharedState.Configuration.CONFIG_ID], !datastreamId.isEmpty else {
            Log.warning(label: EdgeConstants.LOG_TAG,
                        "\(SELF_TAG) - Unable to process the event '\(event.id.uuidString)' " +
                            "due to missing or empty edge.configId in configuration.")
            completion(true)
            return // drop current event
        }

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

        // Get location hint for request endpoint
        let locationHint = getLocationHint()

        let endpoint = buildEdgeEndpoint(config: edgeConfig,
                                         requestType: EdgeRequestType.consent,
                                         requestProperties: nil,
                                         locationHint: locationHint)
        let edgeHit = ConsentEdgeHit(endpoint: endpoint, datastreamId: datastreamId, consents: consentPayload)
        networkResponseHandler.addWaitingEvent(requestId: edgeHit.requestId, event: event)
        sendHit(entityId: entityId, edgeHit: edgeHit, headers: getRequestHeaders(event), completion: completion)
    }

    /// Builds the endpoint based on the provided config info and `EdgeRequestType`
    /// - Parameters:
    ///   - config: configuration data, used to extract the environment and the custom domain, if any
    ///   - requestType: the `EdgeRequestType`
    ///   - requestProperties: properties from request event
    ///   - locationHint: optional location hint
    private func buildEdgeEndpoint(config: [String: String], requestType: EdgeRequestType, requestProperties: [String: Any]?, locationHint: String?) -> EdgeEndpoint {
        return EdgeEndpoint(
            requestType: requestType,
            environmentType: EdgeEnvironmentType(optionalRawValue: config[EdgeConstants.SharedState.Configuration.EDGE_ENVIRONMENT]),
            optionalDomain: config[EdgeConstants.SharedState.Configuration.EDGE_DOMAIN],
            optionalPath: requestProperties?[EdgeConstants.EventDataKeys.Request.PATH] as? String,
            locationHint: locationHint)
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
                                                datastreamId: edgeHit.datastreamId,
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
            if let self = self {
                // remove any retry interval if success, otherwise add to retry mapping
                self.entityRetryIntervalMapping[entityId] = success ? nil : retryInterval
            }
            completion(success)
        }
    }

    /// Computes the request headers for provided `event`, including the `Assurance` integration identifier when `Assurance` is enabled
    /// - Returns: the network request headers as `[String: String]`
    private func getRequestHeaders(_ event: Event) -> [String: String] {
        // get Assurance integration id and include it in to the requestHeaders
        var requestHeaders: [String: String] = [:]
        if let assuranceIntegrationId = sharedStateReader.getAssuranceIntegrationId(event: event) {
            requestHeaders[EdgeConstants.NetworkKeys.HEADER_KEY_AEP_VALIDATION_TOKEN] = assuranceIntegrationId
        }

        return requestHeaders
    }

    // Extracts all the custom request properties to overwrite the default values
    /// - Parameter event: current event for which the request properties are to be extracted
    /// - Returns: the dictionary of extracted request properties and their custom values
    private func getRequestProperties(from event: Event) -> [String: Any]? {
        var requestProperties = [String: Any]()
        if let overwritePath = getCustomRequestPath(from: event) {
            Log.trace(label: self.SELF_TAG, "Got custom path:(\(overwritePath)) for event:(\(event.id)), which will overwrite the default interaction request path.")
            requestProperties[EdgeConstants.EventDataKeys.Request.PATH] = overwritePath
        }
        return requestProperties
    }

    // Extracts network request path property to overwrite the default endpoint path value
    /// - Parameter event: current event for which the request path property is to be extracted
    /// - Returns: the custom path string
    private func getCustomRequestPath(from event: Event) -> String? {
        var path: String?
        if let eventData = event.data {
            let requestData = eventData[EdgeConstants.EventDataKeys.Request.KEY] as? [String: Any]
            path = requestData?[EdgeConstants.EventDataKeys.Request.PATH] as? String
        }

        guard let path = path, !path.isEmpty else {
            return nil
        }

        if !isValidPath(path) {
            Log.error(label: self.SELF_TAG, "Dropping the overwrite path value: (\(path)), since it contains invalid characters or is empty.")
            return nil
        }

        return path
    }

    /// Validates a given path does not contain invalid characters.
    /// A 'path'  may only contain alphanumeric characters, forward slash, period, hyphen, underscore, or tilde, but may not contain a double forward slash.
    /// - Parameter path: the path to validate
    /// - Returns: true if 'path' passes validation, false if 'path' contains invalid characters.
    private func isValidPath(_ path: String) -> Bool {
        if path.contains("//") {
            return false
        }

        let pattern = VALID_PATH_REGEX_PATTERN

        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.firstMatch(in: path, range: NSRange(path.startIndex..., in: path)) != nil
        return matches
    }
}

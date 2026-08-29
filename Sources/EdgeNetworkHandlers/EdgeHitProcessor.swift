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
            // Current workflow includes needed configuration in EdgeDataEntity before queuing hit.
            // configuration may also carry the non-String `edge.batching` object (a nested map),
            // so pull out only the String-valued entries instead of a blanket cast that would fail entirely
            // the moment a non-String key is present.
            edgeConfig = edgeEntity.configuration.asAnyDictionary.compactMapValues { $0 as? String }
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

    /// Processes a batch of `DataEntity`s as a single network request when the batch contains more than
    /// one ExperienceEvent; otherwise delegates to the existing single-entity `processHit` path.
    ///
    /// Routing rules mirror `aepsdk-edge-android`'s `EdgeHitProcessor.processBatch`:
    /// - Head is not an ExperienceEvent (Consent, Reset) -> process head alone.
    /// - Head's `xdm.eventType` is not whitelisted by the `edge.batching` config snapshotted at enqueue
    ///   time -> process head alone (strict allow-list: `enabled` alone is not sufficient).
    /// - Batch size == 1 (or only the head qualifies) -> single-entity path.
    /// - Multiple consecutive, allowlisted ExperienceEvents -> build one batch request; on 400, explode
    ///   to individual sends (nothing was ingested, so every event is safe to resend); on other
    ///   unrecoverable errors, drop all (matches the single-event path's existing behavior for the same codes).
    /// - Parameters:
    ///   - entities: ordered list of entities to process; must not be empty
    ///   - completion: completion handler invoked with a `BatchOutcome` describing how the queue should advance
    func processBatch(entities: [DataEntity], completion: @escaping (BatchOutcome) -> Void) {
        guard let headEntity = entities.first else {
            completion(.done(resolvedCount: 0))
            return
        }

        guard let headEdgeEntity = decode(dataEntity: headEntity) else {
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Unable to decode head entity to EdgeDataEntity, dropping.")
            completion(.done(resolvedCount: 1))
            return
        }

        guard headEdgeEntity.event.isExperienceEvent else {
            // Non-experience events (consent, reset) must be processed alone.
            processSingleEntity(headEntity, completion: completion)
            return
        }

        // Events whose xdm.eventType isn't whitelisted by the batching config must also be processed alone.
        let headBatchingConfig = EdgeBatchingConfig.from(headEdgeEntity.configuration.asAnyDictionary)
        guard headBatchingConfig.isEventTypeBatchable(xdmEventType(from: headEdgeEntity.event)) else {
            Log.trace(label: EdgeConstants.LOG_TAG,
                      "\(SELF_TAG) - Head entity's xdm.eventType (\(xdmEventType(from: headEdgeEntity.event) ?? "nil")) is not whitelisted for batching; processing alone.")
            processSingleEntity(headEntity, completion: completion)
            return
        }

        // Collect the consecutive ExperienceEvent run from the front. `hasSameRequestConfig` is checked
        // first since it's cheap and, once true, guarantees the candidate's batching config snapshot is
        // identical to the head's - so the head's already-parsed `headBatchingConfig` can be reused
        // instead of re-decoding/re-parsing each candidate's config from scratch.
        var batchEntities: [DataEntity] = []
        var batchEvents: [Event] = []
        for dataEntity in entities {
            guard let edgeEntity = decode(dataEntity: dataEntity),
                  edgeEntity.event.isExperienceEvent,
                  hasSameRequestConfig(edgeEntity, headEdgeEntity),
                  headBatchingConfig.isEventTypeBatchable(xdmEventType(from: edgeEntity.event)) else {
                break
            }
            batchEntities.append(dataEntity)
            batchEvents.append(edgeEntity.event)
        }

        guard batchEntities.count > 1 else {
            processSingleEntity(headEntity, completion: completion)
            return
        }

        Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Processing batch of \(batchEntities.count) ExperienceEvent(s).")

        let requestBuilder = RequestBuilder()
        let identityState = AnyCodable.toAnyDictionary(dictionary: headEdgeEntity.identityMap)
        requestBuilder.xdmPayloads[EdgeConstants.SharedState.Identity.IDENTITY_MAP] =
            AnyCodable(identityState?[EdgeConstants.SharedState.Identity.IDENTITY_MAP])
        requestBuilder.enableResponseStreaming(recordSeparator: EdgeConstants.Defaults.RECORD_SEPARATOR,
                                               lineFeed: EdgeConstants.Defaults.LINE_FEED)

        if let implementationDetails = getImplementationDetails() {
            requestBuilder.xdmPayloads[EdgeConstants.JsonKeys.IMPLEMENTATION_DETAILS] = AnyCodable(implementationDetails)
        }

        // configuration may also carry the non-String `edge.batching` object (a nested map),
        // so pull out only the String-valued entries instead of a blanket cast that would fail entirely
        // the moment a non-String key is present.
        let edgeConfig = headEdgeEntity.configuration.asAnyDictionary.compactMapValues { $0 as? String }
        guard var datastreamId = edgeConfig[EdgeConstants.SharedState.Configuration.CONFIG_ID], !datastreamId.isEmpty else {
            Log.debug(label: EdgeConstants.LOG_TAG,
                      "\(SELF_TAG) - Cannot process batch: Edge config ID is missing or empty, dropping \(batchEntities.count) events.")
            completion(.done(resolvedCount: batchEntities.count))
            return
        }

        let headEvent = headEdgeEntity.event
        if let datastreamIdOverride = headEvent.config?[EdgeConstants.EventDataKeys.Config.DATASTREAM_ID_OVERRIDE] as? String, !datastreamIdOverride.isEmpty {
            requestBuilder.sdkConfig = SDKConfig(datastream: Datastream(original: datastreamId))
            datastreamId = datastreamIdOverride
        }
        if let datastreamConfigOverride = headEvent.config?[EdgeConstants.EventDataKeys.Config.DATASTREAM_CONFIG_OVERRIDE] as? [String: Any], !datastreamConfigOverride.isEmpty {
            requestBuilder.configOverrides = AnyCodable.from(dictionary: datastreamConfigOverride)
        }

        guard let requestPayload = requestBuilder.getPayloadWithExperienceEvents(batchEvents) else {
            Log.warning(label: EdgeConstants.LOG_TAG,
                        "\(SELF_TAG) - Failed to build the batch request payload, dropping \(batchEntities.count) events.")
            completion(.done(resolvedCount: batchEntities.count))
            return
        }

        let requestProperties = getRequestProperties(from: headEvent)
        let locationHint = getLocationHint()
        let endpoint = buildEdgeEndpoint(config: edgeConfig,
                                         requestType: EdgeRequestType.interact,
                                         requestProperties: requestProperties,
                                         locationHint: locationHint)
        let edgeHit = ExperienceEventsEdgeHit(endpoint: endpoint, datastreamId: datastreamId, request: requestPayload)

        // NOTE: the order of these events needs to be maintained as they were sent in the network request
        // otherwise the response callback cannot be matched
        networkResponseHandler.addWaitingEvents(requestId: edgeHit.requestId, batchedEvents: batchEvents)

        sendBatchHit(entityId: headEntity.uniqueIdentifier,
                    edgeHit: edgeHit,
                    headers: getRequestHeaders(headEvent),
                    batchEntities: batchEntities,
                    completion: completion)
    }

    /// Extracts `xdm.eventType` from the event's data, used as the batching whitelist key. Returns nil
    /// when the event has no XDM or no `eventType`. Mirrors `aepsdk-edge-android`'s `EventUtils.getXdmEventType`.
    private func xdmEventType(from event: Event) -> String? {
        guard let xdm = event.data?[EdgeConstants.JsonKeys.XDM] as? [String: Any] else {
            return nil
        }
        return xdm[EdgeConstants.JsonKeys.EVENT_TYPE] as? String
    }

    /// Checks whether `candidate` shares the same request-building config as `head` - the full snapshotted
    /// Configuration map (datastream ID, environment, domain, batching keys), the event-level `config`
    /// overrides (`datastreamIdOverride`/`datastreamConfigOverride`), and the event's custom
    /// `data.request.path` override. A single batch request is built entirely from the head's config
    /// (including its custom path, see `getRequestProperties`), so an entity with a different snapshot -
    /// or a different intended request path - must not be silently folded in: it would lose its own
    /// datastream/override, or be sent to the wrong endpoint, under the head's instead. Loosely mirrors
    /// `aepsdk-edge-android`'s `EdgeHitProcessor.hasSameRequestConfig`, with the additional path check.
    ///
    /// Compares via `NSDictionary` bridging rather than `AnyCodable`'s own `==`, since `AnyCodable.==`
    /// only recognizes array/dictionary values typed exactly as `[AnyCodable]`/`[String: AnyCodable]` -
    /// the nested `edge.batching` object (with its grouped arrays of event maps) decodes to plain
    /// `[String: Any]`/`[Any?]`, which falls through to `AnyCodable`'s `default: return false` and would
    /// make this always report "different config" whenever a batching config is present, defeating
    /// batching entirely.
    private func hasSameRequestConfig(_ candidate: EdgeDataEntity, _ head: EdgeDataEntity) -> Bool {
        let candidateConfig = AnyCodable.toAnyDictionary(dictionary: candidate.configuration) ?? [:]
        let headConfig = AnyCodable.toAnyDictionary(dictionary: head.configuration) ?? [:]
        guard (candidateConfig as NSDictionary).isEqual(to: headConfig) else { return false }

        let candidateOverrides = candidate.event.config ?? [:]
        let headOverrides = head.event.config ?? [:]
        guard (candidateOverrides as NSDictionary).isEqual(to: headOverrides) else { return false }

        return getCustomRequestPath(from: candidate.event) == getCustomRequestPath(from: head.event)
    }

    /// Delegates a single `DataEntity` to the existing `processHit` path and converts the boolean
    /// result to a `BatchOutcome`.
    private func processSingleEntity(_ entity: DataEntity, completion: @escaping (BatchOutcome) -> Void) {
        processHit(entity: entity) { [weak self] success in
            if success {
                completion(.done(resolvedCount: 1))
            } else {
                completion(.retryBatch(retryInterval: self?.retryInterval(for: entity) ?? EdgeConstants.Defaults.RETRY_INTERVAL))
            }
        }
    }

    /// Sends a batch network request. The response is buffered (not forwarded to `networkResponseHandler`)
    /// until the HTTP response code is known, so a 400 (nothing ingested) can be exploded into individual
    /// resends without first delivering a phantom, misattributed error or firing premature completions for
    /// the whole batch. Every other outcome is forwarded to `networkResponseHandler` unchanged, in the same
    /// order it was received, exactly reproducing the single-event path's existing behavior.
    private func sendBatchHit(entityId: String, edgeHit: EdgeHit, headers: [String: String], batchEntities: [DataEntity], completion: @escaping (BatchOutcome) -> Void) {
        guard let url = networkService.buildUrl(endpoint: edgeHit.endpoint, datastreamId: edgeHit.datastreamId, requestId: edgeHit.requestId) else {
            Log.debug(label: EdgeConstants.LOG_TAG,
                      "\(SELF_TAG) - Failed to build the URL, dropping batch request with id '\(edgeHit.requestId)'.")
            completion(.done(resolvedCount: batchEntities.count))
            return
        }

        let buffering = BufferingResponseCallback()
        networkService.doRequest(url: url,
                                 requestBody: edgeHit.getPayload(),
                                 requestHeaders: headers,
                                 streaming: edgeHit.getStreamingSettings(),
                                 responseCallback: buffering) { [weak self] success, retryInterval, responseCode in
            guard let self = self else { return }

            guard success else {
                self.entityRetryIntervalMapping[entityId] = retryInterval
                completion(.retryBatch(retryInterval: retryInterval ?? EdgeConstants.Defaults.RETRY_INTERVAL))
                return
            }

            self.entityRetryIntervalMapping[entityId] = nil

            if responseCode == HttpResponseCodes.badRequest.rawValue {
                Log.warning(label: EdgeConstants.LOG_TAG,
                            "\(self.SELF_TAG) - Batch of \(batchEntities.count) events received 400; nothing ingested, exploding to individual requests.")
                // Discard the buffered onError/onComplete: the batch's waiting events were registered
                // under edgeHit.requestId, but since nothing was ingested, remove that registration
                // without dispatching so the individual resends (new request ids) own the completions.
                _ = self.networkResponseHandler.removeWaitingEvents(requestId: edgeHit.requestId)
                self.explodeAndResend(remaining: batchEntities, resolvedCount: 0, completion: completion)
            } else {
                buffering.replay(into: self.networkResponseHandler, requestId: edgeHit.requestId)
                completion(.done(resolvedCount: batchEntities.count))
            }
        }
    }

    /// Re-sends each entity in `batchEntities` individually after a batch 400. A 400 means nothing in the
    /// batch was ingested, so every event is safe to resend. Entities are processed FIFO: a `.done` outcome
    /// counts as resolved; a `.retryBatch` (recoverable failure) stops the explosion and returns the
    /// resolved count so the queue can remove those entities and schedule a retry for the remainder.
    private func explodeAndResend(remaining: [DataEntity], resolvedCount: Int, completion: @escaping (BatchOutcome) -> Void) {
        guard let entity = remaining.first else {
            completion(.done(resolvedCount: resolvedCount))
            return
        }

        // Each entity is sent as a batch-of-1, which goes through the same terminal path (handles
        // success, drop, and the existing single-event 400 behavior).
        processSingleEntity(entity) { [weak self] outcome in
            guard let self = self else { return }
            switch outcome {
            case .done:
                self.explodeAndResend(remaining: Array(remaining.dropFirst()), resolvedCount: resolvedCount + 1, completion: completion)
            case .retryBatch(let retryInterval):
                if resolvedCount > 0 {
                    completion(.partialRemove(resolvedHeadCount: resolvedCount, retryInterval: retryInterval))
                } else {
                    completion(.retryBatch(retryInterval: retryInterval))
                }
            case .partialRemove:
                // Not reachable: a size-1 `processSingleEntity` call never returns `.partialRemove`.
                self.explodeAndResend(remaining: Array(remaining.dropFirst()), resolvedCount: resolvedCount + 1, completion: completion)
            }
        }
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
                                 responseCallback: callback) { [weak self] success, retryInterval, _ in
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

/// Buffers `ResponseCallback` invocations (in the order received) instead of forwarding them immediately,
/// so `EdgeHitProcessor.sendBatchHit` can inspect the HTTP response code before deciding whether to
/// replay them into `NetworkResponseHandler` or discard them (400 batch explosion).
private class BufferingResponseCallback: ResponseCallback {
    private enum BufferedCall {
        case response(String)
        case error(String)
    }

    private var calls: [BufferedCall] = []
    private var completeCalled = false

    func onResponse(jsonResponse: String) {
        calls.append(.response(jsonResponse))
    }

    func onError(jsonError: String) {
        calls.append(.error(jsonError))
    }

    func onComplete() {
        completeCalled = true
    }

    /// Forwards every buffered call to `networkResponseHandler`, in the original order, for `requestId`.
    func replay(into networkResponseHandler: NetworkResponseHandler, requestId: String) {
        for call in calls {
            switch call {
            case .response(let jsonResponse):
                networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: requestId)
            case .error(let jsonError):
                networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: requestId)
            }
        }
        if completeCalled {
            networkResponseHandler.processResponseOnComplete(requestId: requestId)
        }
    }
}

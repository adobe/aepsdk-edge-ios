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

@objc(AEPMobileEdge)
public class Edge: NSObject, Extension {
    private let LOG_TAG = "Edge" // Tag for logging
    private var networkService: EdgeNetworkService = EdgeNetworkService()
    private var networkResponseHandler: NetworkResponseHandler = NetworkResponseHandler()
    private var hitQueue: HitQueuing?

    // MARK: - Extension
    public var name = Constants.EXTENSION_NAME
    public var friendlyName = Constants.FRIENDLY_NAME
    public static var extensionVersion = Constants.EXTENSION_VERSION
    public var metadata: [String: String]?
    public var runtime: ExtensionRuntime

    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()
        setupHitQueue()
    }

    public func onRegistered() {
        registerListener(type: Constants.EventType.EDGE,
                         source: EventSource.requestContent,
                         listener: handleExperienceEventRequest)
    }

    public func onUnregistered() {
        hitQueue?.close()
        print("Extension unregistered from MobileCore: \(Constants.FRIENDLY_NAME)")
    }

    public func readyForEvent(_ event: Event) -> Bool {
        if event.type == Constants.EventType.EDGE, event.source == EventSource.requestContent {
            let configurationSharedState = getSharedState(extensionName: Constants.SharedState.Configuration.STATE_OWNER_NAME,
                                                          event: event)
            let identitySharedState = getSharedState(extensionName: Constants.SharedState.Identity.STATE_OWNER_NAME,
                                                     event: event)
            return configurationSharedState?.status == .set && identitySharedState?.status == .set
        }

        return true
    }

    /// Handler for Experience Edge Request Content events.
    /// Valid Configuration and Identity shared states are required for processing the event (see `readyForEvent`). If a valid Configuration shared state is
    /// available, but no `edge.configId ` is found, the event is dropped.
    ///
    /// - Parameter event: an event containing ExperienceEvent data for processing
    func handleExperienceEventRequest(_ event: Event) {
        if event.data == nil {
            Log.trace(label: LOG_TAG, "Event with id \(event.id.uuidString) contained no data, ignoring.")
            return
        }

        Log.trace(label: LOG_TAG, "handleExperienceEventRequest - Processing event with id \(event.id.uuidString).")

        // fetch config shared state, this should be resolved based on readyForEvent check
        guard let configId = getEdgeConfigId(event: event) else {
            return // drop current event
        }

        // Build Request object
        let requestBuilder = RequestBuilder()
        requestBuilder.enableResponseStreaming(recordSeparator: Constants.Defaults.RECORD_SEPARATOR,
                                               lineFeed: Constants.Defaults.LINE_FEED)

        // get ECID from Identity shared state, this should be resolved based on readyForEvent check
        guard let identityState =
                getSharedState(extensionName: Constants.SharedState.Identity.STATE_OWNER_NAME,
                               event: event)?.value else {
            Log.warning(label: LOG_TAG,
                        "handleExperienceEventRequest - Unable to process the event '\(event.id.uuidString)', " +
                            "Identity shared state is nil.")
            return // drop current event
        }

        if let ecid = identityState[Constants.SharedState.Identity.ECID] as? String {
            requestBuilder.experienceCloudId = ecid
        } else {
            // This is not expected to happen. Continue without ECID
            Log.warning(label: LOG_TAG, "handleExperienceEventRequest - An unexpected error has occurred, ECID is nil.")
        }

        // get Assurance integration id and include it in to the requestHeaders
        var requestHeaders: [String: String] = [:]
        if let assuranceSharedState = getSharedState(extensionName: Constants.SharedState.Assurance.STATE_OWNER_NAME, event: event)?.value {
            if let assuranceIntegrationId = assuranceSharedState[Constants.SharedState.Assurance.INTEGRATION_ID] as? String {
                requestHeaders[Constants.NetworkKeys.HEADER_KEY_AEP_VALIDATION_TOKEN] = assuranceIntegrationId
            }
        }

        // Build and send the network request to Experience Edge
        let listOfEvents: [Event] = [event]
        guard let requestPayload = requestBuilder.getRequestPayload(listOfEvents) else {
            Log.debug(label: LOG_TAG,
                      "handleExperienceEventRequest - Failed to build the request payload, dropping current event '\(event.id.uuidString)'.")
            return
        }

        let edgeHit = EdgeHit(configId: configId, requestId: UUID().uuidString, request: requestPayload, headers: requestHeaders, event: event)
        guard let edgeHitData = try? JSONEncoder().encode(edgeHit) else {
            Log.debug(label: LOG_TAG, "handleExperienceEventRequest - Failed to encode edge hit: '\(event.id.uuidString)'.")
            return
        }

        // NOTE: the order of these events needs to be maintained as they were sent in the network request
        // otherwise the response callback cannot be matched
        networkResponseHandler.addWaitingEvents(requestId: edgeHit.requestId,
                                                batchedEvents: listOfEvents)

        let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: edgeHitData)
        hitQueue?.queue(entity: entity)
    }

    /// Extracts the Edge Configuration identifier from the Configuration Shared State
    /// - Parameter event: current event for which the configuration is required
    /// - Returns: the Edge Configuration Id if found, nil otherwise
    private func getEdgeConfigId(event: Event) -> String? {
        guard let configSharedState =
                getSharedState(extensionName: Constants.SharedState.Configuration.STATE_OWNER_NAME,
                               event: event)?.value else {
            Log.warning(label: LOG_TAG,
                        "handleExperienceEventRequest - Unable to process the event '\(event.id.uuidString)', Configuration shared state is nil.")
            return nil
        }

        guard let configId =
                configSharedState[Constants.SharedState.Configuration.CONFIG_ID] as? String,
              !configId.isEmpty else {
            Log.warning(label: LOG_TAG,
                        "handleExperienceEventRequest - Unable to process the event '\(event.id.uuidString)' " +
                            "because of invalid edge.configId in configuration.")
            return nil
        }

        return configId
    }

    /// Sets up the `PersistentHitQueue` to handle `EdgeHit`s
    private func setupHitQueue() {
        guard let dataQueue = ServiceProvider.shared.dataQueueService.getDataQueue(label: name) else {
            Log.error(label: "\(name):\(#function)", "Failed to create Data Queue, Edge could not be initialized")
            return
        }

        let hitProcessor = EdgeHitProcessor(networkService: networkService, networkResponseHandler: networkResponseHandler)
        hitQueue = PersistentHitQueue(dataQueue: dataQueue, processor: hitProcessor)
        hitQueue?.beginProcessing()
    }
}

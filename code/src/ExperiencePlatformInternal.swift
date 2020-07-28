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

import ACPCore
import Foundation

class ExperiencePlatformInternal: ACPExtension {
    private static let version = "1.0.0-alpha"

    // Tag for logging
    private let TAG = "ExperiencePlatformInternal"

    typealias EventHandlerMapping = (event: ACPExtensionEvent, handler: (ACPExtensionEvent) -> (Bool))
    private let requestEventQueue = OperationQueue<EventHandlerMapping>("ExperiencePlatformInternal Requests")
    private let responseEventQueue = OperationQueue<EventHandlerMapping>("ExperiencePlatformInternal Responses")
    private var experiencePlatformNetworkService: ExperiencePlatformNetworkService = ExperiencePlatformNetworkService()
    private var networkResponseHandler: NetworkResponseHandler = NetworkResponseHandler()

    override init() {
        super.init()
        requestEventQueue.setHandler({ return $0.handler($0.event) })
        responseEventQueue.setHandler({ return $0.handler($0.event) })

        do {
            try api.registerListener(ExperiencePlatformExtensionRequestListener.self,
                                     eventType: ExperiencePlatformConstants.eventTypeAdobeHub,
                                     eventSource: ExperiencePlatformConstants.eventSourceAdobeSharedState)
        } catch {
            ACPCore.log(ACPMobileLogLevel.error, tag: TAG, message: "There was an error registering Extension Listener for shared state events: \(error.localizedDescription)")
        }

        do {
            try api.registerListener(ExperiencePlatformExtensionRequestListener.self,
                                     eventType: ExperiencePlatformConstants.eventTypeExperiencePlatform,
                                     eventSource: ExperiencePlatformConstants.eventSourceExtensionRequestContent)
        } catch {
            ACPCore.log(ACPMobileLogLevel.error, tag: TAG, message: "There was an error registering Extension Listener for extension request content events: \(error.localizedDescription)")
        }

        do {
            try api.registerListener(ExperiencePlatformExtensionResponseListener.self,
                                     eventType: ExperiencePlatformConstants.eventTypeExperiencePlatform,
                                     eventSource: ExperiencePlatformConstants.eventSourceExtensionResponseContent)
        } catch {
            ACPCore.log(ACPMobileLogLevel.error, tag: TAG, message: "There was an error registering Extension Listener for extension response content events: \(error.localizedDescription)")
        }

        requestEventQueue.start()
        responseEventQueue.start()
    }

    override func name() -> String? {
        "com.adobe.ExperiencePlatform"
    }

    override func version() -> String? {
        return ExperiencePlatformInternal.version
    }

    override func onUnregister() {
        super.onUnregister()

        // if the shared states are not used in the next registration they can be cleared in this method
        try? api.clearSharedEventStates()
    }

    override func unexpectedError(_ error: Error) {
        super.unexpectedError(error)

        ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Oh snap! An unexpected error occured: \(error.localizedDescription)")
    }

    /// Adds an event to the event queue and starts processing the queue.  Events with no event data are ignored.
    /// - Parameter event: the event to add to the event queue for processing
    func processAddEvent(_ event: ACPExtensionEvent) {
        requestEventQueue.add((event, handleAddEvent(event:)))
        ACPCore.log(ACPMobileLogLevel.verbose, tag: TAG, message: "Event with id \(event.eventUniqueIdentifier) added to queue.")
    }

    /// Called by event listeners to kick the processing of the event queue. Event passed to function is not added to queue for processing
    /// - Parameter event: the event which triggered processing of the event queue
    func processEventQueue(_ event: ACPExtensionEvent) {
        // Trigger processing of queue
        requestEventQueue.start()
        ACPCore.log(ACPMobileLogLevel.verbose, tag: TAG, message: "Event with id \(event.eventUniqueIdentifier) requested event queue kick.")
    }

    /// Handler called from `OperationQueue` to add and process an event.
    /// - Parameter event: an event containing ExperiencePlatformEvent data for processing
    func handleAddEvent(event: ACPExtensionEvent) -> Bool {
        if event.eventData == nil {
            ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Event with id \(event.eventUniqueIdentifier) contained no data, ignoring.")
            return true
        }

        return handleSendEvent(event)
    }

    /// Handle Konductor response by calling response callback. Called by event listener.
    /// - Parameter event: the response event to add to the queue
    func processPlatformResponseEvent(_ event: ACPExtensionEvent) {
        responseEventQueue.add((event, handleResponseEvent(event:)))
        ACPCore.log(ACPMobileLogLevel.verbose, tag: TAG, message: "Event with id \(event.eventUniqueIdentifier) added to queue.")
    }

    /// Calls `ResponseCallbackHandler` and invokes the response handler associated with this response event, if any
    /// - Parameter event: the `ACPExtensionEvent` to process, event data should not be nil and it should contain a requestEventId
    /// - Returns: `Bool` indicating if the response event was processed or not
    func handleResponseEvent(event: ACPExtensionEvent) -> Bool {
        guard let eventData = event.eventData as? [String: Any], let _ = eventData[ExperiencePlatformConstants.EventDataKeys.requestEventId] else { return false }
        ResponseCallbackHandler.shared.invokeResponseHandler(eventData: eventData)
        return true
    }

    /// Processes the events in the event queue in the order they were received.
    ///
    /// A valid Configuration shared state is required for processing events and if one is not available, processing the queue is halted without removing events from
    /// the queue. If a valid Configuration shared state is available but no `experiencePlatform.configId ` is found, the event is dropped.
    func handleSendEvent(_ event: ACPExtensionEvent) -> Bool {
        ACPCore.log(ACPMobileLogLevel.verbose, tag: TAG, message: "Processing handleSendEvent for event with id \(event.eventUniqueIdentifier).")

        guard let configSharedState = getSharedState(owner: ExperiencePlatformConstants.SharedState.Configuration.stateOwner,
                                                     event: event) else {
                                                        ACPCore.log(ACPMobileLogLevel.debug,
                                                                    tag: TAG,
                                                                    message: "handleSendEvent - Unable to process queued events at this time, Configuration shared state is pending.")
                                                        return false // keep event in queue to process on next trigger
        }

        guard let configId = configSharedState[ExperiencePlatformConstants.SharedState.Configuration.experiencePlatformConfigId] as? String else {
            ACPCore.log(ACPMobileLogLevel.warning,
                        tag: TAG,
                        message: "handleSendEvent - Removed event '\(event.eventUniqueIdentifier)' because of invalid experiencePlatform.configId in configuration.")
            return true // drop event from queue
        }

        // Build Request object

        let requestBuilder = RequestBuilder()
        requestBuilder.enableResponseStreaming(recordSeparator: ExperiencePlatformConstants.Defaults.requestConfigRecordSeparator, lineFeed: ExperiencePlatformConstants.Defaults.requestConfigLineFeed)

        // get ECID
        guard let identityState = getSharedState(owner: ExperiencePlatformConstants.SharedState.Identity.stateOwner,
                                                 event: event) else {
                                                    ACPCore.log(ACPMobileLogLevel.debug,
                                                                tag: TAG,
                                                                message: "handleSendEvent - Unable to process queued events at this time, Identity shared state is pending.")
                                                    return false // keep event in queue to process when Identity state updates
        }

        if let ecid = identityState[ExperiencePlatformConstants.SharedState.Identity.ecid] as? String {
            requestBuilder.experienceCloudId = ecid
        } else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "handleSendEvent - An unexpected error has occurred, ECID is null.")
        }

        // get Griffon integration id and include it in to the requestHeaders
        var requestHeaders: [String: String] = [:]
        if let griffonSharedState = getSharedState(owner: ExperiencePlatformConstants.SharedState.Griffon.stateOwner, event: event) {
            if let griffonIntegrationId = griffonSharedState[ExperiencePlatformConstants.SharedState.Griffon.integrationId] as? String {
                requestHeaders[ExperiencePlatformConstants.NetworkKeys.headerKeyAEPValidationToken] = griffonIntegrationId
            }
        }

        // Build and send the network request to Konductor
        let listOfEvents: [ACPExtensionEvent] = [event]
        if let requestPayload = requestBuilder.getRequestPayload(listOfEvents) {
            let requestId: String = UUID.init().uuidString

            // NOTE: the order of these events need to be maintained as they were sent in the network request
            // otherwise the response callback cannot be matched
            networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: listOfEvents)
            guard let url: URL = experiencePlatformNetworkService.buildUrl(requestType: ExperienceEdgeRequestType.interact, configId: configId, requestId: requestId) else {
                ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Failed to build the URL, skipping current event with id \(event.eventUniqueIdentifier).")
                return true
            }

            let callback: ResponseCallback = NetworkResponseCallback(requestId: requestId, responseHandler: networkResponseHandler)
            experiencePlatformNetworkService.doRequest(url: url,
                                                       requestBody: requestPayload,
                                                       requestHeaders: requestHeaders,
                                                       responseCallback: callback,
                                                       retryTimes: ExperiencePlatformConstants.Defaults.networkRequestMaxRetries)
        }

        ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Finished processing and sending events to Platform.")
        return true
    }

    /// Helper to get shared state of another extension.
    /// - Parameters:
    ///   - owner: The name of the shared state owner, typically the registered name of the extension.
    ///   - event: The triggering event used to retieve a specific state version.
    /// - Returns: The shared state of the specified `owner` or nil if the state is pending or an error occurred retrieving the state.
    private func getSharedState(owner: String, event: ACPExtensionEvent) -> [AnyHashable: Any]? {
        let state: [AnyHashable: Any]?
        do {
            state = try api.getSharedEventState(owner, event: event)
        } catch {
            ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Failed to retrieve shared state \(owner): \(error.localizedDescription)")
            return nil // keep event in queue to process on next trigger
        }

        guard let unwrappedState = state else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Shared state for \(owner) is pending.")
            return nil // keep event in queue to process on next trigger
        }
        return unwrappedState
    }
}

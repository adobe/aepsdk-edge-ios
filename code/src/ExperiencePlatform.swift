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

@objc(AEPExperiencePlatform)
public class ExperiencePlatform: NSObject, Extension {
    // Tag for logging
    private let TAG = "ExperiencePlatformInternal"
    
    typealias EventHandlerMapping = (event: Event, handler: (Event) -> (Bool))
    private let requestEventQueue = OperationOrderer<EventHandlerMapping>("ExperiencePlatformInternal Requests")
    private let responseEventQueue = OperationOrderer<EventHandlerMapping>("ExperiencePlatformInternal Responses")
    private var experiencePlatformNetworkService: ExperiencePlatformNetworkService = ExperiencePlatformNetworkService()
    private var networkResponseHandler: NetworkResponseHandler = NetworkResponseHandler()
    
    // MARK: - Extension
    
    public var name = ExperiencePlatformConstants.extensionName
    public var friendlyName = ExperiencePlatformConstants.friendlyName
    public static var extensionVersion = ExperiencePlatformConstants.extensionVersion
    public var metadata: [String : String]?
    public var runtime: ExtensionRuntime
    
    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()
        
        requestEventQueue.setHandler({ return $0.handler($0.event) })
        responseEventQueue.setHandler({ return $0.handler($0.event) })
        requestEventQueue.start()
        responseEventQueue.start()
    }
    
    public func onRegistered() {
        registerListener(type: ExperiencePlatformConstants.eventTypeExperiencePlatform, source: EventSource.requestContent, listener: handleExperienceEventRequest)
        registerListener(type: ExperiencePlatformConstants.eventTypeExperiencePlatform, source: EventSource.responseContent, listener: handleExperienceEventResponse)
        registerListener(type: EventType.hub, source: EventSource.sharedState, listener: handleSharedStateUpdate)
    }
    
    public func onUnregistered() {
        print("Extension unregistered from MobileCore: \(ExperiencePlatformConstants.friendlyName)")
    }
    
    public func readyForEvent(_ event: Event) -> Bool {
        return true
    }
    
    private func handleExperienceEventRequest(event: Event) {
        processAddEvent(event)
    }
    
    private func handleExperienceEventResponse(event: Event) {
        processPlatformResponseEvent(event)
    }
    
    private func handleSharedStateUpdate(event: Event) {
        guard let eventData = event.data else {
            //ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Adobe Hub event contains no data. Cannot process event '\(event.eventUniqueIdentifier)'")
            return
        }

        // If Configuration or Identity shared state, start processing event queue
        let stateOwner = eventData[ExperiencePlatformConstants.SharedState.stateowner] as? String
        if stateOwner == ExperiencePlatformConstants.SharedState.Configuration.stateOwner  ||
            stateOwner == ExperiencePlatformConstants.SharedState.Identity.stateOwner {
            // kick event queue processing
            processEventQueue(event)
        }
    }
       
    

    /// Adds an event to the event queue and starts processing the queue.  Events with no event data are ignored.
    /// - Parameter event: the event to add to the event queue for processing
    func processAddEvent(_ event: Event) {
        requestEventQueue.add((event, handleAddEvent(event:)))
        Log.trace(label: TAG, "Event with id \(event.id.uuidString) added to queue.")
    }

    /// Called by event listeners to kick the processing of the event queue. Event passed to function is not added to queue for processing
    /// - Parameter event: the event which triggered processing of the event queue
    func processEventQueue(_ event: Event) {
        // Trigger processing of queue
        requestEventQueue.start()
        Log.trace(label: TAG, "Event with id \(event.id.uuidString) requested event queue kick.")
    }

    /// Handler called from `OperationQueue` to add and process an event.
    /// - Parameter event: an event containing ExperiencePlatformEvent data for processing
    func handleAddEvent(event: Event) -> Bool {
        if event.data == nil {
            Log.debug(label: TAG, "Event with id \(event.id.uuidString) contained no data, ignoring.")
            return true
        }

        return handleSendEvent(event)
    }

    /// Handle Konductor response by calling response callback. Called by event listener.
    /// - Parameter event: the response event to add to the queue
    func processPlatformResponseEvent(_ event: Event) {
        responseEventQueue.add((event, handleResponseEvent(event:)))
        Log.trace(label: TAG, "Event with id \(event.id.uuidString) added to queue.")
    }

    /// Calls `ResponseCallbackHandler` and invokes the response handler associated with this response event, if any
    /// - Parameter event: the `ACPExtensionEvent` to process, event data should not be nil and it should contain a requestEventId
    /// - Returns: `Bool` indicating if the response event was processed or not
    func handleResponseEvent(event: Event) -> Bool {
        guard let eventData = event.data, let _ = eventData[ExperiencePlatformConstants.EventDataKeys.requestEventId] else { return false }
        ResponseCallbackHandler.shared.invokeResponseHandler(eventData: eventData)
        return true
    }

    /// Processes the events in the event queue in the order they were received.
    ///
    /// A valid Configuration shared state is required for processing events and if one is not available, processing the queue is halted without removing events from
    /// the queue. If a valid Configuration shared state is available but no `experiencePlatform.configId ` is found, the event is dropped.
    func handleSendEvent(_ event: Event) -> Bool {
        Log.trace(label: TAG, "Processing handleSendEvent for event with id \(event.id.uuidString).")

        guard let configSharedState = getSharedState(extensionName: ExperiencePlatformConstants.SharedState.Configuration.stateOwner,
                                                     event: event)?.value else {
                                                        Log.debug(label: TAG, "handleSendEvent - Unable to process queued events at this time, Configuration shared state is pending.")
                                                        return false // keep event in queue to process on next trigger
        }

        guard let configId = configSharedState[ExperiencePlatformConstants.SharedState.Configuration.experiencePlatformConfigId] as? String else {
            Log.warning(label: TAG, "handleSendEvent - Removed event '\(event.id.uuidString)' because of invalid experiencePlatform.configId in configuration.")
            return true // drop event from queue
        }

        // Build Request object

        let requestBuilder = RequestBuilder()
        requestBuilder.enableResponseStreaming(recordSeparator: ExperiencePlatformConstants.Defaults.requestConfigRecordSeparator, lineFeed: ExperiencePlatformConstants.Defaults.requestConfigLineFeed)

        // get ECID
        guard let identityState = getSharedState(extensionName: ExperiencePlatformConstants.SharedState.Identity.stateOwner,
                                                 event: event)?.value else {
                                                    Log.debug(label: TAG, "handleSendEvent - Unable to process queued events at this time, Identity shared state is pending.")
                                                    return false // keep event in queue to process when Identity state updates
        }

        if let ecid = identityState[ExperiencePlatformConstants.SharedState.Identity.ecid] as? String {
            requestBuilder.experienceCloudId = ecid
        } else {
            Log.warning(label: TAG, "handleSendEvent - An unexpected error has occurred, ECID is null.")
        }

        // get Griffon integration id and include it in to the requestHeaders
        var requestHeaders: [String: String] = [:]
        if let griffonSharedState = getSharedState(extensionName: ExperiencePlatformConstants.SharedState.Griffon.stateOwner, event: event)?.value {
            if let griffonIntegrationId = griffonSharedState[ExperiencePlatformConstants.SharedState.Griffon.integrationId] as? String {
                requestHeaders[ExperiencePlatformConstants.NetworkKeys.headerKeyAEPValidationToken] = griffonIntegrationId
            }
        }

        // Build and send the network request to Konductor
        let listOfEvents: [Event] = [event]
        if let requestPayload = requestBuilder.getRequestPayload(listOfEvents) {
            let requestId: String = UUID.init().uuidString

            // NOTE: the order of these events need to be maintained as they were sent in the network request
            // otherwise the response callback cannot be matched
            networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: listOfEvents)
            guard let url: URL = experiencePlatformNetworkService.buildUrl(requestType: ExperienceEdgeRequestType.interact, configId: configId, requestId: requestId) else {
                Log.debug(label: TAG, "Failed to build the URL, skipping current event with id \(event.id.uuidString).")
                return true
            }

            let callback: ResponseCallback = NetworkResponseCallback(requestId: requestId, responseHandler: networkResponseHandler)
            experiencePlatformNetworkService.doRequest(url: url,
                                                       requestBody: requestPayload,
                                                       requestHeaders: requestHeaders,
                                                       responseCallback: callback,
                                                       retryTimes: ExperiencePlatformConstants.Defaults.networkRequestMaxRetries)
        }

        Log.debug(label: TAG, "Finished processing and sending events to Platform.")
        return true
    }
}

//
// ADOBE CONFIDENTIAL
//
// Copyright 2020 Adobe
// All Rights Reserved.
//
// NOTICE: All information contained herein is, and remains
// the property of Adobe and its suppliers, if any. The intellectual
// and technical concepts contained herein are proprietary to Adobe
// and its suppliers and are protected by all applicable intellectual
// property laws, including trade secret and copyright laws.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from Adobe.
//


import Foundation
import ACPCore

class ExperiencePlatformInternal : ACPExtension {
    // Tag for logging
    private let TAG = "ExperiencePlatformInternal"
    
    typealias EventHandlerMapping = (event: ACPExtensionEvent, handler: (ACPExtensionEvent) -> (Bool))
    private let eventQueue = OperationQueue<EventHandlerMapping>("ExperiencePlatformInternal")
    
    override init() {
        super.init()
        eventQueue.setHandler({ return $0.handler($0.event) })
        
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
        
        eventQueue.start()
    }
    
    override func name() -> String? {
        "com.adobe.ExperiencePlatform"
    }
    
    override func version() -> String? {
        "1.0.0-alpha-2"
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
        eventQueue.add((event, handleAddEvent(event:)))
        ACPCore.log(ACPMobileLogLevel.verbose, tag: TAG, message: "Event with id \(event.eventUniqueIdentifier) added to queue.")
    }
    
    /// Called by event listeners to kick the processing of the event queue. Event passed to function is not added to queue for processing
    /// - Parameter event: the event which triggered processing of the event queue
    func processEventQueue(_ event: ACPExtensionEvent) {
        // TODO add way to trigger event queue without needing to add item (make triggerSourceIfNeeded public?)
        eventQueue.add((event, {(event: ACPExtensionEvent) -> Bool in
            // trigger processing of queue
            return true
        }))
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
    func processPlatformResponseEvent(_ event: ACPExtensionEvent){
        eventQueue.add((event, handleResponseEvent(event:)))
        ACPCore.log(ACPMobileLogLevel.verbose, tag: TAG, message: "Event with id \(event.eventUniqueIdentifier) added to queue.")
    }
    
    func handleResponseEvent(event: ACPExtensionEvent) -> Bool {
        // TODO implement me
        return true
    }
    
     /// Processes the events in the event queue in the order they were received.
     ///
     /// A valid Configuration shared state is required for processing events and if one is not available, processing the queue is halted without removing events from
     /// the queue. If a valid Configuration shared state is available but no `experiencePlatform.configId ` is found, the event is dropped.
    func handleSendEvent(_ event: ACPExtensionEvent) -> Bool {
        ACPCore.log(ACPMobileLogLevel.verbose, tag: TAG, message: "Processing handleSendEvent for event with id \(event.eventUniqueIdentifier).")
        
        let configState: [AnyHashable:Any]?
        do {
            configState = try api.getSharedEventState(ExperiencePlatformConstants.SharedState.Configuration.stateOwner, event: event)
        } catch {
            ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Failed to retrieve config shared state: \(error.localizedDescription)")
            return false // keep event in queue to process on next trigger
        }
        
        guard let configSharedState = configState else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Could not process queued events, configuration shared state is pending.")
            return false // keep event in queue to process on next trigger
        }
        
        guard let configId = configSharedState[ExperiencePlatformConstants.SharedState.Configuration.experiencePlatformConfigId] as? String else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Removed event '\(event.eventUniqueIdentifier)' because of invalid experiencePlatform.configId in configuration.")
            return true // drop event from queue
        }
        
        // Build Request object
        
        let requestBuilder = RequestBuilder()
        if let orgId = configSharedState[ExperiencePlatformConstants.SharedState.Configuration.experienceCloudOrgId] as? String{
            requestBuilder.organizationId = orgId
        }
        
        requestBuilder.recordSeparator = ExperiencePlatformConstants.Defaults.requestConfigRecordSeparator
        requestBuilder.lineFeed = ExperiencePlatformConstants.Defaults.requestConfigLineFeed
        
        if let requestData = requestBuilder.getPayload([event]) {
            // TODO send network request
            
            // DEBUG
            ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Sending request for config '\(configId)' and body: \(String(data: requestData, encoding: .utf8) ?? "failed to parse")")
        }
        
        ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Finished processing and sending events to Platform.")
        return true
    }

}

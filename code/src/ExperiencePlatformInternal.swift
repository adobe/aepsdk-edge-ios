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
    private let TAG = "ACPExperiencePlatformInternal"
    
    // Event queue
    private var eventQueue = [ACPExtensionEvent]()
    
    override init() {
        super.init()
        
        ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "init")
        do {
            try api.registerListener(ExperiencePlatformExtensionRequestListener.self,
                                     eventType: ExperiencePlatformConstants.eventTypeAdobeHub,
                                     eventSource: ExperiencePlatformConstants.eventSourceAdobeSharedState)
        } catch {
            ACPCore.log(ACPMobileLogLevel.error, tag: TAG, message: "There was an error registering Extension Listener for shared state events: \(error)")
        }
        
        do {
            try api.registerListener(ExperiencePlatformExtensionRequestListener.self,
                                     eventType: ExperiencePlatformConstants.eventTypeExperiencePlatform,
                                     eventSource: ExperiencePlatformConstants.eventSourceExtensionRequestContent)
        } catch {
            ACPCore.log(ACPMobileLogLevel.error, tag: TAG, message: "There was an error registering Extension Listener for extension request content events: \(error)")

        }
        
        do {
            try api.registerListener(ExperiencePlatformExtensionResponseListener.self,
                                     eventType: ExperiencePlatformConstants.eventTypeExperiencePlatform,
                                     eventSource: ExperiencePlatformConstants.eventSourceExtensionResponseContent)
        } catch {
            ACPCore.log(ACPMobileLogLevel.error, tag: TAG, message: "There was an error registering Extension Listener for extension response content events: \(error)")

        }
        
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
     /// - Parameter event: The event to add to the event queue for processing
    func processAddEvent(_ event: ACPExtensionEvent) {
        
        if event.eventData == nil {
            ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Event with id \(event.eventUniqueIdentifier) contained no data, ignoring.")
            return;
        }
        
        // TODO add to task executor
        self.eventQueue.append(event)
        ACPCore.log(ACPMobileLogLevel.verbose, tag: TAG, message: "Event with id \(event.eventUniqueIdentifier) added to queue.")
        
        // kick event queue
        self.processEventQueue()
        
    }
    
    /// Handle Konductor response by calling response callback.
    func processPlatformResponseEvent(_ event: ACPExtensionEvent) {
        // TODO implement me
    }
    
     /// Processes the events in the event queue in the order they were received.
     ///
     /// A valid Configuration shared state is required for processing events and if one is not available, processing the queue is halted without removing events from
     /// the queue. If a valid Configuration shared state is available but no `experiencePlatform.configId ` is found, the event is dropped.
    func processEventQueue() {
        if (eventQueue.isEmpty) {
            return;
        }
        
        // TODO add to task executor
        while !eventQueue.isEmpty {
        
            // get next event to process
            guard let event = eventQueue.last else {
                // unexpected to have nil events
                _ = eventQueue.dropLast()
                continue
            }
            
            let configState: [AnyHashable:Any]?
            do {
                configState = try api.getSharedEventState(ExperiencePlatformConstants.SharedState.configuration, event: event)
            } catch {
                ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Failed to retrieve config shared state: \(error)")
                return
            }
            
            guard let configSharedState = configState else {
                ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Could not process queued events, configuration shared state is pending.")
                return
            }
            
            let configId: String? = configSharedState[ExperiencePlatformConstants.SharedState.Configuration.experiencePlatformConfigId] as? String
            if (configId ?? "").isEmpty {
                ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Removed event '\(event.eventUniqueIdentifier)' because of invalid experiencePlatform.configId in configuration.")
                _ = eventQueue.dropLast()
                return
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
                ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Sending request with body '\(String(data: requestData, encoding: .utf8) ?? "failed to parse")'")
            }
            
            
        }
        
        ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Finished processing and sending events to Platform.")
        
    }

}

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

import ACPCore

private let LOG_TAG = "ACPExperiencePlatform"
private let EXTENSION_VERSION = "1.0.0-alpha"

public class ACPExperiencePlatform {

    @available(*, unavailable) private init() {}

    /// Registers the extension with the Mobile SDK. This method should be called only once in your application class
    public static func registerExtension() {
        
        do {
            try ACPCore.registerExtension(ExperiencePlatformInternal.self)
            ACPCore.log(ACPMobileLogLevel.debug,tag:LOG_TAG, message:"Extention successfully registered!")
        } catch {
            ACPCore.log(ACPMobileLogLevel.debug, tag:LOG_TAG, message:"Extension Registration has failed!")
        }
    }
    
   /// Returns the current version of the ACPExperiencePlatform Extesion
   public static func extensionVersion() -> String {
        return EXTENSION_VERSION
    }


    /// Sends one event to Adobe Data Platform and registers a callback for responses coming from Data Platform
    /// - Parameters:
    ///   - experiencePlatformEvent: Event to be sent to Adobe Data Platform; should not be null
    ///   - responseCallback: Optional callback to be invoked when the response handles are received from Adobe Data Platform
    public static func sendEvent(experiencePlatformEvent: ExperiencePlatformEvent,
                               responseCallback: (_ data: [String: Any]) -> ()) {
 
    let uniqueSequenceId = UUID().uuidString
    addDataPlatformEvent(experiencePlatformEvent: experiencePlatformEvent, uniqueSequenceId: uniqueSequenceId)
    dispatchSendAllEvent(uniqueSequenceId: uniqueSequenceId)
    }

    /// Deserialize the provided experiencePlatformEvent and dispatches a new event for the Experience platform extension with that data.
    /// - Parameters:
    ///   -  experiencePlatformEvent: The ExperiencePlatformEvent to be dispatched to the internal extension, event should not be null
    ///   - uniqueSequenceId: Unique event sequence identifier, used to identify all the events from the same batch before being sent to Data Platform
    /// - Returns: A Boolean indicating if the provided ExperiencePlatformEvent was dispatched
    private static func addDataPlatformEvent(experiencePlatformEvent: ExperiencePlatformEvent, uniqueSequenceId: String) {

        var eventData = experiencePlatformEvent.getData()
        eventData[ExperiencePlatformConstants.EventDataKeys.uniqueSequenceId] = uniqueSequenceId
        guard let event = try? ACPExtensionEvent(name: "Add event for Data Platform", type: ExperiencePlatformConstants.eventTypeExperiencePlatform, source: ExperiencePlatformConstants.eventSourceExtensionRequestContent, data: eventData)
        else {
            return
        }
        do {
            try ACPCore.dispatchEvent(event)
        } catch {
            ACPCore.log(ACPMobileLogLevel.warning, tag: LOG_TAG, message:"Failed to dispatch the event.")
        }
    }
    
    /// Dispatches the SendAll event for the Experience platform extension in order to start processing the queued events, prepare and initiate the network request.
    /// - Parameters:
    ///   -  experiencePlatformEvent: The ExperiencePlatformEvent to be dispatched to the internal extension, event should not be null
    ///   - uniqueSequenceId: Unique event sequence identifier, used to identify all the events from the same batch before being sent to Data Platform
    private static func dispatchSendAllEvent(uniqueSequenceId: String) {
        var sendAllEventData = [String: Any]()
        sendAllEventData[ExperiencePlatformConstants.EventDataKeys.send_all_events] = true
        sendAllEventData[ExperiencePlatformConstants.EventDataKeys.uniqueSequenceId] = uniqueSequenceId
       guard let sendAllEvent:ACPExtensionEvent = try? ACPExtensionEvent(name: "Send all events to Data Platform", type: ExperiencePlatformConstants.eventTypeExperiencePlatform, source: ExperiencePlatformConstants.eventSourceExtensionRequestContent, data: sendAllEventData)
        else {
            return
        }
        try? ACPCore.dispatchEvent(sendAllEvent)
     }
}

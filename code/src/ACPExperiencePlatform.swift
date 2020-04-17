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

public class ACPExperiencePlatform {

    @available(*, unavailable) private init() {}

    /// Registers the ACPExperiencePlatform extension with the Mobile SDK. This method should be called only once in your application class
    /// from the AppDelegate's application:didFinishLaunchingWithOptions method. This call should be before any calls into ACPCore
    /// interface except setLogLevel.
    public static func registerExtension() {
        
        do {
            try ACPCore.registerExtension(ExperiencePlatformInternal.self)
            ACPCore.log(ACPMobileLogLevel.debug,tag:LOG_TAG, message:"Extention Version has been successfully registered!")
        } catch {
            ACPCore.log(ACPMobileLogLevel.debug, tag:LOG_TAG, message:"Extension Registration has failed!")
        }
    }

    /// Sends one event to Adobe Data Platform and registers a callback for responses coming from Data Platform
    /// - Parameters:
    ///   - experiencePlatformEvent: Event to be sent to Adobe Data Platform
    ///   - responseCallback: Optional callback to be invoked when the response handles are received from
    ///   Adobe Data Platform. It may be invoked on a different thread and may be invoked multiple times
    public static func sendEvent(experiencePlatformEvent: ExperiencePlatformEvent, responseCallback: (([String: Any]) -> Void)?) {
        let uniqueSequenceId = UUID().uuidString
        if addDataPlatformEvent(experiencePlatformEvent: experiencePlatformEvent, uniqueSequenceId: uniqueSequenceId) {
                dispatchSendAllEvent(uniqueSequenceId: uniqueSequenceId)
        } else {
                ACPCore.log(ACPMobileLogLevel.warning, tag: LOG_TAG, message:"Unable to dispatch the event with id : \(uniqueSequenceId)." )
        }
    }

    /// Deserialize the provided experiencePlatformEvent and dispatches a new event for the Experience platform extension with that data.
    /// - Parameters:
    ///   -  experiencePlatformEvent: The ExperiencePlatformEvent to be dispatched to the internal extension
    ///   - uniqueSequenceId: Unique event sequence identifier, used to identify all the events from the same batch before being sent to Data Platform
    /// - Returns: A Boolean indicating if the provided ExperiencePlatformEvent was dispatched
    private static func addDataPlatformEvent(experiencePlatformEvent: ExperiencePlatformEvent, uniqueSequenceId: String) -> Bool {

        var eventData = experiencePlatformEvent.getData()
        eventData[ExperiencePlatformConstants.EventDataKeys.uniqueSequenceId] = AnyCodable(uniqueSequenceId)
        
        var event : ACPExtensionEvent
        do {
            event = try ACPExtensionEvent(name: "Add event for Data Platform", type: ExperiencePlatformConstants.eventTypeExperiencePlatform, source: ExperiencePlatformConstants.eventSourceExtensionRequestContent, data: eventData)
            do {
                 try ACPCore.dispatchEvent(event)
             } catch {
                 ACPCore.log(ACPMobileLogLevel.warning, tag: LOG_TAG, message:"Failed to dispatch the event with id \(uniqueSequenceId) due to an Unexpected error: \(error).")
                 return false
             }
        } catch {
            ACPCore.log(ACPMobileLogLevel.warning, tag: LOG_TAG, message:"Failed to dispatch due to an Unexpected error: \(error)." )
            return false
        }
          return true
    }
    
    /// Dispatches the SendAll event for the Experience platform extension in order to start processing the queued events, prepare and initiate the network request.
    /// - Parameters:
    ///   - uniqueSequenceId: Unique event sequence identifier, used to identify all the events from the same batch before being sent to Data Platform
    private static func dispatchSendAllEvent(uniqueSequenceId: String) {
        var sendAllEventData = [String: Any]()
        var sendAllEvent:ACPExtensionEvent
        sendAllEventData[ExperiencePlatformConstants.EventDataKeys.send_all_events] = true
        sendAllEventData[ExperiencePlatformConstants.EventDataKeys.uniqueSequenceId] = uniqueSequenceId
        do {
            sendAllEvent = try ACPExtensionEvent(name: "Send all events to Data Platform", type: ExperiencePlatformConstants.eventTypeExperiencePlatform, source: ExperiencePlatformConstants.eventSourceExtensionRequestContent, data: sendAllEventData)

        } catch {
            ACPCore.log(ACPMobileLogLevel.warning, tag: LOG_TAG, message:"Failed to dispatch the event with id \(uniqueSequenceId) due to an Unexpected error: \(error).")
            return
        }
        do {
            try ACPCore.dispatchEvent(sendAllEvent)
        } catch {
            ACPCore.log(ACPMobileLogLevel.warning, tag: LOG_TAG, message:"Failed to dispatch the event with id \(uniqueSequenceId) due to an Unexpected error: \(error).")
        }
     }
    
}

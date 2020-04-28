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
    
    static var responseCallbacksHandler: [String: ([String: Any]) -> Void] = [:]

    static func responseCallbacksHandlerClosure(eventId:String, completionHandler: @escaping ([String: Any]) -> Void) {
        responseCallbacksHandler[eventId] = completionHandler
    }
    

    /// Registers the ACPExperiencePlatform extension with the Mobile SDK. This method should be called only once in your application class
    /// from the AppDelegate's application:didFinishLaunchingWithOptions method. This call should be before any calls into ACPCore
    /// interface except setLogLevel.
    public static func registerExtension() {
        
        do {
            try ACPCore.registerExtension(ExperiencePlatformInternal.self)
            ACPCore.log(ACPMobileLogLevel.debug,tag:LOG_TAG, message:"Extention has been successfully registered!")
        } catch {
            ACPCore.log(ACPMobileLogLevel.debug, tag:LOG_TAG, message:"Extension Registration has failed!")
        }
    }

    /// Sends an event to Adobe Data Platform and registers a callback for responses coming from Data Platform
    /// - Parameters:
    ///   - experiencePlatformEvent: Event to be sent to Adobe Data Platform
    ///   - responseCallback: Optional callback to be invoked when the response handles are received from
    ///                       Adobe Data Platform. It may be invoked on a different thread and may be invoked multiple times
    public static func sendEvent(experiencePlatformEvent: ExperiencePlatformEvent!, responseCallback: (([String: Any]) -> Void)?) {

        guard let eventData = experiencePlatformEvent.asDictionary() else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message:"Failed to dispatch the event because the event data is nil.")
            return
        }
        var event : ACPExtensionEvent = ACPExtensionEvent()
        do {
            event = try ACPExtensionEvent(name: "Add event for Data Platform", type: ExperiencePlatformConstants.eventTypeExperiencePlatform, source: ExperiencePlatformConstants.eventSourceExtensionRequestContent, data: eventData)
        } catch {
            ACPCore.log(ACPMobileLogLevel.warning, tag: LOG_TAG, message:"Failed to dispatch due to an unexpected error: \(error)." )
        }
        do {
            if let  responsecallback = responseCallback {
                responseCallbacksHandlerClosure(eventId: event.eventUniqueIdentifier, completionHandler:responsecallback)
            }
             try ACPCore.dispatchEvent(event)
         } catch {
             ACPCore.log(ACPMobileLogLevel.warning, tag: LOG_TAG, message:"Failed to dispatch the event due to an unexpected error: \(error).")
        }
        return
    }
}


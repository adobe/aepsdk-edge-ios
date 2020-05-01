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
            ACPCore.log(ACPMobileLogLevel.debug,tag:LOG_TAG, message:"Extension has been successfully registered.")
        } catch {
            ACPCore.log(ACPMobileLogLevel.debug, tag:LOG_TAG, message:"Extension Registration has failed.")
        }
    }

    /// Sends an event to Adobe Data Platform and registers a callback for responses coming from Data Platform
    /// - Parameters:
    ///   - experiencePlatformEvent: Event to be sent to Adobe Data Platform
    ///   - responseCallback: Optional callback to be invoked when the response handles are received from
    ///                       Adobe Data Platform. It may be invoked on a different thread and may be invoked multiple times
    public static func sendEvent(experiencePlatformEvent: ExperiencePlatformEvent, responseCallback: (([String: Any]) -> Void)?) {

        guard let eventData = experiencePlatformEvent.asDictionary() else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message:"Failed to dispatch the event because the event data is nil.")
            return
        }
        var event : ACPExtensionEvent = ACPExtensionEvent()
        do {
            event = try ACPExtensionEvent(name: "Add event for Data Platform", type: ExperiencePlatformConstants.eventTypeExperiencePlatform, source: ExperiencePlatformConstants.eventSourceExtensionRequestContent, data: eventData)
            if let  responsecallback = responseCallback {
                responseCallbacksHandlerClosure(eventId: event.eventUniqueIdentifier, completionHandler:responsecallback)
            }
            try ACPCore.dispatchEvent(event)
        } catch {
            ACPCore.log(ACPMobileLogLevel.warning, tag: LOG_TAG, message:"Failed to dispatch the event due to an unexpected error: \(error).")
        }
    }
}

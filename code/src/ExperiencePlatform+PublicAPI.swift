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

private let logTag = "ExperiencePlatform"

public extension ExperiencePlatform {

    private static var responseCallbacksHandlers: [String: ([String: Any]) -> Void] = [:]

    /// Sends an event to Adobe Data Platform and registers a handler for responses coming from Data Platform
    /// - Parameters:
    ///   - experiencePlatformEvent: Event to be sent to Adobe Data Platform
    ///   - responseHandler: Optional callback to be invoked when the response handles are received from
    ///                     Adobe Data Platform. It may be invoked on a different thread and may be invoked multiple times
    static func sendEvent(experiencePlatformEvent: ExperiencePlatformEvent, responseHandler: ExperiencePlatformResponseHandler? = nil) {

        guard let xdmData = experiencePlatformEvent.xdm, !xdmData.isEmpty, let eventData = experiencePlatformEvent.asDictionary() else {
            Log.debug(label: logTag, "Failed to dispatch the platform event because the XDM data was nil/empty.")
            return
        }
        
        let event = Event(name: "AEP Request Event",
                          type: ExperiencePlatformConstants.eventTypeExperiencePlatform,
                          source: ExperiencePlatformConstants.eventSourceExtensionRequestContent,
                          data: eventData)

        ResponseCallbackHandler.shared.registerResponseHandler(uniqueEventId: event.id.uuidString, responseHandler: responseHandler)
        MobileCore.dispatch(event: event)
    }
}

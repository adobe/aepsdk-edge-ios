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

private let LOG_TAG = "Edge"

public extension Edge {

    /// Sends an event to Adobe Experience Edge and registers a completion handler for responses coming from the Edge Network
    /// - Parameters:
    ///   - experienceEvent: Event to be sent to Adobe Experience Edge
    ///   - completion: Optional completion handler to be invoked when the request is complete, returning the associated response handles
    ///                 received from the Adobe Experience Edge. It may be invoked on a different thread.
    @objc(sendExperienceEvent:completion:)
    static func sendEvent(experienceEvent: ExperienceEvent, _ completion: (([EdgeEventHandle]) -> Void)? = nil) {
        guard let xdmData = experienceEvent.xdm, !xdmData.isEmpty, let eventData = experienceEvent.asDictionary() else {
            Log.debug(label: LOG_TAG, "Failed to dispatch the experience event because the XDM data was nil/empty.")
            return
        }

        let event = Event(name: "AEP Request Event",
                          type: EventType.edge,
                          source: EventSource.requestContent,
                          data: eventData)

        CompletionHandlersManager.shared.registerCompletionHandler(forRequestEventId: event.id.uuidString, completion: completion)
        MobileCore.dispatch(event: event)
    }
}

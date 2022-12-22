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

    /// Get the Edge Network location hint used in requests to the Adobe Experience Platform Edge Network.
    /// The Edge Network location hint may be used when building the URL for Adobe Experience Platform Edge Network requests to hint at the server cluster to use.
    /// Returns the Edge Network location hint, or nil if the location hint expired or is not set.
    /// - Parameter completion: A completion handler invoked with the location hint, or an 'AEPError' if the request times out or an unexpected error occurs.
    @objc(getLocationHint:)
    static func getLocationHint(_ completion: @escaping (String?, Error?) -> Void) {
        let event = Event(name: "Edge Request Location Hint",
                          type: EventType.edge,
                          source: EventSource.requestIdentity,
                          data: [EdgeConstants.EventDataKeys.LOCATION_HINT: true])
        MobileCore.dispatch(event: event) { responseEvent in
            guard let responseEvent = responseEvent else {
                completion(nil, AEPError.callbackTimeout)
                return
            }

            if let data = responseEvent.data, data.keys.contains(EdgeConstants.EventDataKeys.LOCATION_HINT) {
                guard let hint = data[EdgeConstants.EventDataKeys.LOCATION_HINT] as? String else {
                    completion(nil, AEPError.unexpected)
                    return
                }
                completion(hint, nil)
                return
            }

            completion(nil, nil) // hint value is nil (no or expired hint)
        }
    }

    /// Set the Edge Network location hint used in requests to the Adobe Experience Platform Edge Network.
    /// Sets the Edge Network location hint used in requests to the AEP Edge Network causing requests to "stick" to a specific server cluster. Passing nil or
    /// an empty string will clear the existing location hint. Edge Network responses may overwrite the location hint to a new value when necessary to manage network traffic.
    /// Use caution when setting the location hint. Only use location hints for the 'EdgeNetwork' scope. An incorrect location hint value will cause all Edge Network requests to fail.
    /// - Parameter hint: the Edge Network location hint to use when connecting to the Adobe Experience Platform Edge Network
    @objc(setLocationHint:)
    static func setLocationHint(_ hint: String?) {
        let hintValue = hint ?? ""
        let event = Event(name: "Edge Update Location Hint",
                          type: EventType.edge,
                          source: EventSource.updateIdentity,
                          data: [EdgeConstants.EventDataKeys.LOCATION_HINT: hintValue as Any])

        MobileCore.dispatch(event: event)
    }
}

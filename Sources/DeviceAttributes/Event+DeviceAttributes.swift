//
// Copyright 2026 Adobe. All rights reserved.
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
import Foundation

extension Event {
    /// Returns true if this `Event` has the dedicated device-attributes event type (`EdgeConstants.DeviceAttributes.EVENT_TYPE`) and the standard
    /// `EventSource.requestContent` source. Such events are routed to the separate device-attributes queue
    /// and are sent regardless of collect consent.
    var isDeviceAttributesRequestEvent: Bool {
        return type == EdgeConstants.DeviceAttributes.EVENT_TYPE && source == EventSource.requestContent
    }

    /// Creates the device attributes response event for this request event, linked to it via `parentID`.
    func createDeviceAttributesResponse(status: String, reason: String? = nil, httpStatus: Int? = nil) -> Event {
        typealias Keys = EdgeConstants.DeviceAttributes.EventDataKeys
        var data: [String: Any] = [Keys.STATUS: status]
        if let reason = reason { data[Keys.REASON] = reason }
        if let httpStatus = httpStatus { data[Keys.HTTP_STATUS] = httpStatus }
        return createChainedEvent(name: EdgeConstants.DeviceAttributes.EVENT_NAME_RESPONSE,
                                  type: EdgeConstants.DeviceAttributes.EVENT_TYPE,
                                  source: EventSource.responseContent,
                                  data: data)
    }

    /// Creates the `dropped` device attributes response event for a hit that can't be decoded. With no request event to
    /// link to, it carries the request event id in `requestEventId`.
    static func createDeviceAttributesDroppedResponse(requestEventId: String) -> Event {
        typealias Keys = EdgeConstants.DeviceAttributes.EventDataKeys
        return Event(name: EdgeConstants.DeviceAttributes.EVENT_NAME_RESPONSE,
                     type: EdgeConstants.DeviceAttributes.EVENT_TYPE,
                     source: EventSource.responseContent,
                     data: [Keys.STATUS: EdgeConstants.DeviceAttributes.Status.DROPPED,
                            Keys.REASON: EdgeConstants.DeviceAttributes.Reason.INVALID_PAYLOAD,
                            Keys.REQUEST_EVENT_ID: requestEventId])
    }
}

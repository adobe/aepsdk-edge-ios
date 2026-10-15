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
    /// Returns true if this `Event` has the dedicated `edgeBypassConsent` type and the standard
    /// `EventSource.requestContent` source. Such events are routed to the separate device-attributes queue
    /// and are not subject to the collect-consent gate.
    var isBypassConsentEvent: Bool {
        return type == EdgeConstants.EventType.EDGE_BYPASS_CONSENT && source == EventSource.requestContent
    }

    /// Creates the device-attributes result event (E4) chained to this request event (E3).
    func createBypassResult(status: String, reason: String? = nil, httpStatus: Int? = nil) -> Event {
        typealias Keys = EdgeConstants.EventDataKeys.BypassResult
        var data: [String: Any] = [Keys.STATUS: status]
        if let reason = reason { data[Keys.REASON] = reason }
        if let httpStatus = httpStatus { data[Keys.HTTP_STATUS] = httpStatus }
        return createChainedEvent(name: EdgeConstants.EventName.BYPASS_RESULT,
                                  type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                                  source: EventSource.responseContent,
                                  data: data)
    }

    /// A corrupt hit has no usable Event; its persisted identifier still identifies the request to drop.
    static func createBypassDropResult(requestEventId: String) -> Event {
        typealias Keys = EdgeConstants.EventDataKeys.BypassResult
        return Event(name: EdgeConstants.EventName.BYPASS_RESULT,
                     type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                     source: EventSource.responseContent,
                     data: [Keys.STATUS: EdgeConstants.BypassResult.Status.DROPPED,
                            Keys.REASON: EdgeConstants.BypassResult.Reason.INVALID_PAYLOAD,
                            Keys.REQUEST_EVENT_ID: requestEventId])
    }
}

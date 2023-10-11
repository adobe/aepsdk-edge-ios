//
// Copyright 2023 Adobe. All rights reserved.
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
import AEPEdge
import Foundation

extension TestBase {

    /// Sets the location hint with the provided value.
    ///  - Parameter edgelocationHint: `String` denoting the location hint
    func setInitialLocationHint(_ edgeLocationHint: String?) {
        if edgeLocationHint != nil {
            print("Setting Edge location hint to: \(String(describing: edgeLocationHint))")
            Edge.setLocationHint(edgeLocationHint)
        } else {
            print("No preset Edge location hint is being used for this test.")
        }
    }

    /// Creates a valid interact URL using the provided location hint.
    /// - Parameters:
    ///    - locationHint: The location hint String to use in the URL
    /// - Returns: The interact URL with location hint applied
    public func createInteractUrl(with locationHint: String?) -> String {
        guard let locationHint = locationHint else {
            return "https://obumobile5.data.adobedc.net/ee/v1/interact"
        }
        return "https://obumobile5.data.adobedc.net/ee/\(locationHint)/v1/interact"
    }

    /// Gets all the dispatched events of type `com.adobe.eventType.edge` and source passed.
    /// - Parameters:
    ///    - expectedHandleType: `String` denoting the edge handle type
    /// - Returns: List of events of the passed handle type
    func getEdgeEventHandles(expectedHandleType: String) -> [Event] {
        return getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: expectedHandleType)
    }

    /// Gets all the dispatched `Edge` error response `Event`s
    /// - Returns: List of `Edge` error response `Event`s
    func getEdgeResponseErrors() -> [Event] {
        return getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
    }

    /// Extracts the Edge location hint from the location hint result
    func getLastLocationHintResultValue() -> String? {
        let locationHintResultEvent = getEdgeEventHandles(expectedHandleType: TestConstants.EventSource.LOCATION_HINT_RESULT).last
        guard let payload = locationHintResultEvent?.data?["payload"] as? [[String: Any]] else {
            return nil
        }
        guard payload.indices.contains(2) else {
            return nil
        }
        return payload[2]["hint"] as? String
    }

    /// Sets the test expectation for the event of type `com.adobe.eventType.edge` and source passed, with count matching the passed expected counts.
    /// - Parameters:
    ///    - expectedHandleType: `String` denoting expected handle type
    ///    - expectedCount: `Int32` denoting number of events expected
    func expectEdgeEventHandle(expectedHandleType: String, expectedCount: Int32 = 1) {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: expectedHandleType, expectedCount: expectedCount)
    }
}

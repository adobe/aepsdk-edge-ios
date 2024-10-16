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
import AEPTestUtils

extension TestBase {
    /// Sets the initial Edge location hint for the test suite if a valid, non-nil, and non-empty location hint is provided.
    ///
    /// - Parameter locationHint: An optional string representing the location hint to be set. Must be non-nil and non-empty to be applied.
    func setInitialLocationHint(_ locationHint: String?) {
        // Location hint is non-nil and non-empty
        if let locationHint = locationHint, !locationHint.isEmpty {
            print("Setting Edge location hint to: \(locationHint)")
            Edge.setLocationHint(locationHint)
            return
        }
        print("No preset Edge location hint is being used for this test.")
    }

    /// Creates a valid interact URL using the provided location hint. Requires that the Configuration shared state
    /// containing the `edge.domain` value is available.
    ///
    /// - Parameters:
    ///    - locationHint: The location hint String to use in the URL
    /// - Returns: The interact URL with location hint applied
    public func createInteractUrl(with locationHint: String?) -> String {
        var edgeDomain = IntegrationTestConstants.NetworkKeys.DEFAULT_EDGE_DOMAIN

        // Attempt to get Configuration shared state value for `edge.domain`
        if let sharedStateResult = getSharedStateFor(extensionName: IntegrationTestConstants.ExtensionName.CONFIGURATION),
           let values = sharedStateResult.value,
           let fetchedEdgeDomain = values[IntegrationTestConstants.ConfigurationKey.EDGE_DOMAIN] as? String {
            edgeDomain = fetchedEdgeDomain
        } else {
            print("WARNING: Unable to get valid Edge domain from configuration shared state. Using default edge domain: \(IntegrationTestConstants.NetworkKeys.DEFAULT_EDGE_DOMAIN)")
        }

        // Construct the URL based on the optional location hint
        if let locationHint = locationHint {
            return "https://\(edgeDomain)/ee/\(locationHint)/v1/interact"
        } else {
            return "https://\(edgeDomain)/ee/v1/interact"
        }
    }

    /// Gets all the dispatched events of type `com.adobe.eventType.edge` and source passed.
    /// - Parameters:
    ///    - expectedHandleType: `String` denoting the edge handle type
    /// - Returns: List of events of the passed handle type
    func getEdgeEventHandles(expectedHandleType: String, timeout: TimeInterval = 30, file: StaticString = #file, line: UInt = #line) -> [Event] {
        return getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: expectedHandleType, timeout: timeout, file: file, line: line)
    }

    /// Gets all the dispatched `Edge` error response `Event`s
    /// - Returns: List of `Edge` error response `Event`s
    func getEdgeResponseErrors(timeout: TimeInterval = 30, file: StaticString = #file, line: UInt = #line) -> [Event] {
        return getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, timeout: timeout, file: file, line: line)
    }

    /// Extracts the Edge location hint from the location hint result
    func getLastLocationHintResultValue(timeout: TimeInterval = 30, file: StaticString = #file, line: UInt = #line) -> String? {
        let locationHintResultEvent = getEdgeEventHandles(expectedHandleType: TestConstants.EventSource.LOCATION_HINT_RESULT, timeout: timeout, file: file, line: line).last
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

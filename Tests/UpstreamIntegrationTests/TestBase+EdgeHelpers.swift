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
import Foundation

extension TestBase {

    func getEdgeEventHandles(expectedHandleType: String) -> [Event] {
        return getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: expectedHandleType)
    }

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

    func expectEdgeEventHandle(expectedHandleType: String, expectedCount: Int32 = 1) {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: expectedHandleType, expectedCount: expectedCount)
    }
}

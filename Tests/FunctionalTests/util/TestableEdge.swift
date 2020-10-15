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
@testable import AEPEdge
import XCTest

/// Spy  class used for testing and inspecting `Edge`.
class TestableEdge: Edge {
    static public var readyForEventExpectation: XCTestExpectation?
    static public var handleExperienceEventRequestExpectation: XCTestExpectation?

    override func handleExperienceEventRequest(_ event: Event) {
        if let expectation = TestableEdge.handleExperienceEventRequestExpectation {
            expectation.fulfill()
        }
        super.handleExperienceEventRequest(event)
    }

    override public func readyForEvent(_ event: Event) -> Bool {
        if let expectation = TestableEdge.readyForEventExpectation {
            expectation.fulfill()
        }
        return super.readyForEvent(event)
    }
}

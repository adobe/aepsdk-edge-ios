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
@testable import AEPExperiencePlatform
import XCTest

/// Spy  class used for testing and inspecting `ExperiencePlatformInternal`.
class TestableExperiencePlatformInternal: ExperiencePlatformInternal {

    static public var processAddEventExpectation: XCTestExpectation?
    static public var processEventQueueExpectation: XCTestExpectation?
    static public var handleAddEventExpectation: XCTestExpectation?
    static public var processPlatformResponseEventExpectation: XCTestExpectation?
    static public var handleResponseEventExpectation: XCTestExpectation?

    override func processAddEvent(_ event: ACPExtensionEvent) {
        if let expectation = TestableExperiencePlatformInternal.processAddEventExpectation {
            expectation.fulfill()
        }
        super.processAddEvent(event)
    }

    override func processEventQueue(_ event: ACPExtensionEvent) {
        if let expectation = TestableExperiencePlatformInternal.processEventQueueExpectation {
            expectation.fulfill()
        }
        super.processEventQueue(event)
    }

    override func handleAddEvent(event: ACPExtensionEvent) -> Bool {
        if let expectation = TestableExperiencePlatformInternal.handleAddEventExpectation {
            expectation.fulfill()
        }
        return super.handleAddEvent(event: event)
    }

    override func processPlatformResponseEvent(_ event: ACPExtensionEvent) {
        if let expectation = TestableExperiencePlatformInternal.processPlatformResponseEventExpectation {
            expectation.fulfill()
        }
        super.processPlatformResponseEvent(event)
    }

    override func handleResponseEvent(event: ACPExtensionEvent) -> Bool {
        if let expectation = TestableExperiencePlatformInternal.handleResponseEventExpectation {
            expectation.fulfill()
        }
        return super.handleResponseEvent(event: event)
    }
}

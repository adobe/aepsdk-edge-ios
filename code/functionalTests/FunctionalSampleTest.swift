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

import Foundation
import ACPCore
import XCTest

/// This Test class is an example of usages of the FunctionalTestBase APIs
class FunctionalSampleTest: FunctionalTestBase {
    private let e1 = try! ACPExtensionEvent(name: "e1", type: "eventType", source: "eventSource", data: nil)
    private let e2 = try! ACPExtensionEvent(name: "e2", type: "eventType", source: "eventSource", data: nil)
    
    override func setUp() {
        super.setUp()
        FunctionalTestUtils.resetUserDefaults()
        FunctionalTestBase.debugEnabled = true
        continueAfterFailure = false
    }
    
    func testSample_AssertUnexpectedEvents() {
        // set event expectations specifying the event type, source and the count (count should be > 0)
        setEventExpectation(type: "eventType", source: "eventSource", count: 2)
        setEventExpectation(type: "com.adobe.eventType.hub", source: "com.adobe.eventSource.booted", count: 1)
        setEventExpectation(type: "com.adobe.eventType.hub", source: "com.adobe.eventSource.sharedState", count: 1)
        try? ACPCore.dispatchEvent(e1)
        try? ACPCore.dispatchEvent(e1)
        
        // assert that no unexpected event was received
        assertUnexpectedEvents()
    }
    
    func testSample_AssertExpectedEvents() {
        setEventExpectation(type: "eventType", source: "eventSource", count: 2)
        try? ACPCore.dispatchEvent(e1)
        try? ACPCore.dispatchEvent(e1)
        
        // assert all expected events were received and ignore any unexpected events
        // when ignoreUnexpectedEvents is set on false, an extra assertUnexpectedEvents step is performed
        assertExpectedEvents(ignoreUnexpectedEvents: true)
    }
    
    func testSample_DispatchedEvents() {
        try? ACPCore.dispatchEvent(e1)
        try? ACPCore.dispatchEvent(try! ACPExtensionEvent(name: "e1", type: "otherEventType", source: "otherEventSource", data: ["test":"withdata"]))
        try? ACPCore.dispatchEvent(try! ACPExtensionEvent(name: "e1", type: "eventType", source: "eventSource", data: ["test":"withdata"]))
        
        // assert on count and data for events of a certain type, source
        let dispatchedEvents = getDispatchedEventsWith(type: "eventType", source: "eventSource")
        
        XCTAssertEqual(2, dispatchedEvents.count)
        guard let event2data = dispatchedEvents[1].eventData as? [String: Any] else {
            XCTFail("Invalid event data for event 2")
            return
        }
        XCTAssertEqual(1, flattenDictionary(dict: event2data).count)
    }
}

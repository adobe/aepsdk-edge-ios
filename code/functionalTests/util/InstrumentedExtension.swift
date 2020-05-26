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

import ACPCore
import XCTest

/// Instrumented extension that registers a wildcard listener for intercepting events in current session. Use it along with `FunctionalTestBase`
class InstrumentedExtension : ACPExtension {
    override init() {
        super.init()
        
        try? api.registerWildcardListener(InstrumentedWildcardListener.self)
    }
    
    override func name() -> String? {
        "com.adobe.InstrumentedExtension"
    }
    
    override func version() -> String? {
        "1.0.0"
    }
}

/// Wildcard listener that monitors all the events dispatched in current test session. Use it along with `FunctionalTestBase`
class InstrumentedWildcardListener : ACPExtensionListener {
    static var expectations: Dictionary<EventSpec, XCTestExpectation> = Dictionary<EventSpec, XCTestExpectation>()
    static var receivedEvents: [ACPExtensionEvent] = []
    
    override func hear(_ event: ACPExtensionEvent) {
        print("Event received by InstrumentedWildcardListener")
        InstrumentedWildcardListener.receivedEvents.append(event)
        if let expectation = InstrumentedWildcardListener.expectations[EventSpec(type: event.eventType, source: event.eventSource)] {
            expectation.fulfill()
        }
        
    }
}


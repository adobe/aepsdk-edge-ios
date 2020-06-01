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

import XCTest
import ACPCore

/// Wildcard listener that monitors all the events dispatched in current test session. Use it along with `FunctionalTestBase`
class InstrumentedWildcardListener : ACPExtensionListener {
    private let logTag = "InstrumentedWildcardListener"
    static var expectations: Dictionary<EventSpec, XCTestExpectation> = Dictionary<EventSpec, XCTestExpectation>()
    static var receivedEvents: [ACPExtensionEvent] = []
    
    override func hear(_ event: ACPExtensionEvent) {
        guard let parentExtension = self.extension as? InstrumentedExtension else { return }
        
        InstrumentedWildcardListener.receivedEvents.append(event)
        
        if event.eventType.lowercased() == FunctionalTestConst.EventType.instrumentedExtension.lowercased() {
            // process the shared state request event
            if event.eventSource.lowercased() == FunctionalTestConst.EventSource.sharedStateRequest.lowercased() {
                parentExtension.processSharedStateRequest(event)
            }
                // process the unregister extension event
            else if event.eventSource.lowercased() == FunctionalTestConst.EventSource.unregisterExtension.lowercased() {
                parentExtension.unregisterExtension()
            }
            
            return
        }
        
        // fulfill event expectations (if any registered before)
        if let expectation = InstrumentedWildcardListener.expectations[EventSpec(type: event.eventType, source: event.eventSource)] {
            expectation.fulfill()
            ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "Expected event received with type \(event.eventType) and source \(event.eventSource)")
        } else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "Event received, but not expected of type \(event.eventType) and source \(event.eventSource)")
        }
    }
}

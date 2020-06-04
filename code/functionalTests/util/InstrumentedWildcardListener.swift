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
    
    // Expected events Dictionary - key: EventSpec, value: the expected count
    static var expectedEvents: Dictionary<EventSpec, Int> = Dictionary<EventSpec, Int>()
    
    // All the events seen by this listener that are not of type instrumentedExtension
    static var receivedEvents: Dictionary<EventSpec, [ACPExtensionEvent]> = Dictionary<EventSpec, [ACPExtensionEvent]>()
    
    override func hear(_ event: ACPExtensionEvent) {
        guard let parentExtension = self.extension as? InstrumentedExtension else { return }
        
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
        
        if var previousReceivedEvents = InstrumentedWildcardListener.receivedEvents[EventSpec(type: event.eventType, source: event.eventSource)] {
            InstrumentedWildcardListener.receivedEvents[EventSpec(type: event.eventType, source: event.eventSource)]?.append(event)
        } else {
            InstrumentedWildcardListener.receivedEvents[EventSpec(type: event.eventType, source: event.eventSource)] = [event]
        }
        
        
        ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "Received event with type \(event.eventType) and source \(event.eventSource)")
    }
    
    static func reset() {
        receivedEvents.removeAll()
        expectedEvents.removeAll()
    }
}

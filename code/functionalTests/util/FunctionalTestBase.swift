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

/// Struct defining the event specifications - contains the event type and source
struct EventSpec {
    let type: String
    let source: String
}

/// Hashable `EventSpec`, to be used as key in Dictionaries
extension EventSpec : Hashable {
    static func == (lhs: EventSpec, rhs: EventSpec) -> Bool {
        return lhs.source.lowercased() == rhs.source.lowercased() && lhs.type.lowercased() == rhs.type.lowercased()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(source)
    }
}

class FunctionalTestBase : XCTestCase {
    private static let DEFAULT_EVENTS_WAIT_TIMEOUT:TimeInterval = 1.0
    private static let DEFAULT_WAIT_TIMEOUT:UInt32 = 1 // used when no expectation was set
    
    public override func setUp() {
        super.setUp()
        ACPCore.setLogLevel(ACPMobileLogLevel.verbose)
        guard let _ = try? ACPCore.registerExtension(InstrumentedExtension.self) else {
            print("Unable to register InstrumentedExtension")
            return
        }
        ACPCore.start()
    }
    
    public override func tearDown() {
        InstrumentedWildcardListener.receivedEvents = []
    }
    
    
    /// Sets an expectation for a specific event type and source and how many times the event should be dispatched
    /// - Parameters:
    ///   - type: the event type as a `String`, should not be empty
    ///   - source: the event source as a `String`, should not be empty
    ///   - count: the number of times this event should be dispatched, but default it is set to 1
    func setEventExpectation(type: String, source: String, count: Int = 1) {
        guard count > 0, !type.isEmpty, !source.isEmpty else { return }
        
        let newExpectation = XCTestExpectation(description: "Expect \(String(describing: count)) event(s) dispatched with type \(type) and source \(source)")
        newExpectation.expectedFulfillmentCount = count
        
        InstrumentedWildcardListener.expectations[EventSpec(type: type, source: source)] = newExpectation
    }
    
    /// Returned the `ACPExtensionEvent`(s) dispatched through the Event Hub, or empty if none was found.
    /// Use this API after calling `setEventExpectation(type:source:count:)` to wait for the right amount of time
    /// - Parameters:
    ///   - type: the event type as in the exectation
    ///   - source: the event source as in the expectation
    ///   - timeout: how long should this method wait for the expected event, in seconds; by default it waits up to 1 second
    /// - Returns: list of events with the provided `type` and `source`, or empty if none was dispatched
    func getDispatchedEventsWith(type: String, source: String, timeout: TimeInterval = DEFAULT_EVENTS_WAIT_TIMEOUT) -> [ACPExtensionEvent] {
        if let expectation = InstrumentedWildcardListener.expectations[EventSpec(type: type, source: source)] {
            wait(for: [expectation], timeout: timeout)
        } else {
            sleep(1)
        }
        
        let matchingEvents = InstrumentedWildcardListener.receivedEvents.filter{ $0.eventType.lowercased() == type.lowercased() &&
            $0.eventSource.lowercased() == source.lowercased() }
        return matchingEvents
    }
}


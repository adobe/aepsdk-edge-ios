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
    /// Use this setting to enable debug mode logging in the `FunctionalTestBase`
    static var debugEnabled = false
    
    public class override func setUp() {
        ACPCore.setLogLevel(ACPMobileLogLevel.verbose)
        guard let _ = try? ACPCore.registerExtension(InstrumentedExtension.self) else {
            log("Unable to register the InstrumentedExtension")
            return
        }
        ACPCore.start()
    }
    
    public override func tearDown() {
        InstrumentedWildcardListener.reset()
    }
    
    /// Unregisters the `InstrumentedExtension` from the Event Hub. This method executes asynchronous.
    func unregisterInstrumentedExtension() {
        guard let event = try? ACPExtensionEvent(name: "Unregister Instrumented Extension",
                                                 type: FunctionalTestConst.EventType.instrumentedExtension,
                                                 source: FunctionalTestConst.EventSource.unregisterExtension,
                                                 data: nil) else {
                                                    log("Failed to create unregisterExtension event")
                                                    return
        }
        
        guard let _ = try? ACPCore.dispatchEvent(event) else {
            log("Unable to unregister the InstrumentedExtension")
            return
        }
    }
    
    /// Sets an expectation for a specific event type and source and how many times the event should be dispatched
    /// - Parameters:
    ///   - type: the event type as a `String`, should not be empty
    ///   - source: the event source as a `String`, should not be empty
    ///   - count: the number of times this event should be dispatched, but default it is set to 1
    func setEventExpectation(type: String, source: String, count: Int = 1) {
        guard count > 0 else {
            assertionFailure("setEventExpectation - Expected event count should be greater than 0")
            return
        }
        guard !type.isEmpty, !source.isEmpty else {
            assertionFailure("setEventExpectation - Expected event type and source should be non-empty trings")
            return
        }
        
        InstrumentedWildcardListener.expectedEvents[EventSpec(type: type, source: source)] = count
    }
    
    
    /// Asserts if any unexpected event was received. Use this method to verify the received events are correct when setting event expectations.
    /// - See also: setEventExpectation(type: source: count:)
    func assertUnexpectedEvents(file: StaticString = #file, line: UInt = #line) {
        wait()
        var unexpectedEventsReceivedCount = 0
        for receivedEvent in InstrumentedWildcardListener.receivedEvents {
            if InstrumentedWildcardListener.expectedEvents[EventSpec(type: receivedEvent.key.type, source: receivedEvent.key.source)] == nil {
                unexpectedEventsReceivedCount += 1
                log("Received unexpected event with type: \(receivedEvent.key.type) source: \(receivedEvent.key.source)")
            }
        }
        
        XCTAssertEqual(0, unexpectedEventsReceivedCount, "Received \(unexpectedEventsReceivedCount) unexpected event(s)", file: file, line: line)
    }
    
    /// Asserts if all the expected events were received and fails if an unexpected event was seen
    /// - Parameters:
    ///   - ignoreUnexpectedEvents: if set on false, an assertion is made on unexpected events, otherwise the unexpected events are ignored
    /// - See also:
    ///   - setEventExpectation(type: source: count:)
    ///   - assertUnexpectedEvents()
    func assertExpectedEvents(ignoreUnexpectedEvents: Bool = false, file: StaticString = #file, line: UInt = #line) {
        wait()
        
        for expectedEvent in InstrumentedWildcardListener.expectedEvents {
            guard let receivedEvents = InstrumentedWildcardListener.receivedEvents[expectedEvent.key] else {
                XCTFail("Expected \(expectedEvent.value) event(s) of type \(expectedEvent.key.type) and source \(expectedEvent.key.source), but none was received.", file: file, line: line)
                return
            }
            
            XCTAssertEqual(expectedEvent.value, receivedEvents.count, "Expected \(expectedEvent.value) event(s) of type \(expectedEvent.key.type) and source \(expectedEvent.key.source), but received \(receivedEvents.count)", file: file, line: line)
        }
        
        guard ignoreUnexpectedEvents == false else { return }
        assertUnexpectedEvents(file: file, line: line)
    }
    
    /// To be revisited once AMSDK-10169 is implemented
    func wait(timeout: UInt32? = FunctionalTestConst.Defaults.waitTimeout) {
        sleep(timeout!)
    }
    
    /// Returned the `ACPExtensionEvent`(s) dispatched through the Event Hub, or empty if none was found.
    /// Use this API after calling `setEventExpectation(type:source:count:)` to wait for the right amount of time
    /// - Parameters:
    ///   - type: the event type as in the exectation
    ///   - source: the event source as in the expectation
    ///   - timeout: how long should this method wait for the expected event, in seconds; by default it waits up to 1 second
    /// - Returns: list of events with the provided `type` and `source`, or empty if none was dispatched
    func getDispatchedEventsWith(type: String, source: String, timeout: TimeInterval = FunctionalTestConst.Defaults.waitEventTimeout) -> [ACPExtensionEvent] {
        wait()
        return InstrumentedWildcardListener.receivedEvents[EventSpec(type: type, source: source)] ?? []
    }
    
    /// Synchronous call to get the shared state for the specified `stateOwner`. This API throws an assertion failure in case of timeout.
    /// - Parameter ownerExtension: the owner extension of the shared state (typically the name of the extension)
    /// - Parameter timeout: how long should this method wait for the requested shared state, in seconds; by default it waits up to 3 second
    /// - Returns: latest shared state of the given `stateOwner` or nil if no shared state was found
    func getSharedStateFor(_ ownerExtension:String, timeout: TimeInterval = FunctionalTestConst.Defaults.waitSharedStateTimeout) -> [AnyHashable : Any]? {
        log("GetSharedState for \(ownerExtension)")
        guard let event = try? ACPExtensionEvent(name: "Get Shared State",
                                                 type: FunctionalTestConst.EventType.instrumentedExtension,
                                                 source: FunctionalTestConst.EventSource.sharedStateRequest,
                                                 data: ["stateowner" : ownerExtension]) else {
                                                    log("GetSharedState failed to create request event.")
                                                    return nil
        }
        
        var returnedState: [AnyHashable:Any]? = nil
        
        let expectation = XCTestExpectation(description: "Shared state data returned")
        try? ACPCore.dispatchEvent(withResponseCallback: event) { (event) in
            
            if let eventData = event.eventData {
                returnedState = eventData["state"] as? [AnyHashable:Any]
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
        return returnedState
    }
    
    /// Print message to console if `FunctionalTestBase.debug` is true
    /// - Parameter message: message to log to console
    func log(_ message: String) {
        FunctionalTestBase.log(message)
        
    }
    
    /// Print message to console if `FunctionalTestBase.debug` is true
    /// - Parameter message: message to log to console
    private static func log(_ message: String) {
        guard !message.isEmpty && FunctionalTestBase.debugEnabled else { return }
        print("FunctionalTestBase - \(message)")
    }
}


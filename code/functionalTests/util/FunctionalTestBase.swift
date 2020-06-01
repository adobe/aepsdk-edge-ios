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
        InstrumentedWildcardListener.receivedEvents = []
        InstrumentedWildcardListener.expectations.removeAll()
    }
    
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
    func getDispatchedEventsWith(type: String, source: String, timeout: TimeInterval = FunctionalTestConst.Defaults.waitEventTimeout) -> [ACPExtensionEvent] {
        if let expectation = InstrumentedWildcardListener.expectations[EventSpec(type: type, source: source)] {
            wait(for: [expectation], timeout: timeout)
        } else {
            sleep(1)
        }
        
        let matchingEvents = InstrumentedWildcardListener.receivedEvents.filter{ $0.eventType.lowercased() == type.lowercased() &&
            $0.eventSource.lowercased() == source.lowercased() }
        return matchingEvents
    }
    
    /// Synchronous call to get the shared state for the specified `stateOwner`.
    /// - Parameter stateOwner: the owner of the shared state (typically the name of the extension)
    /// - Parameter timeout: how long should this method wait for the requested shared state, in seconds; by default it waits up to 3 second
    /// - Returns: latest shared state of the given `stateOwner` or nil if no shared state was found
    static func getSharedStateFor(_ stateOwner:String, timeout: TimeInterval = FunctionalTestConst.Defaults.waitSharedStateTimeout) -> [AnyHashable : Any]? {
        log("GetSharedState for \(stateOwner)")
        guard let event = try? ACPExtensionEvent(name: "Get Shared State",
                                                 type: FunctionalTestConst.EventType.instrumentedExtension,
                                                 source: FunctionalTestConst.EventSource.sharedStateRequest,
                                                 data: ["stateowner" : stateOwner]) else {
                                                    log("GetSharedState failed to create request event.")
                                                    return nil
        }
        
        var returnedState: [AnyHashable:Any]? = nil
        let semaphore = DispatchSemaphore(value: 0)
        
        try? ACPCore.dispatchEvent(withResponseCallback: event) { (event) in
            
            if let eventData = event.eventData {
                returnedState = eventData["state"] as? [AnyHashable:Any]
            }
            semaphore.signal()
        }
        
        let timeoutResult = semaphore.wait(timeout: .now() + timeout)
        log("GetSharedState timeout result was (\(timeoutResult)).")
        return returnedState
    }
    
    /// Print message to console if `FunctionalTestBase.debug` is true
    /// - Parameter message: message to log to console
    private func log(_ message: String) {
        if FunctionalTestBase.debugEnabled {
            print("FunctionalTestBase - \(message)")
        }
    }
    
    /// Print message to console if `FunctionalTestBase.debug` is true
    /// - Parameter message: message to log to console
    static func log(_ message: String) {
        if debugEnabled {
            print("FunctionalTestBase - \(message)")
        }
    }
}


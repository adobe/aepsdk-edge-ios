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
@testable import AEPExperiencePlatform
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
    private static var firstRun = true
    private static var networkService: FunctionalTestNetworkService = FunctionalTestNetworkService()
    /// Use this setting to enable debug mode logging in the `FunctionalTestBase`
    static var debugEnabled = false
    
    public class override func setUp() {
        super.setUp()
        FunctionalTestUtils.resetUserDefaults()
        ACPCore.setLogLevel(ACPMobileLogLevel.verbose)
        networkService = FunctionalTestNetworkService()
        AEPServiceProvider.shared.networkService = networkService
    }
    
    public override func setUp() {
        super.setUp()
        continueAfterFailure = false
        if FunctionalTestBase.firstRun {
            let startLatch: CountDownLatch = CountDownLatch(1)
            setExpectationEvent(type: FunctionalTestConst.EventType.eventHub, source: FunctionalTestConst.EventSource.booted, count: 1)
            // event hub shared state containing registered versions
            setExpectationEvent(type: FunctionalTestConst.EventType.eventHub, source: FunctionalTestConst.EventSource.sharedState, count: 1)
            guard let _ = try? ACPCore.registerExtension(InstrumentedExtension.self) else {
                log("Unable to register the InstrumentedExtension")
                return
            }
            ACPCore.start {
                startLatch.countDown()
            }
            
            XCTAssertEqual(DispatchTimeoutResult.success, startLatch.await(timeout: 2))
            assertExpectedEvents(ignoreUnexpectedEvents: false)
            resetTestExpectations()
        }
        FunctionalTestBase.firstRun = false
        
    }
    
    public override func tearDown() {
        super.tearDown()
        resetTestExpectations()
    }
    
    /// Reset event and network request expectations and drop the items received until this point
    func resetTestExpectations() {
        log("Resetting functional test expectations for events and network requests")
        InstrumentedWildcardListener.reset()
        FunctionalTestBase.networkService.reset()
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
    
    // MARK: Expected/Unexpected events assertions
    
    /// Sets an expectation for a specific event type and source and how many times the event should be dispatched
    /// - Parameters:
    ///   - type: the event type as a `String`, should not be empty
    ///   - source: the event source as a `String`, should not be empty
    ///   - count: the number of times this event should be dispatched, but default it is set to 1
    /// - See also:
    ///   - assertExpectedEvents(ignoreUnexpectedEvents:)
    func setExpectationEvent(type: String, source: String, count: Int32 = 1) {
        guard count > 0 else {
            assertionFailure("Expected event count should be greater than 0")
            return
        }
        guard !type.isEmpty, !source.isEmpty else {
            assertionFailure("Expected event type and source should be non-empty trings")
            return
        }
        
        InstrumentedWildcardListener.expectedEvents[EventSpec(type: type, source: source)] = CountDownLatch(count)
    }
    
    /// Asserts if all the expected events were received and fails if an unexpected event was seen
    /// - Parameters:
    ///   - ignoreUnexpectedEvents: if set on false, an assertion is made on unexpected events, otherwise the unexpected events are ignored
    /// - See also:
    ///   - setExpectationEvent(type: source: count:)
    ///   - assertUnexpectedEvents()
    func assertExpectedEvents(ignoreUnexpectedEvents: Bool = false, file: StaticString = #file, line: UInt = #line) {
        guard InstrumentedWildcardListener.expectedEvents.count > 0 else {
            assertionFailure("There are no event expectations set, use this API after calling setExpectationEvent", file: file, line: line)
            return
        }
        
        for expectedEvent in InstrumentedWildcardListener.expectedEvents {
            let waitResult = expectedEvent.value.await(timeout: FunctionalTestConst.Defaults.waitEventTimeout)
            let expectedCount: Int32 = expectedEvent.value.getInitialCount()
            let receivedCount: Int32 = expectedEvent.value.getInitialCount() - expectedEvent.value.getCurrentCount()
            XCTAssertFalse(waitResult ==  DispatchTimeoutResult.timedOut, "Timed out waiting for event type \(expectedEvent.key.type) and source \(expectedEvent.key.source), expected \(expectedCount), but received \(receivedCount)", file: file, line: line)
            XCTAssertEqual(expectedCount, receivedCount, "Expected \(expectedCount) event(s) of type \(expectedEvent.key.type) and source \(expectedEvent.key.source), but received \(receivedCount)", file: file, line: line)
        }
        
        guard ignoreUnexpectedEvents == false else { return }
        assertUnexpectedEvents(file: file, line: line)
    }
    
    /// Asserts if any unexpected event was received. Use this method to verify the received events are correct when setting event expectations.
    /// - See also: setExpectationEvent(type: source: count:)
    func assertUnexpectedEvents(file: StaticString = #file, line: UInt = #line) {
        wait()
        var unexpectedEventsReceivedCount = 0
        var unexpectedEventsAsString = ""
        for receivedEvent in InstrumentedWildcardListener.receivedEvents {
            
            // check if event is expected and it is over the expected count
            if let expectedEvent = InstrumentedWildcardListener.expectedEvents[EventSpec(type: receivedEvent.key.type, source: receivedEvent.key.source)] {
                let _ = expectedEvent.await(timeout: FunctionalTestConst.Defaults.waitEventTimeout)
                let expectedCount: Int32 = expectedEvent.getInitialCount()
                let receivedCount: Int32 = expectedEvent.getInitialCount() - expectedEvent.getCurrentCount()
                XCTAssertEqual(expectedCount, receivedCount, "Expected \(expectedCount) events of type \(receivedEvent.key.type) and source \(receivedEvent.key.source), but received \(receivedCount)", file: file, line: line)
            }
                // check for events that don't have expectations set
            else {
                unexpectedEventsReceivedCount += receivedEvent.value.count
                unexpectedEventsAsString.append("(\(receivedEvent.key.type), \(receivedEvent.key.source), \(receivedEvent.value.count)),")
                log("Received unexpected event with type: \(receivedEvent.key.type) source: \(receivedEvent.key.source)")
            }
        }
        
        XCTAssertEqual(0, unexpectedEventsReceivedCount, "Received \(unexpectedEventsReceivedCount) unexpected event(s): \(unexpectedEventsAsString)", file: file, line: line)
    }
    
    /// To be revisited once AMSDK-10169 is implemented
    func wait(_ timeout: UInt32? = FunctionalTestConst.Defaults.waitTimeout) {
        sleep(timeout!)
    }
    
    /// Returns the `ACPExtensionEvent`(s) dispatched through the Event Hub, or empty if none was found.
    /// Use this API after calling `setExpectationEvent(type:source:count:)` to wait for the right amount of time
    /// - Parameters:
    ///   - type: the event type as in the exectation
    ///   - source: the event source as in the expectation
    ///   - timeout: how long should this method wait for the expected event, in seconds; by default it waits up to 1 second
    /// - Returns: list of events with the provided `type` and `source`, or empty if none was dispatched
    func getDispatchedEventsWith(type: String, source: String, timeout: TimeInterval = FunctionalTestConst.Defaults.waitEventTimeout, file: StaticString = #file, line: UInt = #line) -> [ACPExtensionEvent] {
        if let _ = InstrumentedWildcardListener.expectedEvents[EventSpec(type: type, source: source)] {
            let waitResult = InstrumentedWildcardListener.expectedEvents[EventSpec(type: type, source: source)]?.await(timeout: timeout)
            XCTAssertFalse(waitResult ==  DispatchTimeoutResult.timedOut, "Timed out waiting for event type \(type) and source \(source)", file: file, line: line)
        } else {
            wait(FunctionalTestConst.Defaults.waitTimeout)
        }
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
    
    // MARK: Network Service helpers
    
    /// Set a custom network response to a network request
    /// - Parameters:
    ///   - url: The URL for which to return the response
    ///   - httpMethod: The `HttpMethod` for which to return the response, along with the `url`
    ///   - responseHttpConnection: `HttpConnection` to be returned when a `NetworkRequest` with the specified `url` and `httpMethod` is seen; when nil  is provided the default
    ///                             `HttpConnection` is returned
    func setNetworkResponseFor(url: String, httpMethod: HttpMethod, responseHttpConnection: HttpConnection?) {
        guard let requestUrl = URL(string: url) else {
            assertionFailure("Unable to convert the provided string \(url) to URL")
            return
        }
        
        FunctionalTestBase.networkService.responseMatchers[NetworkRequest(url: requestUrl, httpMethod: httpMethod)] = responseHttpConnection
    }
    
    /// Set  a network request expectation.
    ///
    /// - Parameters:
    ///   - url: The URL for which to set the expectation
    ///   - httpMethod: the `HttpMethod` for which to set the expectation, along with the `url`
    ///   - count: how many times a request with this url and httpMethod is expected to be sent, by default it is set to 1
    /// - See also:
    ///     - assertNetworkRequestsCount()
    ///     - getNetworkRequestsWith(url:httpMethod:)
    func setExpectationNetworkRequest(url: String, httpMethod: HttpMethod, count: Int32 = 1, file: StaticString = #file, line: UInt = #line) {
        guard count > 0 else {
            assertionFailure("Expected event count should be greater than 0")
            return
        }
        
        guard let requestUrl = URL(string: url) else {
            assertionFailure("Unable to convert the provided string \(url) to URL")
            return
        }
        
        FunctionalTestBase.networkService.expectedNetworkRequests[NetworkRequest(url: requestUrl, httpMethod: httpMethod)] = CountDownLatch(count)
    }
    
    /// Asserts that the correct number of network requests were being sent, based on the previously set expectations.
    /// - See also:
    ///     - setExpectationNetworkRequest(url:httpMethod:)
    func assertNetworkRequestsCount(file: StaticString = #file, line: UInt = #line) {
        guard FunctionalTestBase.networkService.expectedNetworkRequests.count > 0 else {
            assertionFailure("There are no network request expectations set, use this API after calling setExpectationNetworkRequest")
            return
        }
        
        for expectedRequest in FunctionalTestBase.networkService.expectedNetworkRequests {
            let waitResult = expectedRequest.value.await(timeout: 2)
            let expectedCount: Int32 = expectedRequest.value.getInitialCount()
            let receivedCount: Int32 = expectedRequest.value.getInitialCount() - expectedRequest.value.getCurrentCount()
            XCTAssertFalse(waitResult ==  DispatchTimeoutResult.timedOut, "Timed out waiting for network request(s) with URL \(expectedRequest.key.url.absoluteString) and HTTPMethod \(expectedRequest.key.httpMethod.toString()), expected \(expectedCount) but received \(receivedCount)", file: file, line: line)
            XCTAssertEqual(expectedCount, receivedCount, "Expected \(expectedCount) network request(s) for URL \(expectedRequest.key.url.absoluteString) and HTTPMethod \(expectedRequest.key.httpMethod.toString()), but received \(receivedCount)", file: file, line: line)
        }
    }
    
    /// Returns the `NetworkRequest`(s) sent through the Core NetworkService, or empty if none was found.
    /// Use this API after calling `setExpectationNetworkRequest(url:httpMethod:count:)` to wait for the right amount of time
    /// - Parameters:
    ///   - url: The URL for which to retrieved the network requests sent, should be a valid URL
    ///   - httpMethod: the `HttpMethod` for which to retrieve the network requests, along with the `url`
    ///   - timeout: how long should this method wait for the expected network requests, in seconds; by default it waits up to 1 second
    /// - Returns: list of network requests with the provided `url` and `httpMethod`, or empty if none was dispatched
    /// - See also:
    ///     - setExpectationNetworkRequest(url:httpMethod:)
    func getNetworkRequestsWith(url: String, httpMethod: HttpMethod, timeout: TimeInterval = FunctionalTestConst.Defaults.waitNetworkRequestTimeout, file: StaticString = #file, line: UInt = #line) -> [NetworkRequest] {
        guard let requestUrl = URL(string: url) else {
            assertionFailure("Unable to convert the provided string \(url) to URL")
            return []
        }
        
        let networkRequest = NetworkRequest(url: requestUrl, httpMethod: httpMethod)
        if let expectedRequest = FunctionalTestBase.networkService.expectedNetworkRequests[networkRequest] {
            let waitResult = expectedRequest.await(timeout: timeout)
            XCTAssertFalse(waitResult ==  DispatchTimeoutResult.timedOut, "Timed out waiting for network request(s) with URL \(url) and HTTPMethod \(httpMethod.toString())", file: file, line: line)
        } else {
            wait(FunctionalTestConst.Defaults.waitTimeout)
        }
        
        return FunctionalTestBase.networkService.receivedNetworkRequests[networkRequest] ?? []
    }
    
    /// Use this API for JSON formatted `NetworkRequest` body in order to retrieve a flattened dictionary containing its data.
    /// This API fails the assertion if the request body cannot be parsed as JSON.
    /// - Parameters:
    ///   - networkRequest: the NetworkRequest to parse
    /// - Returns: The JSON request body represented as a flatten dictionary
    func getFlattenNetworkRequestBody(_ networkRequest: NetworkRequest, file: StaticString = #file, line: UInt = #line) -> [String: Any] {
        
        if !networkRequest.connectPayload.isEmpty {
            let data = Data(networkRequest.connectPayload.utf8)
            if let payloadAsDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return flattenDictionary(dict: payloadAsDictionary)
            } else {
                XCTFail("Failed to parse networkRequest.connectionPayload to JSON", file: file, line: line)
            }
        }
        
        log("Connection payload is empty for network request with URL \(networkRequest.url.absoluteString), HTTPMethod \(networkRequest.httpMethod.toString())")
        return [:]
    }
    
    /// Print message to console if `FunctionalTestBase.debug` is true
    /// - Parameter message: message to log to console
    func log(_ message: String) {
        FunctionalTestBase.log(message)
        
    }
    
    /// Print message to console if `FunctionalTestBase.debug` is true
    /// - Parameter message: message to log to console
    static func log(_ message: String) {
        guard !message.isEmpty && FunctionalTestBase.debugEnabled else { return }
        print("FunctionalTestBase - \(message)")
    }
}


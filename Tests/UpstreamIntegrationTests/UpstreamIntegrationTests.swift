//
// Copyright 2023 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@testable import AEPCore
import AEPEdge
import AEPEdgeIdentity
import AEPServices
import Foundation
import XCTest

/// Struct defining the event specifications - contains the event type and source
struct EventSpec {
    let type: String
    let source: String
}

/// Hashable `EventSpec`, to be used as key in Dictionaries
extension EventSpec: Hashable & Equatable {

    static func == (lhs: EventSpec, rhs: EventSpec) -> Bool {
        return lhs.source.lowercased() == rhs.source.lowercased() && lhs.type.lowercased() == rhs.type.lowercased()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(source)
    }
}

/// This test class validates proper intergration with upstream services, specifically Edge Network
class UpstreamIntegrationTests: XCTestCase {
    private var edgeEnvironment: EdgeEnvironment = .prod
    private var edgeLocationHint: EdgeLocationHint? = nil
    
    private let testingDelegate = NetworkTestingDelegate()
    
    let LOG_SOURCE = "SampleFunctionalTests"
    
    let asyncTimeout: TimeInterval = 10
    
    override func setUp() {
        let networkService = IntegrationTestNetworkService()
        networkService.testingDelegate = testingDelegate
        ServiceProvider.shared.networkService = networkService
        
        // Extract Edge Network environment level from shell environment; see init for default value
        self.edgeEnvironment = EdgeEnvironment()
        print("Using Edge Network environment: \(edgeEnvironment.rawValue)")
        
        // Extract Edge location hint from shell environment; see init for default value
        self.edgeLocationHint = EdgeLocationHint()
        
        let waitForRegistration = CountDownLatch(1)
        MobileCore.setLogLevel(.trace)
        // Set environment file ID for specific Edge Network environment
        setMobileCoreEnvironmentFileID(for: edgeEnvironment)
        MobileCore.registerExtensions([Identity.self, Edge.self, InstrumentedExtension.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))
        
        // Set Edge location hint value if one is set for the test target
        if edgeLocationHint != nil {
            print("Setting Edge location hint to: \(String(describing: edgeLocationHint?.rawValue))")
            Edge.setLocationHint(edgeLocationHint?.rawValue)
        }
        else {
            print("No preset Edge location hint is being used for this test.")
        }
    }
    
    public override func tearDown() {
        super.tearDown()
        
        // to revisit when AMSDK-10169 is available
        // wait .2 seconds in case there are unexpected events that were in the dispatch process during cleanup
        usleep(200000)
        EventHub.reset()
        UserDefaults.clearAll()
        FileManager.default.clearCache()
    }
    
    // IMPLEMENTATION PLAN
    // 1. use instrumented extension to capture all events going through the Event Hub
    // 2. use the event fetching method to extract relevant events
    // 3. do the assertion using flexible json compare
        // make notes on how often exact match is needed vs flexible and perform necessary base logic tweaking
    
    // dont have to convert every case, just good example cases from each class of assertions
    
    // For proving usefulness of tooling, create
    /// for location hint validation example
        // test case where you only strongly validate the "source" key
        // test case where you only strongy valdiate multiple "source" keys (ex: EdgeNetwork and Target)
        // test case where you strongly validate everything -> this is covered by the converted functional test cases
    
    // also create test cases outside of location hint that are relevant in the integration test case, to better prove out classes of assertions and need
    // also convert some cases from the examples Emilia sent
    /// Consent test cases
    
    // also need to create a test suite for the equality comparisons themselves
    // and need to update the logic to compile all the results since right now it returns immediately?

    // MARK: - Functional test examples
    // MARK: test request event format
    func testSendEvent_withXDMData_sendsCorrectRequestEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.REQUEST_CONTENT)

        let xdmJSON = #"""
        {
          "xdm": {
            "testString": "xdm",
            "testInt": 10,
            "testBool": false,
            "testDouble": 12.89,
            "testArray": ["arrayElem1", 2, true],
            "testDictionary": {
              "key": "val"
            }
          }
        }
        """#
        
        guard let xdm = getXDMPayload(xdmJSON) else {
            XCTFail("Unable to decode JSON string")
            return
        }
        
        let experienceEvent = ExperienceEvent(xdm: xdm.payload)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: true) // NOTE: this is different (true instead of false) from functional test case since the response is not mocked
        let resultEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE,
                                                   source: FunctionalTestConst.EventSource.REQUEST_CONTENT)
        
        guard let eventDataDict = resultEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        
        AnyCodableUtils.assertEqual(expected: xdm.expected, actual: AnyCodable(AnyCodable.from(dictionary: eventDataDict)))
    }
    
    func testSendEvent_withXDMDataAndCustomData_sendsCorrectRequestEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.REQUEST_CONTENT)
        
        let expectedJSON = #"""
        {
          "xdm": {
            "testString": "xdm"
          },
          "data": {
            "testDataString": "stringValue",
            "testDataInt": 101,
            "testDataBool": true,
            "testDataDouble": 13.66,
            "testDataArray": ["arrayElem1", 2, true],
            "testDataDictionary": {
              "key": "val"
            }
          }
        }
        """#
        
        guard let xdm = getXDMPayload(expectedJSON), let data = getDataPayload(expectedJSON) else {
            XCTFail("Unable to decode JSON string")
            return
        }
        
        let experienceEvent = ExperienceEvent(xdm: xdm.payload, data: data.payload)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: true)
        let resultEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE,
                                                   source: FunctionalTestConst.EventSource.REQUEST_CONTENT)
        guard let eventDataDict = resultEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        
        AnyCodableUtils.assertEqual(expected: xdm.expected, actual: AnyCodable(AnyCodable.from(dictionary: eventDataDict)))
    }
    
    /// This test case demonstrates flexible validation but only on exact match key paths
    func testLocationHint_onlyExpectedKeys() {
        let expectedJSON = #"""
        {
          "payload": [
            {
              "scope" : "EdgeNetwork"
            }
          ]
        }
        """#
        
        let actualJSON = #"""
           {
             "payload": [
               {
                 "ttlSeconds" : 1800,
                 "scope" : "Target",
                 "hint" : "35"
               },
               {
                 "ttlSeconds" : 1800,
                 "scope" : "AAM",
                 "hint" : "9"
               },
               {
                 "ttlSeconds" : 1800,
                 "scope" : "EdgeNetwork",
                 "hint" : "or2"
               }
             ]
           }
        """#
        
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }
        
        AnyCodableUtils.assertContains(expected: expected, actual: actual, exactMatchPaths: ["payload[*].scope"])
    }
    
    /// Demonstrates flexible validation using general wildcard match but only on exact match key paths
    /// Use cases covered:
    /// 1. Array general wildcard matching: exact match path -> `[*]`
    /// 2. Array subset matching: only 2/3 on the expected side
    /// 3. Exact match validation on only specific subset of keys in a dictionary: exact match path -> `.scope`
    func testLocationHint_onlyExpectedKeys_usingGeneralWildcard() {
        let expectedJSON = #"""
        {
          "payload": [
            {
              "scope" : "EdgeNetwork"
            },
            {
              "scope" : "Target"
            }
          ]
        }
        """#
        
        let actualJSON = #"""
        {
         "payload": [
           {
             "ttlSeconds" : 1800,
             "scope" : "Target",
             "hint" : "35"
           },
           {
             "ttlSeconds" : 1800,
             "scope" : "AAM",
             "hint" : "9"
           },
           {
             "ttlSeconds" : 1800,
             "scope" : "EdgeNetwork",
             "hint" : "or2"
           }
         ]
        }
        """#
        
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }
        
        AnyCodableUtils.assertContains(expected: expected, actual: actual, exactMatchPaths: ["payload[*].scope"])
    }
    
    /// Demonstrates flexible validation using general wildcard match but only on exact match key paths; shows example failure message
    ///
    /// See `testLocationHint_onlyExpectedKeys_usingGeneralWildcard` for use cases covered
    func testLocationHint_onlyExpectedKeys_usingGeneralWildcard_missingMatchShouldFail() {
        let expectedJSON = #"""
        {
          "payload": [
            {
              "scope" : "EdgeNetwork"
            },
            {
              "scope" : "Target"
            }
          ]
        }
        """#
        
        let actualJSON = #"""
        {
         "payload": [
           {
             "ttlSeconds" : 1800,
             "scope" : "Target",
             "hint" : "35"
           },
           {
             "ttlSeconds" : 1800,
             "scope" : "AAM",
             "hint" : "9"
           },
           {
             "ttlSeconds" : 1800,
             "scope" : "EdgeNetwork_DIFFERENT",
             "hint" : "or2"
           }
         ]
        }
        """#
        
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }
        
        AnyCodableUtils.assertContains(expected: expected, actual: actual, exactMatchPaths: ["payload[*].scope"])
    }
    
    /// Demonstrates flexible validation using general wildcard match but only on exact match key paths
    /// Use cases covered:
    /// 1. Array general wildcard matching: exact match path -> `[*]`
    /// 2. Array subset matching: only 2/3 on the expected side
    /// 3. Exact match validation on only specific subset of keys in a dictionary: exact match path -> `.scope`
    func testConsentUpdate_onlyExpectedKeys_usingGeneralWildcard() {
        let expectedJSON = #"""
        {
          "meta" : {
            "konductorConfig" : {
              "streaming" : {
                "enabled" : true,
                "recordSeparator" : "\u0000",
                "lineFeed" : "\n"
              }
            }
          },
          "query" : {
            "consent" : {
              "operation" : "update"
            }
          },
          "identityMap" : {
            "ECID" : [
              {
                "id" : "01568806327147089148132339481432735151",
                "authenticatedState" : "ambiguous",
                "primary" : false
              }
            ]
          },
          "consent" : [
            {
              "standard" : "Adobe",
              "version" : "2.0",
              "value" : {
                "collect" : {
                  "val" : "n"
                },
                "metadata" : {
                  "time" : "2023-04-21T21:56:52.455Z"
                }
              }
            }
          ]
        }
        """#
        
        let actualJSON = #"""
        {
          "meta" : {
            "konductorConfig" : {
              "streaming" : {
                "enabled" : true,
                "recordSeparator" : "\u0000",
                "lineFeed" : "\n"
              }
            }
          },
          "query" : {
            "consent" : {
              "operation" : "update"
            }
          },
          "identityMap" : {
            "ECID" : [
              {
                "id" : "01568806327147089148132339481432735151",
                "authenticatedState" : "ambiguous",
                "primary" : false
              }
            ]
          },
          "consent" : [
            {
              "standard" : "Adobe",
              "version" : "2.0",
              "value" : {
                "collect" : {
                  "val" : "n"
                },
                "metadata" : {
                  "time" : "2023-04-21T21:56:52.455Z"
                }
              }
            }
          ]
        }
        """#
        
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }
        
        AnyCodableUtils.assertContains(expected: expected, actual: actual, exactMatchPaths: [
            "payload[*].scope"
        ])
    }
    
    // MARK: - Upstream integration test cases

    // MARK: 1st launch scenarios
    func testSendEvent_withStandardExperienceEvent_receivesExpectedEventHandles() {
        // Setup
        // Test expectations that make sure the callbacks fire for:
        // 1. The network response from Edge Network
        // 2. The event response handles converted into events, captured by test case event listeners
        let edgeRequestContentExpectation = XCTestExpectation(description: "Edge extension request content listener called")
        let networkResponseExpectation = XCTestExpectation(description: "Network request callback called")
        
        // MARK: Network response assertions
        testingDelegate.testCaseCompletion = { httpConnection in
            print("SOURCE: testCaseCompletion: \(httpConnection)")
            print("data as string: \(httpConnection.responseString)")
            
            httpConnection.response?.url
            print("baseURL: \(httpConnection.response?.url?.host)")
            if httpConnection.response?.url?.host == "obumobile5.data.adobedc.net" {
                XCTAssertEqual(200, httpConnection.responseCode)
                networkResponseExpectation.fulfill()
            }
        }
        
        let validationJSON = #"""
        {
          "payload": [
            {
              "ttlSeconds" : 1800,
              "scope" : "EdgeNetwork",
              "hint" : "or2"
            }
          ]        }
        """#
        
        // MARK: Response Event assertions
        registerEdgeLocationHintListener() { event in
            XCTAssertNotNil(event)
            let data = event.data
            XCTAssertNotNil(data)
            guard let payloadArray = data?["payload"] as? [[String:Any]] else {
                XCTFail()
                return
            }
            print()
            let targetHint = payloadArray[0]
            guard let locationHintCorrectValue: [String:Any] = self.convertToJSON(validationJSON), let locationHintPayload = locationHintCorrectValue["payload"] as? [[String:Any]] else {
                XCTFail()
                return
            }
            
            // TODO: JSON dictionary compare
            XCTAssertEqual("Target", targetHint["scope"] as? String)
            XCTAssertEqual(1800, targetHint["ttlSeconds"] as? Int)
            
            Log.debug(label: self.LOG_SOURCE, "LISTENER: \(String(describing: data))")
            edgeRequestContentExpectation.fulfill()
        }
        
        // Test
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        Edge.sendEvent(experienceEvent: experienceEvent)
        
        
        // Verify
        wait(for: [edgeRequestContentExpectation, networkResponseExpectation], timeout: asyncTimeout)
        
        let resultEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: "locationHint:result")
        print(resultEvents)
    }
    
    func testFlexibleValidation() {
        let validationJSON = #"""
        {
          "payload": [
            {
              "ttlSeconds" : 1800,
              "scope" : "EdgeNetwork",
              "hint" : 1
            }
          ]
        }
        """#
        
        let inputJSON = #"""
       {
         "payload": [
           {
             "ttlSeconds" : 1800,
             "scope" : "Target",
             "hint" : "35"
           },
           {
             "ttlSeconds" : 1800,
             "scope" : "AAM",
             "hint" : "9"
           },
           {
             "ttlSeconds" : 1800,
             "scope" : "EdgeNetwork",
             "hint" : "or2"
           }
         ]
       }
       """#
        
        let jsonValidation = try? JSONDecoder().decode(AnyCodable.self, from: validationJSON.data(using: .utf8)!)
        let jsonInput = try? JSONDecoder().decode(AnyCodable.self, from: inputJSON.data(using: .utf8)!)
        AnyCodableUtils.assertContains(
            expected: jsonValidation,
            actual: jsonInput,
            exactMatchPaths: ["payload[*].scope"]
        )
    }
    
    func testFlexibleNestedArray() {
        let validationJSON = #"""
        {
          "payload": [
            [1]
          ]
        }
        """#
        
        let inputJSON = #"""
       {
         "payload": [
           [1,2,3]
         ]
       }
       """#
        
        let jsonValidation = try? JSONDecoder().decode(AnyCodable.self, from: validationJSON.data(using: .utf8)!)
        let jsonInput = try? JSONDecoder().decode(AnyCodable.self, from: inputJSON.data(using: .utf8)!)
        AnyCodableUtils.assertContains(
            expected: jsonValidation,
            actual: jsonInput,
            exactMatchPaths: []
        )
    }
    
    func testJSONComparisonSystem() {
        let multilineValidation = #"""
          {
            "integerCompare": 456,
            "decimalCompare": 123.123,
            "stringCompare": "abc",
            "boolCompare": true,
            "nullCompare": null,
            "arraySizeCompare": [1,2,3],
            "arrayValueCompare": [1],
            "arrayOfObjectsPass": [
              {
                "object1": "value1"
              },
              {
                "object2": "value2"
              }
            ],
            "arrayOfObjectsFail": [
              {
                "object1": "value1"
              },
              {
                "object2": "value2"
              }
            ],
            "dictionaryCompare": {
              "nested1": "value1"
            },
            "dictionaryNestedCompare": {
              "nested1": {
                "nested2": {
                  "nested3": {
                    "nested4": {
                      "nested1": "value1"
                    }
                  }
                }
              }
            },
            "trulyNested": [
              {
                "nest1": [
                  {
                    "nest2": {
                      "nest3": [
                        {
                          "nest4": "value1"
                        }
                      ]
                    }
                  }
                ]
              }
            ]
          }
        """#
        
        let multilineInput = #"""
          {
            "integerCompare": 0,
            "decimalCompare": 4.123,
            "stringCompare": "def",
            "boolCompare": false,
            "nullCompare": "not null",
            "arraySizeCompare": [1,2],
            "arrayValueCompare": [0],
            "arrayOfObjectsPass": [
              {
                "object1": "value1"
              },
              {
                "object2": "value2"
              }
            ],
            "arrayOfObjectsFail": [
              {
                "object1": "value1"
              },
              {
                "object2": "value3"
              }
            ],
            "dictionaryCompare": {
              "nested1different": "value1"
            },
            "dictionaryNestedCompare": {
              "nested1": {
                "nested2": {
                  "nested3": {
                    "nested4": {
                      "nested1": "value2"
                    }
                  }
                }
              }
            },
            "trulyNested": [
              {
                "nest1": [
                  {
                    "nest2": {
                      "nest3": [
                        [
                          "nest4"
                        ]
                      ]
                    }
                  }
                ]
              }
            ]
          }
        """#
        
        let jsonValidation = try? JSONDecoder().decode(AnyCodable.self, from: multilineValidation.data(using: .utf8)!)
        let jsonInput = try? JSONDecoder().decode(AnyCodable.self, from: multilineInput.data(using: .utf8)!)
        AnyCodableUtils.assertEqual(expected: jsonValidation, actual: jsonInput)
    }
    
    func testJSONComparison_ambiguousKeys() {
        let multilineInput = #"""
          {
            "key1.key2": {
              "key3": "value1"
            },
            "key1": {
              "key2": {
                "key3": "value1"
              }
            }
          }
        """#
        
        let multilineValidation = #"""
          {
            "key1.key2": {
              "key3": "value3"
            },
            "key1": {
              "key2": {
                "key3": "value1"
              }
            }
          }
        """#
        
        let jsonValidation = try? JSONDecoder().decode(AnyCodable.self, from: multilineValidation.data(using: .utf8)!)
        let jsonInput = try? JSONDecoder().decode(AnyCodable.self, from: multilineInput.data(using: .utf8)!)
        AnyCodableUtils.assertEqual(expected: jsonValidation, actual: jsonInput)
    }
    
    // MARK: - Test helper methods
    
    /// Converts a JSON string into the provided type.
    ///
    /// NOTE: caller is reponsible for providing the correct casting type resulting JSON, otherwise decoding will fail
    func convertToJSON<T>(_ jsonString: String) -> T? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Unable to convert provided JSON string to Data: \(jsonString)")
            return nil
        }
        
        guard let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? T else {
            XCTFail("Unable to convert provided JSON string to JSON type \(T.self)")
            return nil
        }
        return jsonDictionary
    }
    
    func setMobileCoreEnvironmentFileID(for edgeEnvironment: EdgeEnvironment) {
        switch edgeEnvironment {
        case .prod:
            MobileCore.configureWith(appId: "94f571f308d5/6b1be84da76a/launch-023a1b64f561-development")
        case .preProd:
            MobileCore.configureWith(appId: "94f571f308d5/6b1be84da76a/launch-023a1b64f561-development")
        case .int:
            // TODO: create integration environment environment file ID
            MobileCore.configureWith(appId: "94f571f308d5/6b1be84da76a/launch-023a1b64f561-development")
        }
    }
    
    // TODO: create specific listeners for type: Edge + source: * (wildcard) and capture all the response handles for the test event
    // TODO: create specific listeners for error responses
    func registerEdgeLocationHintListener(_ listener: @escaping EventListener) {
        MobileCore.registerEventListener(type: FunctionalTestConst.EventType.EDGE, source: "locationHint:result", listener: listener)
    }
    
    // MARK: - Instrumented Extension helpers
    
    /// To be revisited once AMSDK-10169 is implemented
    /// - Parameters:
    ///   - timeout:how long should this method wait, in seconds; by default it waits up to 1 second
    func wait(_ timeout: UInt32? = FunctionalTestConst.Defaults.WAIT_TIMEOUT) {
        if let timeout = timeout {
            sleep(timeout)
        }
    }

    /// Returns the `ACPExtensionEvent`(s) dispatched through the Event Hub, or empty if none was found.
    /// Use this API after calling `setExpectationEvent(type:source:count:)` to wait for the right amount of time
    /// - Parameters:
    ///   - type: the event type as in the expectation
    ///   - source: the event source as in the expectation
    ///   - timeout: how long should this method wait for the expected event, in seconds; by default it waits up to 1 second
    /// - Returns: list of events with the provided `type` and `source`, or empty if none was dispatched
    func getDispatchedEventsWith(type: String, source: String, timeout: TimeInterval = FunctionalTestConst.Defaults.WAIT_EVENT_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [Event] {
        if InstrumentedExtension.expectedEvents[EventSpec(type: type, source: source)] != nil {
            let waitResult = InstrumentedExtension.expectedEvents[EventSpec(type: type, source: source)]?.await(timeout: timeout)
            XCTAssertFalse(waitResult == DispatchTimeoutResult.timedOut, "Timed out waiting for event type \(type) and source \(source)", file: file, line: line)
        } else {
            wait(FunctionalTestConst.Defaults.WAIT_TIMEOUT)
        }
        return InstrumentedExtension.receivedEvents[EventSpec(type: type, source: source)] ?? []
    }
    
    /// Synchronous call to get the shared state for the specified `stateOwner`. This API throws an assertion failure in case of timeout.
    /// - Parameter ownerExtension: the owner extension of the shared state (typically the name of the extension)
    /// - Parameter timeout: how long should this method wait for the requested shared state, in seconds; by default it waits up to 3 second
    /// - Returns: latest shared state of the given `stateOwner` or nil if no shared state was found
    func getSharedStateFor(_ ownerExtension: String, timeout: TimeInterval = FunctionalTestConst.Defaults.WAIT_SHARED_STATE_TIMEOUT) -> [AnyHashable: Any]? {
        print("GetSharedState for \(ownerExtension)")
        let event = Event(name: "Get Shared State",
                          type: FunctionalTestConst.EventType.INSTRUMENTED_EXTENSION,
                          source: FunctionalTestConst.EventSource.SHARED_STATE_REQUEST,
                          data: ["stateowner": ownerExtension])

        var returnedState: [AnyHashable: Any]?

        let expectation = XCTestExpectation(description: "Shared state data returned")
        MobileCore.dispatch(event: event, responseCallback: { event in

            if let eventData = event?.data {
                returnedState = eventData["state"] as? [AnyHashable: Any]
            }
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: timeout)
        return returnedState
    }
    
    /// Asserts if all the expected events were received and fails if an unexpected event was seen
    /// - Parameters:
    ///   - ignoreUnexpectedEvents: if set on false, an assertion is made on unexpected events, otherwise the unexpected events are ignored
    /// - See also:
    ///   - setExpectationEvent(type: source: count:)
    ///   - assertUnexpectedEvents()
    func assertExpectedEvents(ignoreUnexpectedEvents: Bool = false, file: StaticString = #file, line: UInt = #line) {
        guard InstrumentedExtension.expectedEvents.count > 0 else { // swiftlint:disable:this empty_count
            assertionFailure("There are no event expectations set, use this API after calling setExpectationEvent", file: file, line: line)
            return
        }

        let currentExpectedEvents = InstrumentedExtension.expectedEvents.shallowCopy
        for expectedEvent in currentExpectedEvents {
            let waitResult = expectedEvent.value.await(timeout: FunctionalTestConst.Defaults.WAIT_EVENT_TIMEOUT)
            let expectedCount: Int32 = expectedEvent.value.getInitialCount()
            let receivedCount: Int32 = expectedEvent.value.getInitialCount() - expectedEvent.value.getCurrentCount()
            XCTAssertFalse(waitResult == DispatchTimeoutResult.timedOut, "Timed out waiting for event type \(expectedEvent.key.type) and source \(expectedEvent.key.source), expected \(expectedCount), but received \(receivedCount)", file: (file), line: line)
            XCTAssertEqual(expectedCount, receivedCount, "Expected \(expectedCount) event(s) of type \(expectedEvent.key.type) and source \(expectedEvent.key.source), but received \(receivedCount)", file: (file), line: line)
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

        let currentReceivedEvents = InstrumentedExtension.receivedEvents.shallowCopy
        for receivedEvent in currentReceivedEvents {

            // check if event is expected and it is over the expected count
            if let expectedEvent = InstrumentedExtension.expectedEvents[EventSpec(type: receivedEvent.key.type, source: receivedEvent.key.source)] {
                _ = expectedEvent.await(timeout: FunctionalTestConst.Defaults.WAIT_EVENT_TIMEOUT)
                let expectedCount: Int32 = expectedEvent.getInitialCount()
                let receivedCount: Int32 = expectedEvent.getInitialCount() - expectedEvent.getCurrentCount()
                XCTAssertEqual(expectedCount, receivedCount, "Expected \(expectedCount) events of type \(receivedEvent.key.type) and source \(receivedEvent.key.source), but received \(receivedCount)", file: (file), line: line)
            }
            // check for events that don't have expectations set
            else {
                unexpectedEventsReceivedCount += receivedEvent.value.count
                unexpectedEventsAsString.append("(\(receivedEvent.key.type), \(receivedEvent.key.source), \(receivedEvent.value.count)),")
                print("Received unexpected event with type: \(receivedEvent.key.type) source: \(receivedEvent.key.source)")
            }
        }

        XCTAssertEqual(0, unexpectedEventsReceivedCount, "Received \(unexpectedEventsReceivedCount) unexpected event(s): \(unexpectedEventsAsString)", file: (file), line: line)
    }
    
    /// Sets an expectation for a specific event type and source and how many times the event should be dispatched
    /// - Parameters:
    ///   - type: the event type as a `String`, should not be empty
    ///   - source: the event source as a `String`, should not be empty
    ///   - count: the number of times this event should be dispatched, but default it is set to 1
    /// - See also:
    ///   - assertExpectedEvents(ignoreUnexpectedEvents:)
    func setExpectationEvent(type: String, source: String, expectedCount: Int32 = 1) {
        guard expectedCount > 0 else {
            assertionFailure("Expected event count should be greater than 0")
            return
        }
        guard !type.isEmpty, !source.isEmpty else {
            assertionFailure("Expected event type and source should be non-empty trings")
            return
        }

        InstrumentedExtension.expectedEvents[EventSpec(type: type, source: source)] = CountDownLatch(expectedCount)
    }
    // TODO: create string any codable and compare with event data directly
    func getXDMPayload(_ jsonString: String) -> (expected: AnyCodable, payload: [String: Any])? {
        guard let codable = getAnyCodable(jsonString), let payload = codable.dictionaryValue?["xdm"] as? [String: Any] else {
            XCTFail("TEST ERROR: Unable to decode valid XDM dictionary from input JSON")
            return nil
        }
        return (expected: codable, payload: payload)
    }
    
    func getDataPayload(_ jsonString: String) -> (expected: AnyCodable, payload: [String: Any])? {
        guard let codable = getAnyCodable(jsonString), let payload = codable.dictionaryValue?["data"] as? [String: Any] else {
            XCTFail("TEST ERROR: Unable to decode vaid data dictionary from input JSON")
            return nil
        }
        return (expected: codable, payload: payload)
    }
    
    func getAnyCodable(_ jsonString: String) -> AnyCodable? {
        return try? JSONDecoder().decode(AnyCodable.self, from: jsonString.data(using: .utf8)!)
    }
}


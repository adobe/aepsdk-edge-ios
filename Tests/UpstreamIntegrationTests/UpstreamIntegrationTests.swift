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

/// This test class validates proper intergration with upstream services, specifically Edge Network
class UpstreamIntegrationTests: XCTestCase {
    private var edgeEnvironment: EdgeEnvironment = .prod
    private var edgeLocationHint: EdgeLocationHint?

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
        } else {
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

    // MARK: - Functional test examples
    // MARK: Test request event format
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

        assertEqual(expected: xdm.expected, actual: AnyCodable(AnyCodable.from(dictionary: eventDataDict)))
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

        assertEqual(expected: xdm.expected, actual: AnyCodable(AnyCodable.from(dictionary: eventDataDict)))
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
                 "scope" : "EdgeNetwork21",
                 "hint" : "or2"
               }
             ]
           }
        """#

        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }
        assertContains(expected: expected, actual: actual, mode: .typeMatch)
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
             "scope" : "Target21",
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

        assertContains(expected: expected, actual: actual, alternateModePaths: ["payload[*].scope"], mode: .typeMatch)
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

        assertContains(expected: expected, actual: actual, alternateModePaths: ["payload[*].scope"], mode: .typeMatch)
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
                "id" : "01568806327147093148132339481092735151",
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
                  "time" : "3333-04-21T21:56:52.455Z"
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

        assertContains(expected: expected, actual: actual, alternateModePaths: [
            "meta",
            "query",
            "identityMap.ECID[0].authenticatedState",
            "identityMap.ECID[0].primary",
            "consent[0].standard",
            "consent[0].version",
            "consent[0].value.collect"
        ], mode: .typeMatch)

        assertContains(expected: expected, actual: actual, alternateModePaths: [
            "meta",
            "query",
            "identityMap.ECID[*].authenticatedState",
            "identityMap.ECID[*].primary",
            "consent[*].standard",
            "consent[*].version",
            "consent[*].value.collect"
        ], mode: .typeMatch)

        assertContains(expected: expected, actual: actual)
        assertContains(expected: expected, actual: actual, alternateModePaths: [
            "identityMap.ECID[0].id",
            "consent[0].value.metadata.time"
        ])

        assertContains(expected: expected, actual: actual, alternateModePaths: [
            "identityMap.ECID[*].id",
            "consent[*].value.metadata.time"
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
            guard let payloadArray = data?["payload"] as? [[String: Any]] else {
                XCTFail()
                return
            }
            print()
            let targetHint = payloadArray[0]
            guard let locationHintCorrectValue: [String: Any] = self.convertToJSON(validationJSON), let locationHintPayload = locationHintCorrectValue["payload"] as? [[String: Any]] else {
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
    // TODO: Extract shared utilities so they can be used across functional and integration tests

    func getAnyCodable(_ jsonString: String) -> AnyCodable? {
        return try? JSONDecoder().decode(AnyCodable.self, from: jsonString.data(using: .utf8)!)
    }
}

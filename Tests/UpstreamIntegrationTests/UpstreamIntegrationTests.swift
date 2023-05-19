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

/// Performs validation on intergration with the Edge Network upstream service
class UpstreamIntegrationTests: TestBase {
    private var edgeEnvironment: EdgeEnvironment = .prod
    private var edgeLocationHint: EdgeLocationHint?

    private var networkService: RealNetworkService = RealNetworkService()

    let LOG_SOURCE = "UpstreamIntegrationTests"

    let asyncTimeout: TimeInterval = 10

    // Run before each test case
    override func setUp() {
        ServiceProvider.shared.networkService = networkService

        super.setUp()

        continueAfterFailure = true
        TestBase.debugEnabled = true
        // Extract Edge Network environment level from shell environment; see init for default value
        self.edgeEnvironment = EdgeEnvironment()
        print("Using Edge Network environment: \(edgeEnvironment.rawValue)")

        // Extract Edge location hint from shell environment; see init for default value
        self.edgeLocationHint = EdgeLocationHint()

        let waitForRegistration = CountDownLatch(1)
        MobileCore.setLogLevel(.trace)
        // Set environment file ID for specific Edge Network environment
        setMobileCoreEnvironmentFileID(for: edgeEnvironment)
        MobileCore.registerExtensions([Identity.self, Edge.self], {
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
        resetTestExpectations()
        networkService.reset()
    }

    // MARK: - Upstream integration test cases

    // MARK: 1st launch scenarios
    func testSendEvent_withStandardExperienceEvent_receivesExpectedEventHandles() {
        // Setup
        // Test constructs should always be valid
        let standardNetworkRequest = NetworkRequest(urlString: "https://obumobile5.data.adobedc.net/ee/v1/interact", httpMethod: .post)!
        // Setting expectation allows for both:
        // 1. Validation that the network request was sent out
        // 2. Waiting on a response for the specific network request (with timeout)
        networkService.setExpectationForNetworkRequest(networkRequest: standardNetworkRequest, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        let matchedResponsePost = networkService.getResponsesFor(networkRequest: standardNetworkRequest, timeout: 5)
        XCTAssertEqual(200, matchedResponsePost.first?.responseCode)

        // MARK: Response Event assertions
        // Only validate for the location hint relevant to Edge Network extension
        // NOTE: the key value pair "hint": "stringType" is taking advantage of the flexible
        // JSON comparison system defined in XCTestCase+AnyCodableAsserts where test assertions
        // between JSON values can be based on their data types instead of exact values.
        let expectedJSON = #"""
        {
          "payload": [
            {
              "ttlSeconds" : 1800,
              "scope" : "EdgeNetwork",
              "hint" : "stringType"
            }
          ]
        }
        """#

        let expected = getAnyCodable(expectedJSON)!

        let resultEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: "locationHint:result")
        XCTAssertEqual(1, resultEvents.count)
        guard let locationHintEvent = resultEvents.first else {
            XCTFail("No valid location hint event found")
            return
        }

        assertTypeMatch(expected: expected, actual: getAnyCodableFromEventPayload(event: locationHintEvent), exactMatchPaths: ["payload[*].scope"])
        print(resultEvents)
    }

    // Tests standard sendEvent with both XDM and data, where data is complex - many keys and
    // different value types
    func testSendEvent_withEventXDMAndData_receivesExpectedEventHandles() {
        // Setup
        let standardNetworkRequest = NetworkRequest(urlString: "https://obumobile5.data.adobedc.net/ee/v1/interact", httpMethod: .post)!
        networkService.setExpectationForNetworkRequest(networkRequest: standardNetworkRequest, expectedCount: 1)

        let eventPayloadJSON = #"""
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

        let xdm = getAnyCodableAndPayload(eventPayloadJSON, type: .xdm)!
        let data = getAnyCodableAndPayload(eventPayloadJSON, type: .data)!

        let experienceEvent = ExperienceEvent(xdm: xdm.payload, data: data.payload)

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        let matchedResponse = networkService.getResponsesFor(networkRequest: standardNetworkRequest, timeout: 5)

        XCTAssertEqual(200, matchedResponse.first?.responseCode)

        // MARK: Response Event assertions
        // Only validate for the location hint relevant to Edge Network extension
        let expectedLocationHintJSON = #"""
        {
          "payload": [
            {
              "ttlSeconds" : 1800,
              "scope" : "EdgeNetwork",
              "hint" : "stringType"
            }
          ]
        }
        """#

        assertEdgeResponseEvent(expectedJSON: expectedLocationHintJSON, eventSource: TestConstants.EventSource.LOCATION_HINT_RESULT, exactMatchPaths: ["payload[*].scope"])

        let expectedStateStore1stJSON = #"""
        {
          "payload": [
            {
              "maxAge": 1,
              "key": "stringType",
              "value": "stringType"
            },
            {
              "maxAge": 1,
              "key": "stringType",
              "value": "stringType"
            }
          ]
        }
        """#

        assertEdgeResponseEvent(expectedJSON: expectedStateStore1stJSON, eventSource: TestConstants.EventSource.STATE_STORE)
    }

    // Tests standard sendEvent with complex XDM - many keys and different value types
    func testSendEvent_withEventXDMOnly_receivesExpectedEventHandles() {
        // Setup
        let standardNetworkRequest = NetworkRequest(urlString: "https://obumobile5.data.adobedc.net/ee/v1/interact", httpMethod: .post)!
        networkService.setExpectationForNetworkRequest(networkRequest: standardNetworkRequest, expectedCount: 1)

        let eventPayloadJSON = #"""
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

        let xdm = getAnyCodableAndPayload(eventPayloadJSON, type: .xdm)!

        let experienceEvent = ExperienceEvent(xdm: xdm.payload)

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        let matchedResponse = networkService.getResponsesFor(networkRequest: standardNetworkRequest, timeout: 5)
        XCTAssertEqual(200, matchedResponse.first?.responseCode)

        // MARK: Response Event assertions
        // Only validate for the location hint relevant to Edge Network extension
        let expectedLocationHintJSON = #"""
        {
          "payload": [
            {
              "ttlSeconds" : 1800,
              "scope" : "EdgeNetwork",
              "hint" : "stringType"
            }
          ]
        }
        """#

        assertEdgeResponseEvent(expectedJSON: expectedLocationHintJSON, eventSource: TestConstants.EventSource.LOCATION_HINT_RESULT, exactMatchPaths: ["payload[*].scope"])

        let expectedStateStore1stJSON = #"""
        {
          "payload": [
            {
              "maxAge": 1,
              "key": "stringType",
              "value": "stringType"
            },
            {
              "maxAge": 1,
              "key": "stringType",
              "value": "stringType"
            }
          ]
        }
        """#

        assertEdgeResponseEvent(expectedJSON: expectedStateStore1stJSON, eventSource: TestConstants.EventSource.STATE_STORE)
    }

    // MARK: - Configuration tests
    // Tests standard sendEvent with both XDM and data, where data is complex - many keys and
    // different value types
    func testSendEvent_withSetLocationHint_receivesExpectedEventHandles() {
        // Setup
        let locationHintNetworkRequest = NetworkRequest(urlString: "https://obumobile5.data.adobedc.net/ee/va6/v1/interact", httpMethod: .post)!
        networkService.setExpectationForNetworkRequest(networkRequest: locationHintNetworkRequest, expectedCount: 1)

        Edge.setLocationHint("va6")

        let eventPayloadJSON = #"""
        {
          "xdm": {
            "testString": "xdm"
          },
          "data": {
            "testDataString": "stringValue"
          }
        }
        """#

        let xdm = getAnyCodableAndPayload(eventPayloadJSON, type: .xdm)!
        let data = getAnyCodableAndPayload(eventPayloadJSON, type: .data)!

        let experienceEvent = ExperienceEvent(xdm: xdm.payload, data: data.payload)

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        let matchedResponse = networkService.getResponsesFor(networkRequest: locationHintNetworkRequest, timeout: 5)
        XCTAssertEqual(200, matchedResponse.first?.responseCode)

        // MARK: Response Event assertions
        // Only validate for the location hint relevant to Edge Network extension
        let expectedLocationHintJSON = #"""
        {
          "payload": [
            {
              "ttlSeconds" : 1800,
              "scope" : "EdgeNetwork",
              "hint" : "va6"
            }
          ]
        }
        """#

        assertEdgeResponseEvent(expectedJSON: expectedLocationHintJSON, eventSource: TestConstants.EventSource.LOCATION_HINT_RESULT, exactMatchPaths: ["payload[*].scope", "payload[*].hint"])

        let expectedStateStore1stJSON = #"""
        {
          "payload": [
            {
              "maxAge": 1,
              "key": "stringType",
              "value": "stringType"
            },
            {
              "maxAge": 1,
              "key": "stringType",
              "value": "stringType"
            }
          ]
        }
        """#

        assertEdgeResponseEvent(expectedJSON: expectedStateStore1stJSON, eventSource: TestConstants.EventSource.STATE_STORE)
    }

    // MARK: - Error scenarios

    // Tests that an invalid datastream ID returns the expected error
    func testSendEvent_withInvalidDatastreamID_receivesExpectedError() {
        // Setup
        let standardNetworkRequest = NetworkRequest(urlString: "https://obumobile5.data.adobedc.net/ee/v1/interact", httpMethod: .post)!

        networkService.setExpectationForNetworkRequest(networkRequest: standardNetworkRequest, expectedCount: 1)

        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])
        // Test
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        let matchedResponse = networkService.getResponsesFor(networkRequest: standardNetworkRequest, timeout: 5)
        XCTAssertEqual(400, matchedResponse.first?.responseCode)

        // MARK: Event assertions
        let expectedErrorJSON = #"""
        {
            "status": 400,
            "detail": "stringType",
            "report": {
              "requestId": "stringType"
            },
            "requestEventId": "stringType",
            "title": "Invalid datastream ID",
            "type": "stringType",
            "requestId": "stringType"
          }
        """#

        assertEdgeResponseEvent(expectedJSON: expectedErrorJSON, eventSource: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, exactMatchPaths: ["status", "title"])

    }

    // Tests that an invalid location hint returns the expected error with 0 byte data body
    func testSendEvent_withInvalidLocationHint_receivesExpectedError() {
        // Setup
        let invalidNetworkRequest = NetworkRequest(urlString: "https://obumobile5.data.adobedc.net/ee/invalid/v1/interact", httpMethod: .post)!
        networkService.setExpectationForNetworkRequest(networkRequest: invalidNetworkRequest, expectedCount: 1)

        Edge.setLocationHint("invalid")

        // Test
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        guard let matchedResponse = networkService.getResponsesFor(networkRequest: invalidNetworkRequest, timeout: 5).first else {
            XCTFail("No valid response found for request: \(invalidNetworkRequest)")
            return
        }
        XCTAssertEqual(404, matchedResponse.responseCode)
        XCTAssertEqual(0, matchedResponse.data?.count)
    }

    // MARK: - Test helper methods
    private func setMobileCoreEnvironmentFileID(for edgeEnvironment: EdgeEnvironment) {
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
}

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
    func testSendEvent_withStandardExperienceEventTwice_receivesExpectedEventHandles() {
        // Setup
        // Test constructs should always be valid
        let interactNetworkRequest = NetworkRequest(urlString: createURLWith(locationHint: edgeLocationHint), httpMethod: .post)!
        // Setting expectation allows for both:
        // 1. Validation that the network request was sent out
        // 2. Waiting on a response for the specific network request (with timeout)
        networkService.setExpectationForNetworkRequest(networkRequest: interactNetworkRequest, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        let receivedResponses = networkService.getResponsesFor(networkRequest: interactNetworkRequest, timeout: 5)
        XCTAssertEqual(1, receivedResponses.count)
        XCTAssertEqual(200, receivedResponses.first?.responseCode)

        // MARK: Response Event assertions
        // Only validate for the location hint relevant to Edge Network extension
        // NOTE: when using `assertTypeMatch`, key value pairs take advantage of the flexible
        // JSON comparison system defined in XCTestCase+AnyCodableAsserts where test assertions
        // between JSON values can be based on their data types instead of exact values.
        // See the assertTypeMatch -> exactMatchPaths arg to see which key paths will use exact matching for values
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
       
        assertEdgeResponse(expectedType: TestConstants.EventSource.LOCATION_HINT_RESULT, expectedPayload: expectedLocationHintJSON, exactMatchPaths: ["payload[*].scope"])
        
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
        
        assertEdgeResponse(expectedType: TestConstants.EventSource.STATE_STORE, expectedPayload: expectedStateStore1stJSON)
        
        // MARK: 2nd send event
        resetTestExpectations()
        Edge.sendEvent(experienceEvent: experienceEvent)
        
        // Assert location hint response is correct
        assertEdgeResponse(expectedType: TestConstants.EventSource.LOCATION_HINT_RESULT, expectedPayload: expectedLocationHintJSON, exactMatchPaths: ["payload[*].scope"])

        let expectedStateStore2ndJSON = #"""
        {
          "payload": [
            {
              "maxAge": 1,
              "key": "kndctr_972C898555E9F7BC7F000101_AdobeOrg_cluster",
              "value": "stringType"
            }
          ]
        }
        """#
        
        // Assert state store response is correct
        assertEdgeResponse(expectedType: TestConstants.EventSource.STATE_STORE, expectedPayload: expectedStateStore2ndJSON, exactMatchPaths: ["payload[*].key"])
    }

    // Tests standard sendEvent with both XDM and data, where data is complex - many keys and
    // different value types
    func testSendEvent_withEventXDMAndData_receivesExpectedEventHandles() {
        // Setup
        let interactNetworkRequest = NetworkRequest(urlString: createURLWith(locationHint: edgeLocationHint), httpMethod: .post)!
        networkService.setExpectationForNetworkRequest(networkRequest: interactNetworkRequest, expectedCount: 1)

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
        let matchedResponse = networkService.getResponsesFor(networkRequest: interactNetworkRequest, timeout: 5)

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

        assertEdgeResponse(expectedType: TestConstants.EventSource.LOCATION_HINT_RESULT, expectedPayload: expectedLocationHintJSON, exactMatchPaths: ["payload[*].scope"])

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

        assertEdgeResponse(expectedType: TestConstants.EventSource.STATE_STORE, expectedPayload: expectedStateStore1stJSON)
    }

    // Tests standard sendEvent with complex XDM - many keys and different value types
    func testSendEvent_withEventXDMOnly_receivesExpectedEventHandles() {
        // Setup
        let interactNetworkRequest = NetworkRequest(urlString: createURLWith(locationHint: edgeLocationHint), httpMethod: .post)!
        networkService.setExpectationForNetworkRequest(networkRequest: interactNetworkRequest, expectedCount: 1)

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
        let matchedResponse = networkService.getResponsesFor(networkRequest: interactNetworkRequest, timeout: 5)
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

        assertEdgeResponse(expectedType: TestConstants.EventSource.LOCATION_HINT_RESULT, expectedPayload: expectedLocationHintJSON, exactMatchPaths: ["payload[*].scope"])

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

        assertEdgeResponse(expectedType: TestConstants.EventSource.STATE_STORE, expectedPayload: expectedStateStore1stJSON)
    }

    // MARK: - Configuration tests
    // Tests standard sendEvent with preset location hint
    func testSendEvent_withSetLocationHint_receivesExpectedEventHandles() {
        // Setup
        let locationHint = "va6"
        let locationHintNetworkRequest = NetworkRequest(urlString: createURLWith(locationHint: locationHint), httpMethod: .post)!
        networkService.setExpectationForNetworkRequest(networkRequest: locationHintNetworkRequest, expectedCount: 1)

        Edge.setLocationHint(locationHint)

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
              "hint" : "\#(locationHint)"
            }
          ]
        }
        """#

        assertEdgeResponse(expectedType: TestConstants.EventSource.LOCATION_HINT_RESULT, expectedPayload: expectedLocationHintJSON, exactMatchPaths: ["payload[*].scope", "payload[*].hint"])

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

        assertEdgeResponse(expectedType: TestConstants.EventSource.STATE_STORE, expectedPayload: expectedStateStore1stJSON)
    }

    // MARK: - Error scenarios

    // Tests that an invalid datastream ID returns the expected error
    func testSendEvent_withInvalidDatastreamID_receivesExpectedError() {
        // Setup
        let interactNetworkRequest = NetworkRequest(urlString: createURLWith(locationHint: edgeLocationHint), httpMethod: .post)!

        networkService.setExpectationForNetworkRequest(networkRequest: interactNetworkRequest, expectedCount: 1)

        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])
        // Test
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        let matchedResponse = networkService.getResponsesFor(networkRequest: interactNetworkRequest, timeout: 5)
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

        assertEdgeResponseError(expectedErrorDetails: expectedErrorJSON, exactMatchPaths: ["status", "title"])
    }

    // Tests that an invalid location hint returns the expected error with 0 byte data body
    func testSendEvent_withInvalidLocationHint_receivesExpectedError() {
        // Setup
        let invalidNetworkRequest = NetworkRequest(urlString: createURLWith(locationHint: "invalid"), httpMethod: .post)!
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
    
    /// Creates a valid interact URL using the provided location hint. If location hint is invalid, returns default URL with no location hint.
    /// - Parameters:
    ///    - locationHint: The `EdgeLocationHint`'s raw value to use in the URL
    /// - Returns: The interact URL with location hint applied, default URL if location hint is invalid
    private func createURLWith(locationHint: EdgeLocationHint?) -> String {
        guard let locationHint = locationHint else {
            return "https://obumobile5.data.adobedc.net/ee/v1/interact"
        }
        return createURLWith(locationHint: locationHint.rawValue)
    }
    
    /// Creates a valid interact URL using the provided location hint.
    /// - Parameters:
    ///    - locationHint: The location hint String to use in the URL
    /// - Returns: The interact URL with location hint applied
    private func createURLWith(locationHint: String) -> String {
        return "https://obumobile5.data.adobedc.net/ee/\(locationHint)/v1/interact"
    }
    
    private func assertEdgeResponse(expectedType: String, expectedPayload: String, exactMatchPaths: [String] = [], file: StaticString = #file, line: UInt = #line) {
        guard let expected = getAnyCodable(expectedPayload) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.", file: file, line: line)
            return
        }
        
        let responseHandleEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: expectedType)
        
        XCTAssertEqual(1, responseHandleEvents.count, file: file, line: line)
        
        guard let responseHandleEvent = responseHandleEvents.first else {
            XCTFail("No valid response handle event found", file: file, line: line)
            return
        }
        
        assertTypeMatch(expected: expected, actual: getAnyCodableFromEventPayload(event: responseHandleEvent), exactMatchPaths: exactMatchPaths, file: file, line: line)
    }
    
    private func assertEdgeResponseError(expectedErrorDetails: String, exactMatchPaths: [String] = [], file: StaticString = #file, line: UInt = #line) {
        assertEdgeResponse(expectedType: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedPayload: expectedErrorDetails, file: file, line: line)
    }
}

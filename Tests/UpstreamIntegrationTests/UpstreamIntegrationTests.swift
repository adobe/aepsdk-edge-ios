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
class UpstreamIntegrationTests: TestBase {
    private var edgeEnvironment: EdgeEnvironment = .prod
    private var edgeLocationHint: EdgeLocationHint?

    let LOG_SOURCE = "SampleFunctionalTests"

    let asyncTimeout: TimeInterval = 10

    override class func setUp() {
        TestBase.mockNetworkService = false
        super.setUp()
    }
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = true
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
        resetTestExpectations()
    }

    // datastream ID - is edge.configId from the configuration - this is already tested by sendEvent 
    // MARK: - Upstream integration test cases
    // MARK: 1st launch scenarios
    func testSendEvent_withStandardExperienceEvent_receivesExpectedEventHandles() {
        // Setup
        
        // Setting expectation allows for both:
        // 1. Validation that the network request was sent out
        // 2. Waiting on a response for the specific network request (with timeout)
        setExpectationNetworkRequest(url: "https://obumobile5.data.adobedc.net/ee/v1/interact", httpMethod: HttpMethod.post, expectedCount: 1)
        
        // Test
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        let matchedResponse = getResponsesForRequestWith(url: "https://obumobile5.data.adobedc.net/ee/v1/interact", httpMethod: .post, timeout: 5)
        XCTAssertEqual(200, matchedResponse.first?.responseCode)
        
        // MARK: Response Event assertions
        // MARK: 1st send event
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
        
        // MARK: 2nd send event
        resetTestExpectations()
        Edge.sendEvent(experienceEvent: experienceEvent)
        
        // Assert location hint response is correct
        assertEdgeResponseEvent(expectedJSON: expectedLocationHintJSON, eventSource: TestConstants.EventSource.LOCATION_HINT_RESULT, exactMatchPaths: ["payload[*].scope"])
        // TODO: strong validation against org ID portion of key
        let expectedStateStore2ndJSON = #"""
        {
          "payload": [
            {
              "maxAge": 1,
              "key": "stringType",
              "value": "stringType"
            }
          ]
        }
        """#
        
        // Assert state store response is correct
        assertEdgeResponseEvent(expectedJSON: expectedStateStore2ndJSON, eventSource: TestConstants.EventSource.STATE_STORE)
    }
    
    // Tests standard sendEvent with both XDM and data, where data is complex - many keys and
    // different value types
    func testSendEvent_withEventXDMAndData_receivesExpectedEventHandles() {
        // Setup
        setExpectationNetworkRequest(url: "https://obumobile5.data.adobedc.net/ee/v1/interact", httpMethod: HttpMethod.post, expectedCount: 1)
        
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
        
        // Test constructs should always be valid
        let xdm = getAnyCodableAndPayload(eventPayloadJSON, type: .xdm)!
        let data = getAnyCodableAndPayload(eventPayloadJSON, type: .data)!
        
        let experienceEvent = ExperienceEvent(xdm: xdm.payload, data: data.payload)
        
        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        let matchedResponse = getResponsesForRequestWith(url: "https://obumobile5.data.adobedc.net/ee/v1/interact", httpMethod: .post, timeout: 5)
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
        setExpectationNetworkRequest(url: "https://obumobile5.data.adobedc.net/ee/v1/interact", httpMethod: HttpMethod.post, expectedCount: 1)
        
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
        
        // Test constructs should always be valid
        let xdm = getAnyCodableAndPayload(eventPayloadJSON, type: .xdm)!
        
        let experienceEvent = ExperienceEvent(xdm: xdm.payload)
        
        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        let matchedResponse = getResponsesForRequestWith(url: "https://obumobile5.data.adobedc.net/ee/v1/interact", httpMethod: .post, timeout: 5)
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
        setExpectationNetworkRequest(url: "https://obumobile5.data.adobedc.net/ee/va6/v1/interact", httpMethod: HttpMethod.post, expectedCount: 1)
        
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
        
        // Test constructs should always be valid
        let xdm = getAnyCodableAndPayload(eventPayloadJSON, type: .xdm)!
        let data = getAnyCodableAndPayload(eventPayloadJSON, type: .data)!
        
        let experienceEvent = ExperienceEvent(xdm: xdm.payload, data: data.payload)
        
        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        let matchedResponse = getResponsesForRequestWith(url: "https://obumobile5.data.adobedc.net/ee/va6/v1/interact", httpMethod: .post, timeout: 5)
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
        let validRequest = NetworkRequest(urlString: "https://obumobile5.data.adobedc.net/ee/v1/interact", httpMethod: .post)!
        
        setExpectationNetworkRequest(url: validRequest.url.absoluteString, httpMethod: validRequest.httpMethod, expectedCount: 1)
        
        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])
        // Test
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        let matchedResponse = getResponsesForRequestWith(url: validRequest.url.absoluteString, httpMethod: validRequest.httpMethod, timeout: 5)
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
        let invalidRequestSpec = NetworkRequestSpec(url: "https://obumobile5.data.adobedc.net/ee/invalid/v1/interact", httpMethod: .post)
        setExpectationNetworkRequest(spec: invalidRequestSpec, expectedCount: 1)
        
        Edge.setLocationHint("invalid")
        
        // Test
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        guard let matchedResponse = getResponsesForRequestWith(spec: invalidRequestSpec, timeout: 5).first else {
            XCTFail("No valid response found for request: \(invalidRequestSpec)")
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
    
    // MARK: Assertion helpers
    private func assertEdgeResponseEvent(expectedJSON: String, eventSource: String, exactMatchPaths: [String] = [], file: StaticString = #file, line: UInt = #line) {
        guard let expected = getAnyCodable(expectedJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }
        
        let stateStoreEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: eventSource)
        
        XCTAssertEqual(1, stateStoreEvents.count, file: file, line: line)
        
        guard let stateStoreEvent = stateStoreEvents.first else {
            XCTFail("No valid location hint event found")
            return
        }
        
        assertTypeMatch(expected: expected, actual: getAnyCodableFromEventPayload(event: stateStoreEvent), exactMatchPaths: exactMatchPaths, file: file, line: line)
    }
}

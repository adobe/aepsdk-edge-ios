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
//    private static let networkService: ServerTestNetworkService = ServerTestNetworkService()
    private var networkService: RealNetworkService = RealNetworkService()

    let LOG_SOURCE = "UpstreamIntegrationTests"

    let asyncTimeout: TimeInterval = 10

    // Run once per test suite
    override class func setUp() {
        super.setUp()

        TestBase.debugEnabled = true

    }

    // Run before each test case
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

    // datastream ID - is edge.configId from the configuration - this is already tested by sendEvent 
    // MARK: - Upstream integration test cases
    // MARK: 1st launch scenarios
    func testSendEvent_withStandardExperienceEvent_receivesExpectedEventHandles() {
        // Setup

        // Setting expectation allows for both:
        // 1. Validation that the network request was sent out
        // 2. Waiting on a response for the specific network request (with timeout)
        networkService.setExpectationForNetworkRequest(url: "https://obumobile5.data.adobedc.net/ee/v1/interact", httpMethod: HttpMethod.post, expectedCount: 1)

        // Test
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // MARK: Network response assertions
        let networkRequest = NetworkRequest(urlString: "https://obumobile5.data.adobedc.net/ee/v1/interact", httpMethod: .post)!
        let matchedResponsePost = networkService.getResponsesFor(networkRequest: networkRequest, timeout: 5)
        XCTAssertEqual(200, matchedResponsePost.first?.responseCode)

        // MARK: Response Event assertions
        // MARK: 1st send event
        // Only validate for the location hint relevant to Edge Network extension
        let expectedLocationHintJSON = #"""
        {
          "payload": [
            {
              "ttlSeconds" : 1800,
              "scope" : "EdgeNetwork",
              "hint" : "or2"
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
    
    // MARK: - Error scenarios
    
    // error scenarios
    // 1. invalid datastream id
    // 2. invalid location hint set manually
    
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
        let matchedResponse = getResponsesForRequestWith(spec: invalidRequestSpec, timeout: 5)
        XCTAssertEqual(404, matchedResponse.first?.responseCode)
        // TODO: investigate the actual network response
        // check for error response message and assert against that payload
        let expectedErrorJSON = #"""
        {
          "title" : "Unexpected Error",
          "detail" : "",
          "requestEventId" : "stringType",
          "requestId" : "stringType"
        }
        """#
        assertEdgeResponseEvent(expectedJSON: expectedErrorJSON, eventSource: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, exactMatchPaths: ["title", "detail"])
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

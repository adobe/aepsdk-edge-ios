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
        let matchedResponsePost = getNetworkResponseForRequestWith(url: "https://obumobile5.data.adobedc.net/ee/v1/interact", httpMethod: .post, timeout: 5)
        XCTAssertEqual(200, matchedResponsePost?.responseCode)
        
        // MARK: Response Event assertions
        // Only validate for the location hint relevant to Edge Network extension
        let expectedJSON = #"""
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
        
        guard let expected = getAnyCodable(expectedJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }
        
        let resultEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: "locationHint:result")
        XCTAssertEqual(1, resultEvents.count) // Do we want strict count validation for number of locationHint:result responses?
        guard let locationHintEvent = resultEvents.first else {
            XCTFail("No valid location hint event found")
            return
        }
        
        assertTypeMatch(expected: expected, actual: getAnyCodableFromEventPayload(event: locationHintEvent), exactMatchPaths: ["payload[*].scope"])
        print(resultEvents)
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

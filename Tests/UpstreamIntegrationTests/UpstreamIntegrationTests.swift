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

/// Performs validation on integration with the Edge Network upstream service
class UpstreamIntegrationTests: TestBase {
    private var edgeEnvironment: EdgeEnvironment = getEdgeEnvironment()
    private var edgeLocationHint: EdgeLocationHint? = getLocationHint()

    private var networkService: RealNetworkService = RealNetworkService()

    let LOG_SOURCE = "UpstreamIntegrationTests"

    // Run before each test case
    override func setUp() {
        ServiceProvider.shared.networkService = networkService

        super.setUp()

        continueAfterFailure = true
        TestBase.debugEnabled = true

        let waitForRegistration = CountDownLatch(1)
        MobileCore.setLogLevel(.trace)

        // Set environment file ID for specific Edge Network environment
        MobileCore.configureWith(appId: getTagsEnvironmentFileId(for: edgeEnvironment))

        MobileCore.registerExtensions([Identity.self, Edge.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))

        // Set Edge location hint value if one is set for the test target
        setInitialLocationHint(edgeLocationHint?.rawValue)

        resetTestExpectations()
        networkService.reset()
    }

    // MARK: - Upstream integration test cases

    /// Tests that a standard sendEvent receives a single network response with HTTP code 200
    func testSendEvent_receivesExpectedNetworkResponse() {
        // Setup
        // Note: test constructs should always be valid
        let interactNetworkRequest = NetworkRequest(urlString: createInteractUrl(with: edgeLocationHint?.rawValue), httpMethod: .post)!
        // Setting expectation allows for both:
        // 1. Validation that the network request was sent out
        // 2. Waiting on a response for the specific network request (with timeout)
        networkService.setExpectation(for: interactNetworkRequest, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]])

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // Network response assertions
        networkService.assertAllNetworkRequestExpectations()
        let matchingResponses = networkService.getResponses(for: interactNetworkRequest)

        XCTAssertEqual(1, matchingResponses?.count)
        XCTAssertEqual(200, matchingResponses?.first?.responseCode)
    }

    /// Tests that a standard sendEvent receives a single network response with HTTP code 200
    func testSendEvent_whenComplexEvent_receivesExpectedNetworkResponse() {
        // Setup
        let interactNetworkRequest = NetworkRequest(urlString: createInteractUrl(with: edgeLocationHint?.rawValue), httpMethod: .post)!
        networkService.setExpectation(for: interactNetworkRequest, expectedCount: 1)

        let xdmJSON = #"""
        {
            "testString": "xdm"
        }
        """#

        let dataJSON = #"""
          {
            "testDataString": "stringValue",
            "testDataInt": 101,
            "testDataBool": true,
            "testDataDouble": 13.66,
            "testDataArray": ["arrayElem1", 2, true],
            "testDataDictionary": {
              "key": "val"
            }
          }
        """#

        let xdm = getAnyCodable(xdmJSON)!.dictionaryValue!
        let data = getAnyCodable(dataJSON)!.dictionaryValue!

        let experienceEvent = ExperienceEvent(xdm: xdm, data: data)

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // Network response assertions
        networkService.assertAllNetworkRequestExpectations()
        let matchingResponses = networkService.getResponses(for: interactNetworkRequest)

        XCTAssertEqual(1, matchingResponses?.count)
        XCTAssertEqual(200, matchingResponses?.first?.responseCode)
    }

    /// Tests that a standard sendEvent () receives a single network response with HTTP code 200
    func testSendEvent_whenComplexXDMEvent_receivesExpectedNetworkResponse() {
        // Setup
        let interactNetworkRequest = NetworkRequest(urlString: createInteractUrl(with: edgeLocationHint?.rawValue), httpMethod: .post)!
        networkService.setExpectation(for: interactNetworkRequest, expectedCount: 1)

        let xdmJSON = #"""
          {
            "testString": "xdm",
            "testInt": 10,
            "testBool": false,
            "testDouble": 12.89,
            "testArray": ["arrayElem1", 2, true],
            "testDictionary": {
              "key": "val"
            }
          }
        """#

        let xdm = getAnyCodable(xdmJSON)!.dictionaryValue!

        let experienceEvent = ExperienceEvent(xdm: xdm)

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // Network response assertions
        networkService.assertAllNetworkRequestExpectations()
        let matchingResponses = networkService.getResponses(for: interactNetworkRequest)

        XCTAssertEqual(1, matchingResponses?.count)
        XCTAssertEqual(200, matchingResponses?.first?.responseCode)
    }

    /// Tests that a standard sendEvent receives the expected event handles
    func testSendEvent_receivesExpectedEventHandles() {
        // Setup
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.LOCATION_HINT_RESULT, expectedCount: 1)
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.STATE_STORE, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]])

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        assertExpectedEvents(ignoreUnexpectedEvents: true)
    }

    /// Tests that a standard sendEvent receives the expected event handles
    func testSendEvent_doesNotReceivesErrorEvent() {
        // Setup
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.LOCATION_HINT_RESULT, expectedCount: 1)
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.STATE_STORE, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]])

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        assertExpectedEvents(ignoreUnexpectedEvents: true)

        let errorEvents = getEdgeEventHandles(expectedHandleType: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(0, errorEvents.count)
    }

    /// Tests that a standard sendEvent with no prior location hint value set receives the expected location hint event handle.
    /// That is, checks for a string type location hint
    func testSendEvent_with_NO_priorLocationHint_receivesExpectedLocationHintEventHandle() {
        // Setup
        // Clear any existing location hint
        Edge.setLocationHint(nil)

        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.LOCATION_HINT_RESULT, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]])

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        let expectedLocationHintJSON = #"""
        {
          "payload": [
            {
              "ttlSeconds" : 123,
              "scope" : "EdgeNetwork",
              "hint" : "stringType"
            }
          ]
        }
        """#

        // See testSendEvent_receivesExpectedEventHandles for existence validation
        let locationHintResult = getEdgeEventHandles(expectedHandleType: TestConstants.EventSource.LOCATION_HINT_RESULT).first!

        assertTypeMatch(expected: getAnyCodable(expectedLocationHintJSON)!,
                        actual: getAnyCodable(locationHintResult),
                        exactMatchPaths: ["payload[*].scope"])
    }

    /// Tests that a standard sendEvent WITH prior location hint value set receives the expected location hint event handle.
    /// That is, checks for consistency between prior location hint value and received location hint result
    func testSendEvent_withPriorLocationHint_receivesExpectedLocationHintEventHandle() {
        // Setup
        // Uses all the valid location hint cases in random order to prevent order dependent edge cases slipping through
        for locationHint in (EdgeLocationHint.allCases).map({ $0.rawValue }).shuffled() {
            Edge.setLocationHint(locationHint)

            expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.LOCATION_HINT_RESULT, expectedCount: 1)

            let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]])

            // Test
            Edge.sendEvent(experienceEvent: experienceEvent)

            // Verify
            let expectedLocationHintJSON = #"""
            {
              "payload": [
                {
                  "ttlSeconds" : 123,
                  "scope" : "EdgeNetwork",
                  "hint" : "\#(locationHint)"
                }
              ]
            }
            """#

            let locationHintResult = getEdgeEventHandles(expectedHandleType: TestConstants.EventSource.LOCATION_HINT_RESULT).first!

            assertTypeMatch(expected: getAnyCodable(expectedLocationHintJSON)!,
                            actual: getAnyCodable(locationHintResult),
                            exactMatchPaths: ["payload[*].scope", "payload[*].hint"])

            resetTestExpectations()
            networkService.reset()
        }
    }

    /// Tests that a standard sendEvent with no prior state receives the expected state store event handle.
    func testSendEvent_with_NO_priorState_receivesExpectedStateStoreEventHandle() {
        // Setup
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.STATE_STORE, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]])

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        let expectedStateStoreJSON = #"""
        {
          "payload": [
            {
              "maxAge": 123,
              "key": "kndctr_972C898555E9F7BC7F000101_AdobeOrg_cluster",
              "value": "stringType"
            },
            {
              "maxAge": 123,
              "key": "kndctr_972C898555E9F7BC7F000101_AdobeOrg_identity",
              "value": "stringType"
            }
          ]
        }
        """#

        // See testSendEvent_receivesExpectedEventHandles for existence validation
        let stateStoreEvent = getEdgeEventHandles(expectedHandleType: TestConstants.EventSource.STATE_STORE).last!

        // Exact match used here to strictly validate `payload` array element count == 2
        assertExactMatch(expected: getAnyCodable(expectedStateStoreJSON)!,
                        actual: getAnyCodable(stateStoreEvent),
                        typeMatchPaths: ["payload[0].maxAge", "payload[0].value", "payload[1].maxAge", "payload[1].value"])
    }

    /// Tests that a standard sendEvent with prior state receives the expected state store event handle.
    func testSendEvent_withPriorState_receivesExpectedStateStoreEventHandle() {
        // Setup
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.STATE_STORE, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]])

        Edge.sendEvent(experienceEvent: experienceEvent)

        // Allows waiting for expected responses before clearing expectations
        assertExpectedEvents(ignoreUnexpectedEvents: true, timeout: 5)

        resetTestExpectations()
        networkService.reset()

        for locationHint in (EdgeLocationHint.allCases).map({ $0.rawValue }).shuffled() {
            Edge.setLocationHint(locationHint)

            expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.STATE_STORE, expectedCount: 1)

            // Test
            Edge.sendEvent(experienceEvent: experienceEvent)

            // Verify
            let expectedStateStoreJSON = #"""
            {
              "payload": [
                {
                  "maxAge": 123,
                  "key": "kndctr_972C898555E9F7BC7F000101_AdobeOrg_cluster",
                  "value": "\#(locationHint)"
                }
              ]
            }
            """#

            // See testSendEvent_receivesExpectedEventHandles for existence validation
            let stateStoreEvent = getEdgeEventHandles(expectedHandleType: TestConstants.EventSource.STATE_STORE).last!

            // Exact match used here to strictly validate `payload` array element count == 2
            assertExactMatch(expected: getAnyCodable(expectedStateStoreJSON)!,
                            actual: getAnyCodable(stateStoreEvent),
                            typeMatchPaths: ["payload[0].maxAge"])

            resetTestExpectations()
            networkService.reset()
        }
    }

    // MARK: 2nd event tests
    func testSendEventx2_receivesExpectedNetworkResponse() {
        // Setup
        // These expectations are used as a barrier for the event processing to complete
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.LOCATION_HINT_RESULT)

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])

        Edge.sendEvent(experienceEvent: experienceEvent)

        // Extract location hint from Edge Network location hint response event
        guard let locationHintResult = getLastLocationHintResultValue() else {
            XCTFail("Unable to extract valid location hint from location hint result event handle.")
            return
        }

        // If there is an initial location hint value, check consistency
        if edgeLocationHint != nil {
            XCTAssertEqual(edgeLocationHint?.rawValue, locationHintResult)
        }

        // Wait on all expectations to finish processing before clearing expectations
        assertExpectedEvents(ignoreUnexpectedEvents: true)

        // Reset all test expectations
        networkService.reset()
        resetTestExpectations()

        // Set actual testing expectations
        // If test suite level location hint is not set, uses the value extracted from location hint result
        let locationHintNetworkRequest = NetworkRequest(urlString: createInteractUrl(with: locationHintResult), httpMethod: .post)!
        networkService.setExpectation(for: locationHintNetworkRequest, expectedCount: 1)

        // Test
        // 2nd event
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // Network response assertions
        networkService.assertAllNetworkRequestExpectations()
        let matchingResponses = networkService.getResponses(for: locationHintNetworkRequest)

        XCTAssertEqual(1, matchingResponses?.count)
        XCTAssertEqual(200, matchingResponses?.first?.responseCode)
    }

    func testSendEventx2_receivesExpectedEventHandles() {
        // Setup
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.LOCATION_HINT_RESULT, expectedCount: 2)
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.STATE_STORE, expectedCount: 2)

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        assertExpectedEvents(ignoreUnexpectedEvents: true, timeout: 10)
    }

    func testSendEventx2_doesNotReceivesErrorEvent() {
        // Setup
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.LOCATION_HINT_RESULT, expectedCount: 2)
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.STATE_STORE, expectedCount: 2)

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]])

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        assertExpectedEvents(ignoreUnexpectedEvents: true)

        let errorEvents = getEdgeEventHandles(expectedHandleType: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(0, errorEvents.count)
    }

    func testSendEventx2_receivesExpectedLocationHintEventHandle() {
        // Setup
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.LOCATION_HINT_RESULT)

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])

        Edge.sendEvent(experienceEvent: experienceEvent)

        // Extract location hint from Edge Network location hint response event
        guard let locationHintResult = getLastLocationHintResultValue() else {
            XCTFail("Unable to extract valid location hint from location hint result event handle.")
            return
        }

        // Reset all test expectations
        networkService.reset()
        resetTestExpectations()

        // Set actual testing expectations
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.LOCATION_HINT_RESULT, expectedCount: 1)

        // Test
        // 2nd event
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify

        // If there is an initial location hint value, check consistency
        if edgeLocationHint != nil {
            XCTAssertEqual(edgeLocationHint?.rawValue, locationHintResult)
        }

        // Verify location hint consistency between 1st and 2nd event handles
        let expectedLocationHintJSON = #"""
        {
          "payload": [
            {
              "ttlSeconds" : 123,
              "scope" : "EdgeNetwork",
              "hint" : "\#(locationHintResult)"
            }
          ]
        }
        """#

        let locationHintResultEvent = getEdgeEventHandles(expectedHandleType: TestConstants.EventSource.LOCATION_HINT_RESULT).first!

        assertTypeMatch(expected: getAnyCodable(expectedLocationHintJSON)!,
                         actual: getAnyCodable(locationHintResultEvent),
                         exactMatchPaths: ["payload[*].scope", "payload[*].hint"])
    }

    // MARK: - Error scenarios

    // Tests that an invalid datastream ID returns the expected error
    func testSendEvent_withInvalidDatastreamID_receivesExpectedError() {
        // Setup
        let interactNetworkRequest = NetworkRequest(urlString: createInteractUrl(with: edgeLocationHint?.rawValue), httpMethod: .post)!

        networkService.setExpectation(for: interactNetworkRequest, expectedCount: 1)
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1)

        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // Network response assertions
        networkService.assertAllNetworkRequestExpectations()
        let matchingResponses = networkService.getResponses(for: interactNetworkRequest)

        XCTAssertEqual(1, matchingResponses?.count)
        XCTAssertEqual(400, matchingResponses?.first?.responseCode)

        // Event assertions
        let expectedErrorJSON = #"""
        {
            "status": 400,
            "detail": "stringType",
            "report": {
              "requestId": "stringType"
            },
            "requestEventId": "stringType",
            "title": "Invalid datastream ID",
            "type": "https://ns.adobe.com/aep/errors/EXEG-0003-400",
            "requestId": "stringType"
          }
        """#

        let errorEvents = getEdgeResponseErrors()

        XCTAssertEqual(1, errorEvents.count)

        guard let errorEvent = errorEvents.first else { return }
        assertTypeMatch(expected: getAnyCodable(expectedErrorJSON)!,
                        actual: getAnyCodable(errorEvent),
                        exactMatchPaths: ["status", "title", "type"])
    }

    // Tests that an invalid location hint returns the expected error with 0 byte data body
    func testSendEvent_withInvalidLocationHint_receivesExpectedError() {
        // Setup
        let invalidNetworkRequest = NetworkRequest(urlString: createInteractUrl(with: "invalid"), httpMethod: .post)!

        networkService.setExpectation(for: invalidNetworkRequest, expectedCount: 1)
        expectEdgeEventHandle(expectedHandleType: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1)

        Edge.setLocationHint("invalid")

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // Network response assertions
        networkService.assertAllNetworkRequestExpectations()
        let matchingResponses = networkService.getResponses(for: invalidNetworkRequest)

        XCTAssertEqual(1, matchingResponses?.count)
        XCTAssertEqual(404, matchingResponses?.first?.responseCode)
        XCTAssertEqual(0, matchingResponses?.first?.data?.count)

        // Error event assertions
        assertExpectedEvents(ignoreUnexpectedEvents: true)
    }
}

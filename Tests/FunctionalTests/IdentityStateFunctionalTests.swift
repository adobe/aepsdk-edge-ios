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

import AEPCore
import AEPEdge
import AEPServices
import AEPTestUtils
import XCTest

/// Functional test suite for tests which require no Identity shared state at startup to simulate a missing or pending state.
class IdentityStateFunctionalTests: TestBase, AnyCodableAsserts {
    private let TIMEOUT_SEC: TimeInterval = FunctionalTestConstants.Defaults.TIMEOUT_SEC
    private let exEdgeInteractUrl = URL(string: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR)! // swiftlint:disable:this force_unwrapping

    private let mockNetworkService: MockNetworkService = MockNetworkService()

    override func setUp() {
        ServiceProvider.shared.networkService = mockNetworkService

        super.setUp()

        continueAfterFailure = false // fail so nil checks stop execution
        loggingEnabled = false

        // config state and 2 event hub states (Edge, TestableEdgeInternal, FakeIdentityExtension and InstrumentedExtension registered in TestBase)
        setExpectationEvent(type: TestConstants.EventType.HUB, source: TestConstants.EventSource.SHARED_STATE, expectedCount: 3)

        // expectations for update config request&response events
        setExpectationEvent(type: TestConstants.EventType.CONFIGURATION, source: TestConstants.EventSource.REQUEST_CONTENT, expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.CONFIGURATION, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)

        // wait for async registration because the EventHub is already started in TestBase
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([TestableEdge.self, FakeIdentityExtension.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: TIMEOUT_SEC))
        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
        mockNetworkService.reset()
    }

    // Runs after each test case
    override func tearDown() {
        super.tearDown()

        mockNetworkService.reset()
    }

    func testSendEvent_withPendingIdentityState_noRequestSent() {
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["test1": "xdm"], data: nil))

        let requests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertTrue(requests.isEmpty)
    }

    func testSendEvent_withPendingIdentityState_thenValidIdentityState_requestSentAfterChange() {
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["test1": "xdm"], data: nil))

        var requests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertTrue(requests.isEmpty) // no network request sent yet

        guard let responseBody = "{\"test\": \"json\"}".data(using: .utf8) else {
            XCTFail("Failed to convert json to data")
            return
        }
        let httpConnection: HttpConnection = HttpConnection(data: responseBody,
                                                            response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: httpConnection)

        // Once the shared state is set, the Edge Extension is expected to reprocess the original
        // Send Event request once the Hub Shared State event is received.
        guard let identityMapData = """
                {
                  "identityMap" : {
                    "ECID" : [
                      {
                        "authenticationState" : "ambiguous",
                        "id" : "1234",
                        "primary" : false
                      }
                    ]
                  }
                }
        """.data(using: .utf8) else {
            XCTFail("Failed to convert json string to data")
            return
        }
        let identityMap = try? JSONSerialization.jsonObject(with: identityMapData, options: []) as? [String: Any]
        FakeIdentityExtension.setXDMSharedState(state: identityMap!)
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)

        requests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(1, requests.count)

        let expectedJSON = """
        {
          "xdm": {
            "identityMap": {
              "ECID": [
                {
                  "id": "1234"
                }
              ]
            }
          }
        }
        """

        assertExactMatch(expected: expectedJSON, actual: requests[0])
    }

    func testSendEvent_withNoECIDInIdentityState_requestSentWithoutECID() {
        // set state without ECID
        guard let identityMapData = """
                    {
                      "identityMap" : {
                        "email" : [
                          {
                            "authenticationState" : "ambiguous",
                            "id" : "example@adobe.com",
                            "primary" : false
                          }
                        ]
                      }
                    }
        """.data(using: .utf8) else {
            XCTFail("Failed to convert json string to data")
            return
        }
        let identityMap = try? JSONSerialization.jsonObject(with: identityMapData, options: []) as? [String: Any]
        FakeIdentityExtension.setXDMSharedState(state: identityMap!)

        guard let responseBody = "{\"test\": \"json\"}".data(using: .utf8) else {
            XCTFail("Failed to convert json to data")
            return
        }
        let httpConnection: HttpConnection = HttpConnection(data: responseBody,
                                                            response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: httpConnection)

        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["test1": "xdm"], data: nil))

        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)

        // Assert network request does not contain an ECID
        let requests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(1, requests.count)

        let expectedJSON = "{}"
        assertExactMatch(
            expected: expectedJSON,
            actual: requests[0],
            pathOptions: KeyMustBeAbsent(paths: "xdm.identityMap.ECID[0].id"))
    }

}

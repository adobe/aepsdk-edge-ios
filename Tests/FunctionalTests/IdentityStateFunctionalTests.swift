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
import XCTest

/// Functional test suite for tests which require no Identity shared state at startup to simulate a missing or pending state.
class IdentityStateFunctionalTests: FunctionalTestBase {

    private let exEdgeInteractUrl = URL(string: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR)! // swiftlint:disable:this force_unwrapping

    override func setUp() {
        super.setUp()
        continueAfterFailure = false // fail so nil checks stop execution
        FunctionalTestBase.debugEnabled = false

        // config state and 2 event hub states (Edge, TestableEdgeInternal, FakeIdentityExtension and InstrumentedExtension registered in FunctionalTestBase)
        setExpectationEvent(type: FunctionalTestConst.EventType.HUB, source: FunctionalTestConst.EventSource.SHARED_STATE, expectedCount: 3)

        // expectations for update config request&response events
        setExpectationEvent(type: FunctionalTestConst.EventType.CONFIGURATION, source: FunctionalTestConst.EventSource.REQUEST_CONTENT, expectedCount: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.CONFIGURATION, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT, expectedCount: 1)

        // wait for async registration because the EventHub is already started in FunctionalTestBase
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([TestableEdge.self, FakeIdentityExtension.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))
        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
    }

    func testSendEvent_withPendingIdentityState_noRequestSent() {
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["test1": "xdm"], data: nil))

        let requests = getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 2)
        XCTAssertTrue(requests.isEmpty)
    }

    func testSendEvent_withPendingIdentityState_thenValidIdentityState_requestSentAfterChange() {
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["test1": "xdm"], data: nil))

        var requests = getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 2)
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
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        setNetworkResponseFor(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

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
        assertNetworkRequestsCount()

        requests = getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, requests.count)
        let flattenRequestBody = getFlattenNetworkRequestBody(requests[0])
        XCTAssertEqual("1234", flattenRequestBody["xdm.identityMap.ECID[0].id"] as? String)
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
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        setNetworkResponseFor(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["test1": "xdm"], data: nil))

        assertNetworkRequestsCount()

        // Assert network request does not contain an ECID
        let requests = getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, requests.count)
        let flattenRequestBody = getFlattenNetworkRequestBody(requests[0])
        XCTAssertNil(flattenRequestBody["xdm.identityMap.ECID[0].id"])
    }

}

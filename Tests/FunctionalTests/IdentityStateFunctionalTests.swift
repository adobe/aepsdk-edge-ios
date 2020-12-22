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

    private let exEdgeInteractUrlString = "https://edge.adobedc.net/ee/v1/interact"
    private let exEdgeInteractUrl = URL(string: "https://edge.adobedc.net/ee/v1/interact")! // swiftlint:disable:this force_unwrapping

    override func setUp() {
        super.setUp()
        continueAfterFailure = false // fail so nil checks stop execution
        FunctionalTestBase.debugEnabled = false

        // config state and 2 event hub states (TestableEdgeInternal, FakeIdentityExtension and InstrumentedExtension registered in FunctionalTestBase)
        setExpectationEvent(type: FunctionalTestConst.EventType.HUB, source: FunctionalTestConst.EventSource.SHARED_STATE, expectedCount: 3)

        // expectations for update config request&response events
        setExpectationEvent(type: FunctionalTestConst.EventType.CONFIGURATION, source: FunctionalTestConst.EventSource.REQUEST_CONTENT, expectedCount: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.CONFIGURATION, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        MobileCore.registerExtensions([TestableEdge.self, FakeIdentityExtension.self])
        MobileCore.updateConfigurationWith(configDict: ["global.privacy": "optedin",
                                                        "experienceCloud.org": "testOrg@AdobeOrg",
                                                        "edge.configId": "12345-example"])
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
    }

    func testSendEvent_withPendingIdentityState_noRequestSent() {
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["test1": "xdm"], data: nil))

        let requests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, timeout: 2)
        XCTAssertTrue(requests.isEmpty)
    }

    func testSendEvent_withPendingIdentityState_thenValidIdentityState_requestSentAfterChange() {
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["test1": "xdm"], data: nil))

        var requests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, timeout: 2)
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
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        // Once the shared state is set, the Edge Extension is expected to reprocess the original
        // Send Event request once the Hub Shared State event is received.
        FakeIdentityExtension.setSharedState(state: ["mid": "1234"])
        assertNetworkRequestsCount()

        requests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, requests.count)
        let flattenRequestBody = getFlattenNetworkRequestBody(requests[0])
        XCTAssertEqual("1234", flattenRequestBody["xdm.identityMap.ECID[0].id"] as? String)
    }

    // TODO AMSDK-10674 - investigate intermittent failures in test case
    func testSendEvent_withNoECIDInIdentityState_requestSentWithoutECID() {
        FakeIdentityExtension.setSharedState(state: ["blob": "testing"]) // set state without ECID

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
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["test1": "xdm"], data: nil))

        assertNetworkRequestsCount()

        // Assert network request does not contain an ECID
        let requests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, requests.count)
        let flattenRequestBody = getFlattenNetworkRequestBody(requests[0])
        XCTAssertNil(flattenRequestBody["xdm.identityMap.ECID[0].id"])
    }

}

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

@testable import AEPCore
@testable import AEPExperiencePlatform
import AEPServices
import XCTest

/// Functional test suite for tests which require no Identity shared state at startup to simulate a missing or pending state.
/// This test suite cannot be run in same target as other tests which registers the Identity extension
/// as all the tests in the same target use the same ACPCore instance with that Identity extension and not the needed 'fake' Identity extension.
class IdentityStateFunctionalTests: FunctionalTestBase {

    private let exEdgeInteractUrl = "https://edge.adobedc.net/ee/v1/interact"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false // fail so nil checks stop execution
        FunctionalTestBase.debugEnabled = false

        // config state and 2 event hub states (TestableExperiencePlatformInternal, FakeIdentityExtension and InstrumentedExtension registered in FunctionalTestBase)
        setExpectationEvent(type: FunctionalTestConst.EventType.eventHub, source: FunctionalTestConst.EventSource.sharedState, count: 3)

        // expectations for update config request&response events
        setExpectationEvent(type: FunctionalTestConst.EventType.configuration, source: FunctionalTestConst.EventSource.requestContent, count: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.configuration, source: FunctionalTestConst.EventSource.responseContent, count: 1)
        MobileCore.registerExtensions([TestableExperiencePlatform.self, FakeIdentityExtension.self])
        MobileCore.updateConfigurationWith(configDict: ["global.privacy": "optedin",
                                                        "experienceCloud.org": "testOrg@AdobeOrg",
                                                        "experiencePlatform.configId": "12345-example"])
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
    }

    func testSendEvent_withPendingIdentityState_noRequestSent() {
        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["test1": "xdm"], data: nil))

        let requests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, timeout: 2)
        XCTAssertTrue(requests.isEmpty)
    }

    func testSendEvent_withPendingIdentityState_thenValidIdentityState_requestSentAfterChange() {
        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["test1": "xdm"], data: nil))

        var requests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, timeout: 2)
        XCTAssertTrue(requests.isEmpty) // no network request sent yet

        let responseBody = "{\"test\": \"json\"}"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 1)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        // Once the shared state is set, the Platform Extension is expected to reprocess the original
        // Send Event request once the Hub Shared State event is received.
        FakeIdentityExtension.setSharedState(state: ["mid": "1234"])
        assertNetworkRequestsCount()

        requests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, requests.count)
        let flattenRequestBody = getFlattenNetworkRequestBody(requests[0])
        XCTAssertEqual("1234", flattenRequestBody["xdm.identityMap.ECID[0].id"] as? String)
    }

    func testSendEvent_withNoECIDInIdentityState_requestSentWithoutECID() {
        FakeIdentityExtension.setSharedState(state: ["blob": "testing"]) // set state without ECID

        let responseBody = "{\"test\": \"json\"}"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 1)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["test1": "xdm"], data: nil))

        assertNetworkRequestsCount()

        // Assert network request does not contain an ECID
        let requests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, requests.count)
        let flattenRequestBody = getFlattenNetworkRequestBody(requests[0])
        XCTAssertNil(flattenRequestBody["xdm.identityMap.ECID[0].id"])
    }

}

//
// Copyright 2022 Adobe. All rights reserved.
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
@testable import AEPEdge
import AEPEdgeIdentity
import AEPServices
import Foundation
import XCTest

/// End-to-end testing for the AEPEdge public APIs
class AEPEdgePathOverwriteTests: FunctionalTestBase {
    private let exEdgeMediaProdUrl = URL(string: FunctionalTestConst.EX_EDGE_MEDIA_PROD_URL_STR)! // swiftlint:disable:this force_unwrapping
    private let exEdgeMediaPreProdUrl = URL(string: FunctionalTestConst.EX_EDGE_MEDIA_PRE_PROD_URL_STR)! // swiftlint:disable:this force_unwrapping
    private let exEdgeMediaIntegrationUrl = URL(string: FunctionalTestConst.EX_EDGE_MEDIA_INTEGRATION_URL_STR)! // swiftlint:disable:this force_unwrapping
    private let responseBody = "{\"test\": \"json\"}"

    public class override func setUp() {
        super.setUp()
        FunctionalTestBase.debugEnabled = true
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        FileManager.default.clearCache()

        // hub shared state update for 1 extension versions (InstrumentedExtension (registered in FunctionalTestBase), IdentityEdge, Edge) IdentityEdge XDM and Config shared state updates
        setExpectationEvent(type: FunctionalTestConst.EventType.HUB, source: FunctionalTestConst.EventSource.SHARED_STATE, expectedCount: 3)

        // expectations for update config request&response events
        setExpectationEvent(type: FunctionalTestConst.EventType.CONFIGURATION, source: FunctionalTestConst.EventSource.REQUEST_CONTENT, expectedCount: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.CONFIGURATION, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT, expectedCount: 1)

        // wait for async registration because the EventHub is already started in FunctionalTestBase
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([Identity.self, Edge.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))
        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])

        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
    }

    // MARK: test network request with custom path
    func testSendEvent_withXDMData_withPathOverwrite_withProductionConfigEndpoint_sendsExEdgeNetworkRequestToCustomPath() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeMediaProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: FunctionalTestConst.EX_EDGE_MEDIA_PROD_URL_STR, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_MEDIA_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["request": ["path": "va/v1/sessionstart"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertNetworkRequestsCount()
        let resultNetworkRequests = getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_MEDIA_PROD_URL_STR, httpMethod: HttpMethod.post)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(FunctionalTestConst.EX_EDGE_MEDIA_PROD_URL_STR))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withXDMData_withPathOverwrite_withPreProductionConfigEndpoint_sendsExEdgeNetworkRequestToCustomPath() {
        // set to pre-production endpoint
        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "pre-prod"])

        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeMediaPreProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: FunctionalTestConst.EX_EDGE_MEDIA_PRE_PROD_URL_STR, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_MEDIA_PRE_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["request": ["path": "va/v1/sessionstart"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertNetworkRequestsCount()
        let resultNetworkRequests = getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_MEDIA_PRE_PROD_URL_STR, httpMethod: HttpMethod.post)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(FunctionalTestConst.EX_EDGE_MEDIA_PRE_PROD_URL_STR))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withXDMData_withPathOverwrite_withIntegrationConfigEndpoint_sendsExEdgeNetworkRequestToCustomPath() {
        // set to integration endpoint
        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "int"])

        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeMediaIntegrationUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: FunctionalTestConst.EX_EDGE_MEDIA_INTEGRATION_URL_STR, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_MEDIA_INTEGRATION_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["request": ["path": "va/v1/sessionstart"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertNetworkRequestsCount()
        let resultNetworkRequests = getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_MEDIA_INTEGRATION_URL_STR, httpMethod: HttpMethod.post)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(FunctionalTestConst.EX_EDGE_MEDIA_INTEGRATION_URL_STR))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }
}

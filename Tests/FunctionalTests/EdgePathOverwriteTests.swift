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
import AEPTestUtils
import Foundation
import XCTest

/// End-to-end testing for the AEPEdge public APIs
class AEPEdgePathOverwriteTests: TestBase, AnyCodableAsserts {
    private let TIMEOUT_SEC: TimeInterval = FunctionalTestConstants.Defaults.TIMEOUT_SEC
    static let EDGE_MEDIA_PROD_PATH_STR = "/ee/va/v1/sessionstart"
    static let EDGE_MEDIA_PRE_PROD_PATH_STR = "/ee-pre-prd/va/v1/sessionstart"
    static let EDGE_MEDIA_INTEGRATION_PATH_STR = "/ee/va/v1/sessionstart"
    static let EDGE_CONSENT_PATH_STR = "/ee/v1/privacy/set-consent"
    static let EDGE_INTEGRATION_DOMAIN_STR = "edge-int.adobedc.net"
    private let exEdgeConsentProdUrl = URL(string: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR)! // swiftlint:disable:this force_unwrapping
    private let exEdgeMediaProdUrl = URL(string: TestConstants.EX_EDGE_MEDIA_PROD_URL_STR)! // swiftlint:disable:this force_unwrapping
    private let exEdgeMediaPreProdUrl = URL(string: TestConstants.EX_EDGE_MEDIA_PRE_PROD_URL_STR)! // swiftlint:disable:this force_unwrapping
    private let exEdgeMediaIntegrationUrl = URL(string: TestConstants.EX_EDGE_MEDIA_INTEGRATION_URL_STR)! // swiftlint:disable:this force_unwrapping
    private let responseBody = "{\"test\": \"json\"}"

    private let mockNetworkService: MockNetworkService = MockNetworkService()

    // Runs before each test case
    override func setUp() {
        ServiceProvider.shared.networkService = mockNetworkService

        super.setUp()

        continueAfterFailure = false
        loggingEnabled = true
        NamedCollectionDataStore.clear()

        // hub shared state update for 1 extension versions (InstrumentedExtension (registered in TestBase), IdentityEdge, Edge) IdentityEdge XDM and Config shared state updates
        setExpectationEvent(type: TestConstants.EventType.HUB, source: TestConstants.EventSource.SHARED_STATE, expectedCount: 4)

        // expectations for update config request&response events
        setExpectationEvent(type: TestConstants.EventType.CONFIGURATION, source: TestConstants.EventSource.REQUEST_CONTENT, expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.CONFIGURATION, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)

        // wait for async registration because the EventHub is already started in TestBase
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([Identity.self, Edge.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))
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

    // MARK: test network request with custom path
    func testSendEvent_withXDMData_withPathOverwrite_withProductionConfigEndpoint_sendsExEdgeNetworkRequestToCustomPath() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeMediaProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_MEDIA_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_MEDIA_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEventWithOverwritePath = Event(name: "test-experience-event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["test": "data"], "request": ["path": "/va/v1/sessionstart"]])
        MobileCore.dispatch(event: experienceEventWithOverwritePath)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_MEDIA_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertEqual(Self.EDGE_MEDIA_PROD_PATH_STR, requestUrl.path)
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
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_MEDIA_PRE_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_MEDIA_PRE_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEventWithOverwritePath = Event(name: "test-experience-event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["test": "data"], "request": ["path": "/va/v1/sessionstart"]])
        MobileCore.dispatch(event: experienceEventWithOverwritePath)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_MEDIA_PRE_PROD_URL_STR, httpMethod: HttpMethod.post)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertEqual(Self.EDGE_MEDIA_PRE_PROD_PATH_STR, requestUrl.path)
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
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_MEDIA_INTEGRATION_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_MEDIA_INTEGRATION_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEventWithOverwritePath = Event(name: "test-experience-event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["test": "data"], "request": ["path": "/va/v1/sessionstart"]])
        MobileCore.dispatch(event: experienceEventWithOverwritePath)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_MEDIA_INTEGRATION_URL_STR, httpMethod: HttpMethod.post)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertEqual(Self.EDGE_MEDIA_INTEGRATION_PATH_STR, requestUrl.path)
        XCTAssertEqual(Self.EDGE_INTEGRATION_DOMAIN_STR, requestUrl.host)
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testUpdateConsentEvent_withPathOverwrite_ignoresOverwrite() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeConsentProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEventWithOverwritePath = Event(name: "test-experience-event", type: EventType.edge, source: EventSource.updateConsent, data: ["consents": ["collect": ["val": "y"]], "request": ["path": "/va/v1/sessionstart"]])
        MobileCore.dispatch(event: experienceEventWithOverwritePath)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertEqual(Self.EDGE_CONSENT_PATH_STR, requestUrl.path)
    }

    func testSendEvent_withXDMData_withPathOverwrite_doesNotSendRequestObjectInEventPayload() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeMediaProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_MEDIA_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_MEDIA_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEventWithOverwritePath = Event(name: "test-experience-event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["test": "data"], "request": ["path": "/va/v1/sessionstart"]])
        MobileCore.dispatch(event: experienceEventWithOverwritePath)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_MEDIA_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        let expectedJSON = "{}"
        assertTypeMatch(
            expected: expectedJSON,
            actual: resultNetworkRequests[0],
            pathOptions: KeyMustBeAbsent(paths: "events[0].request.path"))
    }

}

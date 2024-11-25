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

import AEPCore
import AEPEdge
import AEPEdgeIdentity
import AEPServices
import AEPTestUtils
import XCTest

class EdgePublicAPITests: TestBase {
    private let TIMEOUT_SEC: TimeInterval = FunctionalTestConstants.Defaults.TIMEOUT_SEC
    private let exEdgeInteractProdUrlLocHint = URL(string: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR_OR2_LOC)! // swiftlint:disable:this force_unwrapping
    private let responseBody = "{\"test\": \"json\"}"

    private let mockNetworkService: MockNetworkService = MockNetworkService()

    // Runs before each test case
    override func setUp() {
        ServiceProvider.shared.networkService = mockNetworkService

        super.setUp()

        continueAfterFailure = false
        loggingEnabled = true
        NamedCollectionDataStore.clear()

        // hub shared state update for 1 extension versions (InstrumentedExtension (registered in TestBase), IdentityEdge, Edge) IdentityEdge XDM, Config, and Edge shared state updates
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

    func testSetLocationHint_sendEvent_sendsNetworkRequestWithLocationHint() {
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR_OR2_LOC, httpMethod: HttpMethod.post, expectedCount: 1)

        Edge.setLocationHint(TestConstants.OR2_LOC)
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
    }

    func testSetLocationHint_withNilHint_sendEvent_sendsNetworkRequestWithoutLocationHint() {
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])

        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR_OR2_LOC, httpMethod: HttpMethod.post, expectedCount: 1)
        Edge.setLocationHint(TestConstants.OR2_LOC)
        Edge.sendEvent(experienceEvent: experienceEvent)
        mockNetworkService.assertAllNetworkRequestExpectations()

        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        Edge.setLocationHint(nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
    }

    func testSetLocationHint_withEmptyHint_sendEvent_sendsNetworkRequestWithoutLocationHint() {
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])

        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR_OR2_LOC, httpMethod: HttpMethod.post, expectedCount: 1)
        Edge.setLocationHint(TestConstants.OR2_LOC)
        Edge.sendEvent(experienceEvent: experienceEvent)
        mockNetworkService.assertAllNetworkRequestExpectations()

        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        Edge.setLocationHint("")
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
    }

    func testGetLocationHint_withoutSet_returnsNilHint() {
        let expectation = XCTestExpectation(description: "Request Location Hint")
        expectation.assertForOverFulfill = true
        Edge.getLocationHint({ hint, error in
            XCTAssertNil(hint)
            XCTAssertNil(error)
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: TIMEOUT_SEC)
    }

    func testGetLocationHint_withSet_returnsHint() {
        Edge.setLocationHint(TestConstants.OR2_LOC)
        let expectation = XCTestExpectation(description: "Request Location Hint")
        expectation.assertForOverFulfill = true
        Edge.getLocationHint({ hint, error in
            XCTAssertEqual(TestConstants.OR2_LOC, hint)
            XCTAssertNil(error)
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: TIMEOUT_SEC)
    }

    func testGetLocationHint_clearHint_returnsNilHint() {
        Edge.setLocationHint(TestConstants.OR2_LOC)
        Edge.setLocationHint(nil)
        let expectation = XCTestExpectation(description: "Request Location Hint")
        expectation.assertForOverFulfill = true
        Edge.getLocationHint({ hint, error in
            XCTAssertNil(hint)
            XCTAssertNil(error)
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: TIMEOUT_SEC)
    }

    func testGetLocationHint_responseEventChainedToParentId() {
        Edge.setLocationHint(TestConstants.OR2_LOC)
        let expectation = XCTestExpectation(description: "Request Location Hint")
        expectation.assertForOverFulfill = true
        Edge.getLocationHint({ _, _ in
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: TIMEOUT_SEC)

        let dispatchedRequests = getDispatchedEventsWith(type: EventType.edge, source: EventSource.requestIdentity)
        XCTAssertEqual(1, dispatchedRequests.count)

        let dispatchedResponses = getDispatchedEventsWith(type: EventType.edge, source: EventSource.responseIdentity)
        XCTAssertEqual(1, dispatchedResponses.count)

        XCTAssertEqual(dispatchedRequests[0].id, dispatchedResponses[0].parentID)
    }

    func testSendEvent_responseEventsChainedToParentId() {

        // Response data with 1 handle, 1 error, and 1 warning response, all at event index 0
        let responseData: Data? = "\u{0000}{\"handle\":[{\"type\":\"state:store\",\"payload\":[{\"key\":\"s_ecid\",\"value\":\"MCMID|29068398647607325310376254630528178721\",\"maxAge\":15552000}]}],\"errors\":[{\"status\":2003,\"type\":\"personalization\",\"title\":\"Failed to process personalization event\"}],\"warnings\":[{\"type\":\"https://ns.adobe.com/aep/errors/EXEG-0204-200\",\"status\":98,\"title\":\"Some Informative stuff here\",\"report\":{\"cause\":{\"message\":\"Some Informative stuff here\",\"code\":202}}}]}\n".data(using: .utf8)
        let responseConnection: HttpConnection = HttpConnection(data: responseData,
                                                                response: HTTPURLResponse(url: URL(string: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR)!,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)

        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"])

        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 2)

        Edge.sendEvent(experienceEvent: experienceEvent)
        mockNetworkService.assertAllNetworkRequestExpectations()

        let dispatchedRequests = getDispatchedEventsWith(type: EventType.edge, source: EventSource.requestContent)
        XCTAssertEqual(1, dispatchedRequests.count)

        let dispatchedHandleResponses = getDispatchedEventsWith(type: EventType.edge, source: "state:store")
        XCTAssertEqual(1, dispatchedHandleResponses.count)

        let dispatchedErrorResponses = getDispatchedEventsWith(type: EventType.edge, source: EventSource.errorResponseContent)
        XCTAssertEqual(2, dispatchedErrorResponses.count)

        XCTAssertEqual(dispatchedRequests[0].id, dispatchedHandleResponses[0].parentID)
        XCTAssertEqual(dispatchedRequests[0].id, dispatchedErrorResponses[0].parentID)
        XCTAssertEqual(dispatchedRequests[0].id, dispatchedErrorResponses[1].parentID)
    }
}

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
@testable import AEPEdge
import AEPEdgeIdentity
import AEPServices
import XCTest

/// Functional test suite for tests which require no SDK configuration and nil/pending configuration shared state.
class NoConfigFunctionalTests: TestBase {
    private let mockNetworkService: MockNetworkService = MockNetworkService()

    override func setUp() {
        ServiceProvider.shared.networkService = mockNetworkService

        super.setUp()
        continueAfterFailure = false // fail so nil checks stop execution
        TestBase.debugEnabled = false

        // event hub shared state for registered extensions (Edge, TestableEdge and InstrumentedExtension registered in TestBase)
        setExpectationEvent(type: TestConstants.EventType.HUB, source: TestConstants.EventSource.SHARED_STATE, expectedCount: 2)

        MobileCore.registerExtensions([TestableEdge.self])

        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
        mockNetworkService.reset()
    }

    // Runs after each test case
    override func tearDown() {
        super.tearDown()

        mockNetworkService.reset()
    }

    func testHandleExperienceEventRequest_withPendingConfigurationState_expectEventsQueueIsBlocked() {
        // NOTE: Configuration shared state must be PENDING (nil) for this test to be valid
        let configState = getSharedStateFor(TestConstants.SharedState.CONFIGURATION)
        XCTAssertNil(configState)

        // set expectations
        let handleExperienceEventRequestExpectation = XCTestExpectation(description: "handleExperienceEventRequest Called")
        handleExperienceEventRequestExpectation.isInverted = true
        TestableEdge.handleExperienceEventRequestExpectation = handleExperienceEventRequestExpectation

        let readyForEventExpectation = XCTestExpectation(description: "readyForEvent Called")
        TestableEdge.readyForEventExpectation = readyForEventExpectation

        // Dispatch request event which will block request queue as Configuration state is nil
        let requestEvent = Event(name: "Request Test",
                                 type: TestConstants.EventType.EDGE,
                                 source: TestConstants.EventSource.REQUEST_CONTENT,
                                 data: ["key": "value"])
        MobileCore.dispatch(event: requestEvent)

        // Expected readyForEvent is called
        wait(for: [readyForEventExpectation], timeout: 1.0)

        // Expected handleExperienceEventRequest not called
        wait(for: [handleExperienceEventRequestExpectation], timeout: 1.0)
    }

    func testCompletionHandler_withPendingConfigurationState_thenValidConfig_returnsEventHandles() {
        // initialize test data

        // swiftlint:disable:next line_length
        let responseBody = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a26\",\"handle\": [{\"payload\": [{\"id\": \"AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9\",\"scope\": \"buttonColor\",\"items\": [{                           \"schema\": \"https://ns.adobe.com/personalization/json-content-item\",\"data\": {\"content\": {\"value\": \"#D41DBA\"}}}]}],\"type\": \"personalization:decisions\"},{\"payload\": [{\"type\": \"url\",\"id\": 411,\"spec\": {\"url\": \"//example.url?d_uuid=9876\",\"hideReferrer\": false,\"ttlMinutes\": 10080}}],\"type\": \"identity:exchange\"}]}\n"
        let edgeUrl = URL(string: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR)! // swiftlint:disable:this force_unwrapping
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: edgeUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: httpConnection)

        // test sendEvent does not send the event when config is pending
        MobileCore.registerExtension(Identity.self)
        var receivedHandles: [EdgeEventHandle] = []
        let expectation = self.expectation(description: "Completion handler called")
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil), { (_ handles: [EdgeEventHandle]) in
                                                            receivedHandles = handles
                                                            expectation.fulfill()
                                                        })
        var resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        XCTAssertEqual(0, resultNetworkRequests.count)

        // test event gets processed when config shared state is resolved\
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "123567"])

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        wait(for: [expectation], timeout: 0.2)

        resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        XCTAssertEqual(2, receivedHandles.count)
        XCTAssertEqual("personalization:decisions", receivedHandles[0].type)
        XCTAssertEqual(1, receivedHandles[0].payload?.count)
        let handle1 = flattenDictionary(dict: receivedHandles[0].payload?[0] ?? [:])
        XCTAssertEqual(4, handle1.count)
        XCTAssertEqual("AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9", handle1["id"] as? String)
        XCTAssertEqual("buttonColor", handle1["scope"] as? String)
        XCTAssertEqual("#D41DBA", handle1["items[0].data.content.value"] as? String)
        XCTAssertEqual("https://ns.adobe.com/personalization/json-content-item", handle1["items[0].schema"] as? String)

        XCTAssertEqual("identity:exchange", receivedHandles[1].type)
        XCTAssertEqual(1, receivedHandles[1].payload?.count)
        let handle2 = flattenDictionary(dict: receivedHandles[1].payload?[0] ?? [:])
        XCTAssertEqual(5, handle2.count)
        XCTAssertEqual(411, handle2["id"] as? Int)
        XCTAssertEqual("url", handle2["type"] as? String)
        XCTAssertEqual("//example.url?d_uuid=9876", handle2["spec.url"] as? String)
        XCTAssertEqual(false, handle2["spec.hideReferrer"] as? Bool)
        XCTAssertEqual(10080, handle2["spec.ttlMinutes"] as? Int)
    }
}

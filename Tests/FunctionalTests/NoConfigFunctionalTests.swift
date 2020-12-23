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
import AEPIdentity
import AEPServices
import XCTest

/// Functional test suite for tests which require no SDK configuration and nil/pending configuration shared state.
class NoConfigFunctionalTests: FunctionalTestBase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false // fail so nil checks stop execution
        FunctionalTestBase.debugEnabled = false

        // 2 event hub shared states for registered extensions (TestableEdge and InstrumentedExtension registered in FunctionalTestBase)
        setExpectationEvent(type: FunctionalTestConst.EventType.HUB, source: FunctionalTestConst.EventSource.SHARED_STATE, expectedCount: 2)

        MobileCore.registerExtensions([TestableEdge.self])

        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
    }

    func testHandleExperienceEventRequest_withPendingConfigurationState_expectEventsQueueIsBlocked() {
        // NOTE: Configuration shared state must be PENDING (nil) for this test to be valid
        let configState = getSharedStateFor(FunctionalTestConst.SharedState.CONFIGURATION)
        XCTAssertNil(configState)

        // set expectations
        let handleExperienceEventRequestExpectation = XCTestExpectation(description: "handleExperienceEventRequest Called")
        handleExperienceEventRequestExpectation.isInverted = true
        TestableEdge.handleExperienceEventRequestExpectation = handleExperienceEventRequestExpectation

        let readyForEventExpectation = XCTestExpectation(description: "readyForEvent Called")
        TestableEdge.readyForEventExpectation = readyForEventExpectation

        // Dispatch request event which will block request queue as Configuration state is nil
        let requestEvent = Event(name: "Request Test",
                                 type: FunctionalTestConst.EventType.EDGE,
                                 source: FunctionalTestConst.EventSource.REQUEST_CONTENT,
                                 data: ["key": "value"])
        MobileCore.dispatch(event: requestEvent)

        // Expected readyForEvent is called
        wait(for: [readyForEventExpectation], timeout: 1.0)

        // Expected handleExperienceEventRequest not called
        wait(for: [handleExperienceEventRequestExpectation], timeout: 1.0)
    }

    func testResponseHandler_withPendingConfigurationState_thenValidConfig_callsOnResponse() {
        // initialize test data

        // swiftlint:disable:next line_length
        let responseBody = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a26\",\"handle\": [{\"payload\": [{\"id\": \"AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9\",\"scope\": \"buttonColor\",\"items\": [{                           \"schema\": \"https://ns.adobe.com/personalization/json-content-item\",\"data\": {\"content\": {\"value\": \"#D41DBA\"}}}]}],\"type\": \"personalization:decisions\"},{\"payload\": [{\"type\": \"url\",\"id\": 411,\"spec\": {\"url\": \"//example.url?d_uuid=9876\",\"hideReferrer\": false,\"ttlMinutes\": 10080}}],\"type\": \"identity:exchange\"}]}\n"
        let edgeUrl = URL(string: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR)! // swiftlint:disable:this force_unwrapping
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: edgeUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setNetworkResponseFor(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)
        let responseHandler = MockResponseHandler(expectedResponses: 2)

        // test sendEvent does not send the event when config is pending
        MobileCore.registerExtension(Identity.self)
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil),
                       responseHandler: responseHandler)
        var resultNetworkRequests = getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post)
        XCTAssertEqual(0, resultNetworkRequests.count)
        XCTAssertFalse(responseHandler.onCompleteCalled)

        // test event gets processed when config shared state is resolved
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "123567",
                                                        "global.privacy": "optedin",
                                                        "experienceCloud.org": "testOrg@AdobeOrg"])

        // verify
        assertNetworkRequestsCount()
        responseHandler.await()

        resultNetworkRequests = getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, resultNetworkRequests.count)
        XCTAssertEqual(2, responseHandler.onResponseHandles.count)
        XCTAssertTrue(responseHandler.onCompleteCalled)

        var data = flattenDictionary(dict: responseHandler.onResponseHandles[0].toDictionary() ?? [:])
        XCTAssertEqual(5, data.count)
        XCTAssertEqual("personalization:decisions", data["type"] as? String)
        XCTAssertEqual("AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9", data["payload[0].id"] as? String)
        XCTAssertEqual("#D41DBA", data["payload[0].items[0].data.content.value"] as? String)
        XCTAssertEqual("https://ns.adobe.com/personalization/json-content-item", data["payload[0].items[0].schema"] as? String)
        XCTAssertEqual("buttonColor", data["payload[0].scope"] as? String)
        XCTAssertEqual("buttonColor", data["payload[0].scope"] as? String)

        data = flattenDictionary(dict: responseHandler.onResponseHandles[1].toDictionary() ?? [:])
        XCTAssertEqual(6, data.count)
        XCTAssertEqual("identity:exchange", data["type"] as? String)
        XCTAssertEqual(411, data["payload[0].id"] as? Int)
        XCTAssertEqual("url", data["payload[0].type"] as? String)
        XCTAssertEqual("//example.url?d_uuid=9876", data["payload[0].spec.url"] as? String)
        XCTAssertEqual(false, data["payload[0].spec.hideReferrer"] as? Bool)
        XCTAssertEqual(10080, data["payload[0].spec.ttlMinutes"] as? Int)
    }
}

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
@testable import AEPEdge
import AEPIdentity
import AEPServices
import Foundation
import XCTest

/// End-to-end testing for the AEPEdge public APIs with Edge Response Handlers
class AEPEdgeResponseHandlerFunctionalTests: FunctionalTestBase {
    private let event1 = Event(name: "e1", type: "eventType", source: "eventSource", data: nil)
    private let event2 = Event(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private let responseBody = "{\"test\": \"json\"}"
    private let edgeUrl = URL(string: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR)!

    // swiftlint:disable:next line_length
    let responseBodyWithHandle = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a26\",\"handle\": [{\"payload\": [{\"id\": \"AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9\",\"scope\": \"buttonColor\",\"items\": [{                           \"schema\": \"https://ns.adobe.com/personalization/json-content-item\",\"data\": {\"content\": {\"value\": \"#D41DBA\"}}}]}],\"type\": \"personalization:decisions\"}]}\n"
    // swiftlint:disable:next line_length
    let responseBodyWithTwoErrors = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a27\",\"errors\": [{\"message\": \"An error occurred while calling the 'X' service for this request. Please try again.\", \"code\": \"502\"}, {\"message\": \"An error occurred while calling the 'Y', service unavailable\", \"code\": \"503\"}]}\n"

    public class override func setUp() {
        super.setUp()
        FunctionalTestBase.debugEnabled = true
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        FileManager.default.clearCache()

        // wait for async registration because the EventHub is already started in FunctionalTestBase
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([Identity.self, Edge.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))
        MobileCore.updateConfigurationWith(configDict: ["global.privacy": "optedin",
                                                        "experienceCloud.org": "testOrg@AdobeOrg",
                                                        "edge.configId": "12345-example"])

        resetTestExpectations()
    }

    func testSendEvent_withEdgeResponseHandler_callsResponseHandler() {
        let httpConnection: HttpConnection = HttpConnection(data: responseBodyWithHandle.data(using: .utf8),
                                                            response: HTTPURLResponse(url: edgeUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setNetworkResponseFor(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        let responseHandler = MockResponseHandler(expectedResponses: 1)

        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil),
                       responseHandler: responseHandler)

        assertNetworkRequestsCount()
        responseHandler.await()

        let resultNetworkRequests = getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, resultNetworkRequests.count)
        XCTAssertEqual(1, responseHandler.onResponseHandles.count)
        XCTAssertEqual(0, responseHandler.onErrorHandles.count)
        XCTAssertTrue(responseHandler.onCompleteCalled)

        let data = flattenDictionary(dict: responseHandler.onResponseHandles[0].toDictionary() ?? [:])
        XCTAssertEqual(5, data.count)
        XCTAssertEqual("personalization:decisions", data["type"] as? String)
        XCTAssertEqual("AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9", data["payload[0].id"] as? String)
        XCTAssertEqual("#D41DBA", data["payload[0].items[0].data.content.value"] as? String)
        XCTAssertEqual("https://ns.adobe.com/personalization/json-content-item", data["payload[0].items[0].schema"] as? String)
        XCTAssertEqual("buttonColor", data["payload[0].scope"] as? String)
        XCTAssertEqual("buttonColor", data["payload[0].scope"] as? String)
    }

    func testSendEventx2_withEdgeResponseHandlers_whenResponseHandle_callsResponseHandler() {
        let httpConnection: HttpConnection = HttpConnection(data: responseBodyWithHandle.data(using: .utf8),
                                                            response: HTTPURLResponse(url: edgeUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setNetworkResponseFor(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post, expectedCount: 2)
        let responseHandler1 = MockResponseHandler(expectedResponses: 1)
        let responseHandler2 = MockResponseHandler(expectedResponses: 1)

        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil),
                       responseHandler: responseHandler1)
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil),
                       responseHandler: responseHandler2)

        // verify
        assertNetworkRequestsCount()
        responseHandler1.await()
        responseHandler2.await()

        XCTAssertEqual(1, responseHandler1.onResponseHandles.count)
        XCTAssertEqual(0, responseHandler1.onErrorHandles.count)
        XCTAssertTrue(responseHandler1.onCompleteCalled)
        XCTAssertEqual(1, responseHandler2.onResponseHandles.count)
        XCTAssertEqual(0, responseHandler2.onErrorHandles.count)
        XCTAssertTrue(responseHandler2.onCompleteCalled)
    }

    func testSendEventx2_withEdgeResponseHandler_whenServerError_callsOnError() {
        let httpConnection1: HttpConnection = HttpConnection(data: responseBodyWithHandle.data(using: .utf8),
                                                             response: HTTPURLResponse(url: edgeUrl,
                                                                                       statusCode: 200,
                                                                                       httpVersion: nil,
                                                                                       headerFields: nil),
                                                             error: nil)
        let httpConnection2: HttpConnection = HttpConnection(data: responseBodyWithTwoErrors.data(using: .utf8),
                                                             response: HTTPURLResponse(url: edgeUrl,
                                                                                       statusCode: 200,
                                                                                       httpVersion: nil,
                                                                                       headerFields: nil),
                                                             error: nil)
        let responseHandler1 = MockResponseHandler(expectedErrors: 2)
        let responseHandler2 = MockResponseHandler(expectedResponses: 1)

        // set expectations & send two events
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        setNetworkResponseFor(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection1)
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil),
                       responseHandler: responseHandler1)
        assertNetworkRequestsCount()
        responseHandler1.await()

        resetTestExpectations()
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        setNetworkResponseFor(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection2)
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil),
                       responseHandler: responseHandler2)

        // verify
        assertNetworkRequestsCount()
        responseHandler2.await()

        XCTAssertEqual(1, responseHandler1.onResponseHandles.count)
        XCTAssertEqual(0, responseHandler1.onErrorHandles.count)
        XCTAssertTrue(responseHandler1.onCompleteCalled)
        XCTAssertEqual(0, responseHandler2.onResponseHandles.count)
        XCTAssertEqual(2, responseHandler2.onErrorHandles.count)
        XCTAssertTrue(responseHandler2.onCompleteCalled)
    }

    func testSendEvent_withEdgeResponseHandler_whenServerErrorAndHandle_callsOnError_callsOnResponse() {
        let responseBodyWithHandleAndError = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a26\",\"handle\": [{\"payload\": [{\"id\": \"AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9\",\"scope\": \"buttonColor\",\"items\": [{                           \"schema\": \"https://ns.adobe.com/personalization/json-content-item\",\"data\": {\"content\": {\"value\": \"#D41DBA\"}}}]}],\"type\": \"personalization:decisions\"}],\"errors\": [{\"message\": \"An error occurred while calling the 'X' service for this request. Please try again.\", \"code\": \"502\"}, {\"message\": \"An error occurred while calling the 'Y', service unavailable\", \"code\": \"503\"}]}\n"
        let httpConnection: HttpConnection = HttpConnection(data: responseBodyWithHandleAndError.data(using: .utf8),
                                                            response: HTTPURLResponse(url: edgeUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        let responseHandler = MockResponseHandler(expectedResponses: 1, expectedErrors: 1)

        // set expectations & send two events
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        setNetworkResponseFor(url: FunctionalTestConst.EX_EDGE_INTERACT_URL_STR, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil),
                       responseHandler: responseHandler)

        // verify
        assertNetworkRequestsCount()
        responseHandler.await()

        XCTAssertEqual(1, responseHandler.onResponseHandles.count)
        XCTAssertEqual(2, responseHandler.onErrorHandles.count)
        XCTAssertTrue(responseHandler.onCompleteCalled)
    }
}

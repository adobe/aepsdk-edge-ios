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
import AEPEdgeIdentity
import AEPServices
import AEPTestUtils
import Foundation
import XCTest

/// End-to-end testing for the AEPEdge public APIs with completion handlers
class CompletionHandlerFunctionalTests: TestBase, AnyCodableAsserts {
    private let TIMEOUT_SEC: TimeInterval = FunctionalTestConstants.Defaults.TIMEOUT_SEC
    private let event1 = Event(name: "e1", type: "eventType", source: "eventSource", data: nil)
    private let event2 = Event(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private let responseBody = "{\"test\": \"json\"}"
    private let edgeUrl = URL(string: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR)! // swiftlint:disable:this force_unwrapping

    // swiftlint:disable:next line_length
    let responseBodyWithHandle = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a26\",\"handle\": [{\"payload\": [{\"id\": \"AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9\",\"scope\": \"buttonColor\",\"items\": [{                           \"schema\": \"https://ns.adobe.com/personalization/json-content-item\",\"data\": {\"content\": {\"value\": \"#D41DBA\"}}}]}],\"type\": \"personalization:decisions\"}]}\n"
    // swiftlint:disable:next line_length
    let responseBodyWithTwoErrors = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a27\",\"errors\": [{\"message\": \"An error occurred while calling the 'X' service for this request. Please try again.\", \"code\": \"502\"}, {\"message\": \"An error occurred while calling the 'Y', service unavailable\", \"code\": \"503\"}]}\n"

    private let mockNetworkService: MockNetworkService = MockNetworkService()

    // Runs before each test case
    override func setUp() {
        ServiceProvider.shared.networkService = mockNetworkService

        super.setUp()

        continueAfterFailure = false
        loggingEnabled = true
        NamedCollectionDataStore.clear()

        // wait for async registration because the EventHub is already started in TestBase
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([Identity.self, Edge.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: TIMEOUT_SEC))
        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])

        resetTestExpectations()
        mockNetworkService.reset()
    }

    // Runs after each test case
    override func tearDown() {
        super.tearDown()

        mockNetworkService.reset()
    }

    func testSendEvent_withCompletionHandler_callsCompletionCorrectly() {
        let httpConnection: HttpConnection = HttpConnection(data: responseBodyWithHandle.data(using: .utf8),
                                                            response: HTTPURLResponse(url: edgeUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: httpConnection)

        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        var receivedHandles: [EdgeEventHandle] = []
        let expectation = self.expectation(description: "Completion handler called")
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil), { (handles: [EdgeEventHandle]) in
                                                            receivedHandles = handles
                                                            expectation.fulfill()
                                                        })

        mockNetworkService.assertAllNetworkRequestExpectations()
        wait(for: [expectation], timeout: TIMEOUT_SEC)

        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(1, resultNetworkRequests.count)
        XCTAssertEqual(1, receivedHandles.count)

        XCTAssertEqual("personalization:decisions", receivedHandles[0].type)

        let expectedJSON = #"""
        {
          "id": "AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9",
          "items": [
            {
              "data": {
                "content": {
                  "value": "#D41DBA"
                }
              },
              "schema": "https://ns.adobe.com/personalization/json-content-item"
            }
          ],
          "scope": "buttonColor"
        }
        """#

        assertEqual(expected: expectedJSON, actual: receivedHandles[0].payload?[0])
    }

    func testSendEventx2_withCompletionHandler_whenResponseHandle_callsCompletionCorrectly() {
        let httpConnection: HttpConnection = HttpConnection(data: responseBodyWithHandle.data(using: .utf8),
                                                            response: HTTPURLResponse(url: edgeUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: httpConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 2)

        let expectation1 = self.expectation(description: "Completion handler 1 called")
        let expectation2 = self.expectation(description: "Completion handler 2 called")
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil), { (handles: [EdgeEventHandle]) in
                                                            XCTAssertEqual(1, handles.count)
                                                            expectation1.fulfill()
                                                        })
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil), { (handles: [EdgeEventHandle]) in
                                                            XCTAssertEqual(1, handles.count)
                                                            expectation2.fulfill()
                                                        })

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        wait(for: [expectation1, expectation2], timeout: TIMEOUT_SEC)
    }

    func testSendEventx2_withCompletionHandler_whenServerError_callsCompletion() {
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

        // set expectations & send two events
        let expectation1 = self.expectation(description: "Completion handler 1 called")
        let expectation2 = self.expectation(description: "Completion handler 2 called")
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: httpConnection1)
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil), { (handles: [EdgeEventHandle]) in
                                                            XCTAssertEqual(1, handles.count)
                                                            expectation1.fulfill()
                                                        })
        mockNetworkService.assertAllNetworkRequestExpectations()
        wait(for: [expectation1], timeout: TIMEOUT_SEC)

        resetTestExpectations()
        mockNetworkService.reset()
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: httpConnection2)
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil), { (handles: [EdgeEventHandle]) in
                                                            // 0 handles, received errors but still called completion
                                                            XCTAssertEqual(0, handles.count)
                                                            expectation2.fulfill()
                                                        })

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        wait(for: [expectation2], timeout: TIMEOUT_SEC)
    }

    func testSendEvent_withCompletionHandler_whenServerErrorAndHandle_callsCompletion() {
        // swiftlint:disable:next line_length
        let responseBodyWithHandleAndError = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a26\",\"handle\": [{\"payload\": [{\"id\": \"AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9\",\"scope\": \"buttonColor\",\"items\": [{                           \"schema\": \"https://ns.adobe.com/personalization/json-content-item\",\"data\": {\"content\": {\"value\": \"#D41DBA\"}}}]}],\"type\": \"personalization:decisions\"}],\"errors\": [{\"message\": \"An error occurred while calling the 'X' service for this request. Please try again.\", \"code\": \"502\"}, {\"message\": \"An error occurred while calling the 'Y', service unavailable\", \"code\": \"503\"}]}\n"
        let httpConnection: HttpConnection = HttpConnection(data: responseBodyWithHandleAndError.data(using: .utf8),
                                                            response: HTTPURLResponse(url: edgeUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)

        let expectation = self.expectation(description: "Completion handler called")

        // set expectations & send two events
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: httpConnection)
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil), { (handles: [EdgeEventHandle]) in
                                                            XCTAssertEqual(1, handles.count)
                                                            expectation.fulfill()
                                                        })

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        wait(for: [expectation], timeout: TIMEOUT_SEC)
    }
}

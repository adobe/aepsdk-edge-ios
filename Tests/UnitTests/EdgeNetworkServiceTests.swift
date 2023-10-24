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

import AEPServices
import XCTest

@testable import AEPEdge

// swiftlint:disable type_body_length
class EdgeNetworkServiceTests: XCTestCase {

    private var mockNetworking = MockNetworking()
    private var mockResponseCallback = MockResponseCallback()
    private var networkService = EdgeNetworkService()
    private let edgeHitPayload = ExperienceEventsEdgeHit(endpoint: EdgeEndpoint(requestType: EdgeRequestType.interact,
                                                                                environmentType: .production),
                                                         datastreamId: "configIdExample",
                                                         request: EdgeRequest(meta: nil, xdm: nil, events: [["test": "data"]])).getPayload()
    private let url = URL(string: "https://test.com")! // swiftlint:disable:this force_unwrapping
    private let defaultNetworkingHeaders: [String] = ["User-Agent", "Accept-Language"]

    public override func setUp() {
        continueAfterFailure = false
        self.mockResponseCallback = MockResponseCallback()
        self.mockNetworking = MockNetworking()
        ServiceProvider.shared.networkService = mockNetworking
        networkService = EdgeNetworkService()
    }

    func testDoRequest_whenRequestHeadersAreEmpty_setsDefaultHeaders() {
        let defaultServiceHeaders: [String: String] = ["accept": "application/json", "Content-Type": "application/json"]
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        networkService.doRequest(url: url, requestBody: edgeHitPayload, requestHeaders: [:], streaming: nil, responseCallback: mockResponseCallback, completion: { success, retryInterval in
            // verify
            XCTAssertTrue(success)
            XCTAssertNil(retryInterval)
            XCTAssertTrue(self.mockNetworking.connectAsyncCalled)
            XCTAssertEqual(defaultServiceHeaders.count + self.defaultNetworkingHeaders.count,
                           self.mockNetworking.connectAsyncCalledWithNetworkRequest?.httpHeaders.count)
            for header in defaultServiceHeaders {
                XCTAssertNotNil(self.mockNetworking.connectAsyncCalledWithNetworkRequest?.httpHeaders[header.key])
            }

            for header in self.defaultNetworkingHeaders {
                XCTAssertNotNil(self.mockNetworking.connectAsyncCalledWithNetworkRequest?.httpHeaders[header])
            }
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenRequestHeadersExist_RequestHeadersAppendedOnNetworkCall() {
        // setup
        let testHeaders: [String: String] = ["test": "header", "accept": "application/json", "Content-Type": "application/json", "key": "value"]
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        networkService.doRequest(url: url,
                                 requestBody: edgeHitPayload,
                                 requestHeaders: testHeaders,
                                 streaming: nil,
                                 responseCallback: mockResponseCallback,
                                 completion: { success, retryInterval  in
                                    // verify
                                    XCTAssertTrue(success)
                                    XCTAssertNil(retryInterval)
                                    XCTAssertTrue(self.mockNetworking.connectAsyncCalled)
                                    XCTAssertEqual(testHeaders.count + self.defaultNetworkingHeaders.count, self.mockNetworking.connectAsyncCalledWithNetworkRequest?.httpHeaders.count)
                                    for header in testHeaders {
                                        XCTAssertNotNil(self.mockNetworking.connectAsyncCalledWithNetworkRequest?.httpHeaders[header.key])
                                    }

                                    for header in self.defaultNetworkingHeaders {
                                        XCTAssertNotNil(self.mockNetworking.connectAsyncCalledWithNetworkRequest?.httpHeaders[header])
                                    }
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenConnection_ResponseCode200_CallsCompletionTrue_AndCallsResponseCallback_AndNoErrorCallback() {
        // setup
        let stringResponseBody = "{\"key\":\"value\"}"
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        let mockHttpConnection = HttpConnection(data: stringResponseBody.data(using: .utf8),
                                                response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
                                                error: nil)
        mockNetworking.connectAsyncMockReturnConnection = mockHttpConnection
        networkService.doRequest(url: url,
                                 requestBody: edgeHitPayload,
                                 requestHeaders: [:],
                                 streaming: nil,
                                 responseCallback: mockResponseCallback,
                                 completion: { success, retryInterval in
                                    // verify
                                    XCTAssertTrue(success)
                                    XCTAssertNil(retryInterval)
                                    XCTAssertTrue(self.mockResponseCallback.onResponseCalled)
                                    XCTAssertFalse(self.mockResponseCallback.onErrorCalled)
                                    XCTAssertTrue(self.mockResponseCallback.onCompleteCalled)
                                    XCTAssertEqual([stringResponseBody], self.mockResponseCallback.onResponseJsonResponse)
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenConnection_ResponseCode204_CallsCompletionTrue_AndNoResponseCallback_AndNoErrorCallback() {
        // setup
        let stringResponseBody = "OK"
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        let mockHttpConnection = HttpConnection(data: stringResponseBody.data(using: .utf8),
                                                response: HTTPURLResponse(url: url, statusCode: 204, httpVersion: nil, headerFields: nil),
                                                error: nil)
        mockNetworking.connectAsyncMockReturnConnection = mockHttpConnection
        networkService.doRequest(url: url,
                                 requestBody: edgeHitPayload,
                                 requestHeaders: [:],
                                 streaming: nil,
                                 responseCallback: mockResponseCallback,
                                 completion: { success, retryInterval in
                                    // verify
                                    XCTAssertTrue(success)
                                    XCTAssertNil(retryInterval)
                                    XCTAssertFalse(self.mockResponseCallback.onResponseCalled)
                                    XCTAssertFalse(self.mockResponseCallback.onErrorCalled)
                                    XCTAssertTrue(self.mockResponseCallback.onCompleteCalled)
                                    XCTAssertEqual([], self.mockResponseCallback.onResponseJsonResponse)
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenConnection_ResponseCode207_CallsCompletionTrue_AndResponseCallback_AndNotErrorCallback() {
        // setup
        let stringResponseBody = "OK"
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        let mockHttpConnection = HttpConnection(data: stringResponseBody.data(using: .utf8),
                                                response: HTTPURLResponse(url: url, statusCode: 207, httpVersion: nil, headerFields: nil),
                                                error: nil)
        mockNetworking.connectAsyncMockReturnConnection = mockHttpConnection
        networkService.doRequest(url: url,
                                 requestBody: edgeHitPayload,
                                 requestHeaders: [:],
                                 streaming: nil,
                                 responseCallback: mockResponseCallback,
                                 completion: { success, retryInterval in
                                    // verify
                                    XCTAssertTrue(success)
                                    XCTAssertNil(retryInterval)
                                    XCTAssertTrue(self.mockResponseCallback.onResponseCalled)
                                    XCTAssertFalse(self.mockResponseCallback.onErrorCalled)
                                    XCTAssertTrue(self.mockResponseCallback.onCompleteCalled)
                                    XCTAssertEqual([stringResponseBody], self.mockResponseCallback.onResponseJsonResponse)
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenConnection_RecoverableResponseCode_CallsCompletionFalse_AndNoResponseCallback_AndNoErrorCallback() {
        // setup
        let stringResponseBody = "Service Unavailable"
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        let mockHttpConnection = HttpConnection(data: stringResponseBody.data(using: .utf8),
                                                response: HTTPURLResponse(url: url, statusCode: 503, httpVersion: nil, headerFields: ["Retry-After": "60"]),
                                                error: nil)
        mockNetworking.connectAsyncMockReturnConnection = mockHttpConnection
        networkService.doRequest(url: url,
                                 requestBody: edgeHitPayload,
                                 requestHeaders: [:],
                                 streaming: nil,
                                 responseCallback: mockResponseCallback,
                                 completion: { success, retryInterval in
                                    // verify
                                    XCTAssertFalse(success)
                                    XCTAssertEqual(60.0, retryInterval)
                                    XCTAssertFalse(self.mockResponseCallback.onResponseCalled)
                                    XCTAssertFalse(self.mockResponseCallback.onErrorCalled)
                                    XCTAssertFalse(self.mockResponseCallback.onCompleteCalled)
                                    XCTAssertEqual([], self.mockResponseCallback.onResponseJsonResponse)
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenConnection_UnrecoverableResponseCode_WhenContentTypeJson_WithError_ReturnFormattedError() {
        // setup
        let error: NSError = NSError(domain: NSURLErrorDomain, code: NSURLErrorAppTransportSecurityRequiresSecureConnection, userInfo: nil)
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        let mockHttpConnection = HttpConnection(data: nil, response: HTTPURLResponse(url: url, statusCode: 503, httpVersion: nil, headerFields: nil), error: error)
        mockNetworking.connectAsyncMockReturnConnection = mockHttpConnection
        networkService.doRequest(url: url,
                                 requestBody: edgeHitPayload,
                                 requestHeaders: [:],
                                 streaming: nil,
                                 responseCallback: mockResponseCallback,
                                 completion: { success, retryInterval in
                                    // verify
                                    XCTAssertTrue(success)
                                    XCTAssertNil(retryInterval)
                                    XCTAssertFalse(self.mockResponseCallback.onResponseCalled)
                                    XCTAssertTrue(self.mockResponseCallback.onErrorCalled)
                                    XCTAssertEqual(1, self.mockResponseCallback.onErrorJsonError.capacity)
                                    let errorJson = self.mockResponseCallback.onErrorJsonError[0]
                                    XCTAssertTrue(errorJson.contains("\"title\":\"Unexpected Error\""))
                                    XCTAssertTrue(errorJson.contains("\"detail\":\"service unavailable\""))
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenConnection_UnrecoverableResponseCode_WhenContentTypeJson_WithNilError_ShouldReturnGenericError() {
        // test
        let mockHttpConnection = HttpConnection(data: nil,
                                                response: HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil),
                                                error: nil)
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        mockNetworking.connectAsyncMockReturnConnection = mockHttpConnection
        networkService.doRequest(url: url,
                                 requestBody: edgeHitPayload,
                                 requestHeaders: [:],
                                 streaming: nil,
                                 responseCallback: mockResponseCallback,
                                 completion: { success, retryInterval in
                                    // verify
                                    XCTAssertTrue(success)
                                    XCTAssertNil(retryInterval)
                                    XCTAssertFalse(self.mockResponseCallback.onResponseCalled)
                                    XCTAssertTrue(self.mockResponseCallback.onErrorCalled)
                                    XCTAssertEqual(1, self.mockResponseCallback.onErrorJsonError.capacity)
                                    let errorJson = self.mockResponseCallback.onErrorJsonError[0]
                                    XCTAssertTrue(errorJson.contains("\"title\":\"Unexpected Error\""))
                                    XCTAssertTrue(errorJson.contains("\"detail\":\"Request to Experience Edge failed with an unknown exception\""))
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenConnection_UnrecoverableResponseCode_WhenContentTypeJson_WithInvalidJsonContent() {
        // setup
        let stringResponseBody = "Internal Server Error"
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        let mockHttpConnection = HttpConnection(data: stringResponseBody.data(using: .utf8),
                                                response: HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil),
                                                error: nil)
        mockNetworking.connectAsyncMockReturnConnection = mockHttpConnection
        networkService.doRequest(url: url,
                                 requestBody: edgeHitPayload,
                                 requestHeaders: [:],
                                 streaming: nil,
                                 responseCallback: mockResponseCallback,
                                 completion: { success, retryInterval in
                                    // verify
                                    XCTAssertTrue(success)
                                    XCTAssertNil(retryInterval)
                                    XCTAssertFalse(self.mockResponseCallback.onResponseCalled)
                                    XCTAssertTrue(self.mockResponseCallback.onErrorCalled)
                                    XCTAssertEqual(1, self.mockResponseCallback.onErrorJsonError.capacity)
                                    let errorJson = self.mockResponseCallback.onErrorJsonError[0]
                                    XCTAssertTrue(errorJson.contains("\"title\":\"Unexpected Error\""))
                                    XCTAssertTrue(errorJson.contains("\"detail\":\"Internal Server Error\""))
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenConnection_UnrecoverableResponseCode_WhenContentTypeJson_WithValidJsonContent() {
        // setup
        let stringResponseBody = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [],\n" +
            "      \"errors\": [\n" +
            "        {\n" +
            "          \"code\": \"global:0\",\n" +
            "          \"namespace\": \"global\",\n" +
            "          \"severity\": \"0\",\n" +
            "          \"message\": \"Failed due to unrecoverable system error: java.lang.IllegalStateException: Expected BEGIN_ARRAY but was BEGIN_OBJECT at path $.commerce.purchases\"\n"
            +
            "        }\n" +
            "      ]\n" +
            "    }"
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        let mockHttpConnection = HttpConnection(data: stringResponseBody.data(using: .utf8),
                                                response: HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil),
                                                error: nil)
        mockNetworking.connectAsyncMockReturnConnection = mockHttpConnection
        networkService.doRequest(url: url,
                                 requestBody: edgeHitPayload,
                                 requestHeaders: [:],
                                 streaming: nil,
                                 responseCallback: mockResponseCallback,
                                 completion: { success, retryInterval in
                                    // verify
                                    XCTAssertTrue(success)
                                    XCTAssertNil(retryInterval)
                                    XCTAssertFalse(self.mockResponseCallback.onResponseCalled)
                                    XCTAssertTrue(self.mockResponseCallback.onErrorCalled)
                                    XCTAssertEqual(1, self.mockResponseCallback.onErrorJsonError.capacity)
                                    let errorJson = self.mockResponseCallback.onErrorJsonError[0]
                                    XCTAssertTrue(errorJson.contains(stringResponseBody))
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenRequestProcessed_CallsOnComplete() {
        // setup
        let stringResponseBody = "{\"key\":\"value\"}"
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        let mockHttpConnection = HttpConnection(data: stringResponseBody.data(using: .utf8),
                                                response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
                                                error: nil)
        mockNetworking.connectAsyncMockReturnConnection = mockHttpConnection
        networkService.doRequest(url: url,
                                 requestBody: edgeHitPayload,
                                 requestHeaders: [:],
                                 streaming: nil,
                                 responseCallback: mockResponseCallback,
                                 completion: { success, retryInterval in
                                    // verify
                                    XCTAssertTrue(success)
                                    XCTAssertNil(retryInterval)
                                    XCTAssertTrue(self.mockResponseCallback.onResponseCalled)
                                    XCTAssertFalse(self.mockResponseCallback.onErrorCalled)
                                    XCTAssertTrue(self.mockResponseCallback.onCompleteCalled)
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenRequestNotProcessed_NoCallOnComplete() {
        // setup
        let stringResponseBody = "Service Unavailable"
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        let mockHttpConnection = HttpConnection(data: stringResponseBody.data(using: .utf8),
                                                response: HTTPURLResponse(url: url, statusCode: 503, httpVersion: nil, headerFields: ["Retry-After": "60"]),
                                                error: nil)
        mockNetworking.connectAsyncMockReturnConnection = mockHttpConnection
        networkService.doRequest(url: url,
                                 requestBody: edgeHitPayload,
                                 requestHeaders: [:],
                                 streaming: nil,
                                 responseCallback: mockResponseCallback,
                                 completion: { success, retryInterval in
                                    // verify
                                    XCTAssertFalse(success)
                                    XCTAssertEqual(60.0, retryInterval)
                                    XCTAssertFalse(self.mockResponseCallback.onResponseCalled)
                                    XCTAssertFalse(self.mockResponseCallback.onErrorCalled)
                                    XCTAssertFalse(self.mockResponseCallback.onCompleteCalled)
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenRequestNotProcessed_NoCallOnComplete_noRetryAfterHeader() {
        // setup
        let stringResponseBody = "Service Unavailable"
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        let mockHttpConnection = HttpConnection(data: stringResponseBody.data(using: .utf8),
                                                response: HTTPURLResponse(url: url, statusCode: 503, httpVersion: nil, headerFields: nil),
                                                error: nil)
        mockNetworking.connectAsyncMockReturnConnection = mockHttpConnection
        networkService.doRequest(url: url, requestBody: edgeHitPayload, requestHeaders: [:], streaming: nil, responseCallback: mockResponseCallback, completion: { success, retryInterval in
            // verify
            XCTAssertFalse(success)
            XCTAssertEqual(5.0, retryInterval)
            XCTAssertFalse(self.mockResponseCallback.onResponseCalled)
            XCTAssertFalse(self.mockResponseCallback.onErrorCalled)
            XCTAssertFalse(self.mockResponseCallback.onCompleteCalled)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenRequestNotProcessed_NoCallOnComplete_emptyRetryAfterHeader() {
        // setup
        let stringResponseBody = "Service Unavailable"
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        let mockHttpConnection = HttpConnection(data: stringResponseBody.data(using: .utf8),
                                                response: HTTPURLResponse(url: url, statusCode: 503, httpVersion: nil, headerFields: ["Retry-After": ""]),
                                                error: nil)
        mockNetworking.connectAsyncMockReturnConnection = mockHttpConnection
        networkService.doRequest(url: url,
                                 requestBody: edgeHitPayload,
                                 requestHeaders: [:],
                                 streaming: nil,
                                 responseCallback: mockResponseCallback,
                                 completion: { success, retryInterval in
                                    // verify
                                    XCTAssertFalse(success)
                                    XCTAssertEqual(5.0, retryInterval)
                                    XCTAssertFalse(self.mockResponseCallback.onResponseCalled)
                                    XCTAssertFalse(self.mockResponseCallback.onErrorCalled)
                                    XCTAssertFalse(self.mockResponseCallback.onCompleteCalled)
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenRequestNotProcessed_NoCallOnComplete_invalidRetryAfterHeader() {
        // setup
        let stringResponseBody = "Service Unavailable"
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        let mockHttpConnection = HttpConnection(data: stringResponseBody.data(using: .utf8),
                                                response: HTTPURLResponse(url: url, statusCode: 503, httpVersion: nil, headerFields: ["Retry-After": "NotAValidRetryInterval"]),
                                                error: nil)
        mockNetworking.connectAsyncMockReturnConnection = mockHttpConnection
        networkService.doRequest(url: url,
                                 requestBody: edgeHitPayload,
                                 requestHeaders: [:],
                                 streaming: nil,
                                 responseCallback: mockResponseCallback,
                                 completion: { success, retryInterval in
                                    // verify
                                    XCTAssertFalse(success)
                                    XCTAssertEqual(5.0, retryInterval)
                                    XCTAssertFalse(self.mockResponseCallback.onResponseCalled)
                                    XCTAssertFalse(self.mockResponseCallback.onErrorCalled)
                                    XCTAssertFalse(self.mockResponseCallback.onCompleteCalled)
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 0.5)
    }

    func testDoRequest_whenRequestNotProcessed_shouldRetry_CallsOnComplete() {
        // setup
        let stringResponseBody = "Service Unavailable"
        let expectation = XCTestExpectation(description: "Network callback is invoked")

        // test
        let mockHttpConnection = HttpConnection(data: stringResponseBody.data(using: .utf8),
                                                response: HTTPURLResponse(url: url, statusCode: 503, httpVersion: nil, headerFields: ["Retry-After": "60"]),
                                                error: nil)
        mockNetworking.connectAsyncMockReturnConnection = mockHttpConnection
        networkService.doRequest(url: url,
                                 requestBody: edgeHitPayload,
                                 requestHeaders: [:],
                                 streaming: nil,
                                 responseCallback: mockResponseCallback,
                                 completion: { success, retryInterval in
                                    // verify
                                    XCTAssertFalse(success)
                                    XCTAssertEqual(60.0, retryInterval)
                                    XCTAssertFalse(self.mockResponseCallback.onResponseCalled)
                                    XCTAssertFalse(self.mockResponseCallback.onErrorCalled)
                                    XCTAssertFalse(self.mockResponseCallback.onCompleteCalled) // hit can be retried don't invoke onComplete
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 0.5)
    }

    func testHandleStreamingResponse_nilSeparators_doesNotCrash() {
        let responseStr: String = ""

        let streamingSettings = Streaming(recordSeparator: nil, lineFeed: nil)
        let connection: HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil) // swiftlint:disable:this force_unwrapping
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)

        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }

    func testHandleStreamingResponse_EmptyResponse() {
        let responseStr: String = "{}"

        let streamingSettings = Streaming(recordSeparator: "", lineFeed: "\n")
        let connection: HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil) // swiftlint:disable:this force_unwrapping
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)

        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }

    func testHandleStreamingResponse_nonCharacterSeparators_doesNotHandleContent() {
        let responseStr: String =
            "<RS>{\"some\":\"thing\\n\"}<LF>" +
            "<RS>{\n" +
            "  \"may\": {\n" +
            "    \"include\": \"nested\",\n" +
            "    \"objects\": [\n" +
            "      \"and\",\n" +
            "      \"arrays\"\n" +
            "    ]\n" +
            "  }\n" +
            "}<LF>"

        let streamingSettings = Streaming(recordSeparator: "<RS>", lineFeed: "<LF>")
        let connection: HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil) // swiftlint:disable:this force_unwrapping
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)

        XCTAssertFalse(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([], mockResponseCallback.onResponseJsonResponse)
    }

    func testHandleStreamingResponse_SimpleStreamingResponse2() {
        let responseStr: String =
            "\u{00A9}{\"some\":\"thing\\n\"}\u{00F8}" +
            "\u{00A9}{\n" +
            "  \"may\": {\n" +
            "    \"include\": \"nested\",\n" +
            "    \"objects\": [\n" +
            "      \"and\",\n" +
            "      \"arrays\"\n" +
            "    ]\n" +
            "  }\n" +
            "}\u{00F8}"
        var expectedResponse: [String] = []
        expectedResponse.append("{\"some\":\"thing\\n\"}")
        expectedResponse.append("{\n" +
                                    "  \"may\": {\n" +
                                    "    \"include\": \"nested\",\n" +
                                    "    \"objects\": [\n" +
                                    "      \"and\",\n" +
                                    "      \"arrays\"\n" +
                                    "    ]\n" +
                                    "  }\n" +
                                    "}")
        let streamingSettings = Streaming(recordSeparator: "\u{00A9}", lineFeed: "\u{00F8}")
        let connection: HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil) // swiftlint:disable:this force_unwrapping
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)

        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual(expectedResponse, mockResponseCallback.onResponseJsonResponse)
    }

    func testHandleStreamingResponse_SimpleStreamingResponse3() {
        let responseStr: String =
            "\u{00A9}{\"some\":\"thing\\n\"}\u{00FF}" +
            "\u{00A9}{\n" +
            "  \"may\": {\n" +
            "    \"include\": \"nested\",\n" +
            "    \"objects\": [\n" +
            "      \"and\",\n" +
            "      \"arrays\"\n" +
            "    ]\n" +
            "  }\n" +
            "}\u{00FF}"
        var expectedResponse: [String] = []
        expectedResponse.append("{\"some\":\"thing\\n\"}")
        expectedResponse.append("{\n" +
                                    "  \"may\": {\n" +
                                    "    \"include\": \"nested\",\n" +
                                    "    \"objects\": [\n" +
                                    "      \"and\",\n" +
                                    "      \"arrays\"\n" +
                                    "    ]\n" +
                                    "  }\n" +
                                    "}")
        let streamingSettings = Streaming(recordSeparator: "\u{00A9}", lineFeed: "\u{00FF}")
        let connection: HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil) // swiftlint:disable:this force_unwrapping
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)

        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual(expectedResponse, mockResponseCallback.onResponseJsonResponse)
    }

    func testHandleStreamingResponse_SingleStreamingResponse() {
        // swiftlint:disable line_length
        let responseStr: String = "\u{0000}{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}\n"
        let expectedResponse: String =
            "{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}"
        // swiftlint:enable line_length
        let streamingSettings = Streaming(recordSeparator: "\u{0000}", lineFeed: "\n")
        let connection: HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil) // swiftlint:disable:this force_unwrapping
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)

        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([expectedResponse], mockResponseCallback.onResponseJsonResponse)
    }

    func testHandleStreamingResponse_TwoStreamingResponses() {
        // swiftlint:disable line_length
        var responseStr: String = "\u{0000}{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}\n"
        responseStr += responseStr
        let expectedResponse: String =
            "{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}"
        // swiftlint:enable line_length
        let streamingSettings = Streaming(recordSeparator: "\u{0000}", lineFeed: "\n")
        let connection: HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil) // swiftlint:disable:this force_unwrapping
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)

        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([expectedResponse, expectedResponse], mockResponseCallback.onResponseJsonResponse)
    }

    func testHandleStreamingResponse_ManyStreamingResponses() {
        // swiftlint:disable line_length
        let responseStr: String = "\u{0000}{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}\n"
        let expectedResponse: String =
            "{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}"
        // swiftlint:enable line_length
        let streamingSettings = Streaming(recordSeparator: "\u{0000}", lineFeed: "\n")
        let connection: HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil) // swiftlint:disable:this force_unwrapping
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)

        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([expectedResponse], mockResponseCallback.onResponseJsonResponse)
    }

    func testHandleNonStreamingResponse_WhenValidJson_ShouldReturnEntireResponse() {
        let responseStr: String = "{\"some\":\"thing\"}," +
            "{" +
            "  \"may\": {" +
            "    \"include\": \"nested\"," +
            "    \"objects\": [" +
            "      \"and\"," +
            "      \"arrays\"" +
            "    ]" +
            "  }" +
            "}"
        let connection: HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil) // swiftlint:disable:this force_unwrapping
        networkService.handleContent(connection: connection, streaming: nil, responseCallback: mockResponseCallback)

        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }

    func testHandleNonStreamingResponse_WhenValidJsonWithNewLine_ShouldReturnResponse() {
        let responseStr: String = "{\"some\":\"thing\"},\n" +
            "{" +
            "  \"may\": {" +
            "    \"include\": \"nested\"," +
            "    \"objects\": [" +
            "      \"and\"," +
            "      \"arrays\"" +
            "    ]" +
            "  }" +
            "}\n"
        let connection: HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil) // swiftlint:disable:this force_unwrapping
        networkService.handleContent(connection: connection, streaming: nil, responseCallback: mockResponseCallback)

        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }

    func testHandleNonStreamingResponse_WhenOneJsonObject_ShouldReturnEntireResponse() {
        let responseStr: String = "{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}"
        // swiftlint:disable:previous line_length
        guard let responseData = responseStr.data(using: .utf8) else {
            XCTFail("Failed to convert json to data")
            return
        }
        let connection: HttpConnection = HttpConnection(data: responseData, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: nil, responseCallback: mockResponseCallback)

        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }

    func testHandleNonStreamingResponse_WhenTwoJsonObjects_ShouldReturnEntireResponse() {
        let responseStr: String = "{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}"
        // swiftlint:disable:previous line_length
        let connection: HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil) // swiftlint:disable:this force_unwrapping
        networkService.handleContent(connection: connection, streaming: nil, responseCallback: mockResponseCallback)

        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }

    func testHandleNonStreamingResponse_WhenResponseIsEmptyObject_ShouldReturnEmptyObject() {
        let responseStr: String = "{}"
        let connection: HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil) // swiftlint:disable:this force_unwrapping
        networkService.handleContent(connection: connection, streaming: nil, responseCallback: mockResponseCallback)

        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }

    func testHandleNonStreamingResponse_WhenResponseIsEmptyString_ShouldReturnEmptyString() {
        let responseStr = "".data(using: .utf8)
        let connection: HttpConnection = HttpConnection(data: responseStr, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: nil, responseCallback: mockResponseCallback)

        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([""], mockResponseCallback.onResponseJsonResponse)
    }
}

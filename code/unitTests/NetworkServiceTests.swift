//
// ADOBE CONFIDENTIAL
//
// Copyright 2020 Adobe
// All Rights Reserved.
//
// NOTICE: All information contained herein is, and remains
// the property of Adobe and its suppliers, if any. The intellectual
// and technical concepts contained herein are proprietary to Adobe
// and its suppliers and are protected by all applicable intellectual
// property laws, including trade secret and copyright laws.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from Adobe.
//

import XCTest

@testable import ACPExperiencePlatform

class NetworkServiceTests: XCTestCase {

    override func tearDown() {
        NetworkService.shared.session = nil
    }
    
    // MARK: NetworkService tests

    func testConnectAsync_returnsError_whenIncompleteUrl() {
        let expectation = XCTestExpectation(description: "Completion handler called")
        let testUrl = URL(string: "https://")!
        let networkRequest = NetworkRequest(url: testUrl)
        NetworkService.shared.connectAsync(networkRequest: networkRequest, completionHandler: {connection in
            XCTAssertNil(connection.data)
            XCTAssertNil(connection.response)
            guard let resultError = connection.error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            guard case NetworkServiceError.invalidUrl = resultError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testConnectAsync_returnsError_whenInsecureUrl() {
        let expectation = XCTestExpectation(description: "Completion handler called")
        let testUrl = URL(string: "http://www.adobe.com")!
        let networkRequest = NetworkRequest(url: testUrl)
        // test&verify
        NetworkService.shared.connectAsync(networkRequest: networkRequest, completionHandler: {connection in
            XCTAssertNil(connection.data)
            XCTAssertNil(connection.response)
            guard let resultError = connection.error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            guard case NetworkServiceError.invalidUrl = resultError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testConnectAsync_returnsError_whenInvalidUrl() {
        let expectation = XCTestExpectation(description: "Completion handler called")
        let testUrl = URL(string: "invalid.url")!
        let networkRequest = NetworkRequest(url: testUrl)
        // test&verify
        NetworkService.shared.connectAsync(networkRequest: networkRequest, completionHandler: {connection in
            XCTAssertNil(connection.data)
            XCTAssertNil(connection.response)
            guard let resultError = connection.error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            guard case NetworkServiceError.invalidUrl = resultError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testConnectAsync_initiatesConnection_whenValidNetworkRequest() {
        let expectation = XCTestExpectation(description: "Completion handler called")

        let testUrl = URL(string: "https://test.com")!
        let testBody = "test body"
        let networkRequest = NetworkRequest(url: testUrl, httpMethod: HttpMethod.post, connectPayload: testBody, httpHeaders: ["Accept": "text/html"], connectTimeout: 2.0, readTimeout: 3.0)
        let jsonData = "{\"test\": \"json\"\"}".data(using: .utf8)
        let mockSession = MockURLSession(data: jsonData, urlResponse: nil, error: nil)
        NetworkService.shared.session = mockSession
        NetworkService.shared.connectAsync(networkRequest: networkRequest, completionHandler: {connection in
            XCTAssertEqual(jsonData, connection.data)
            XCTAssertNil(connection.response)
            XCTAssertNil(connection.error)
            
            expectation.fulfill()
        })
        
        // verify
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockSession.dataTaskWithCompletionHandlerCalled)
        XCTAssertEqual(URLRequest.CachePolicy.reloadIgnoringCacheData, mockSession.calledWithUrlRequest?.cachePolicy)
        XCTAssertEqual(Data(testBody.utf8), mockSession.calledWithUrlRequest?.httpBody)
        XCTAssertEqual(["Accept": "text/html"], mockSession.calledWithUrlRequest?.allHTTPHeaderFields) // TODO: add assert for default headers
        XCTAssertEqual("POST", mockSession.calledWithUrlRequest?.httpMethod)
        XCTAssertEqual(testUrl, mockSession.calledWithUrlRequest?.url)
    }
    
    func testConnectAsync_returnsTimeoutError_whenConnectionTimesOut() {
        let expectation = XCTestExpectation(description: "Completion handler called")

        let testUrl = URL(string: "https://example.com:81")!
        let testBody = "test body"
        let networkRequest = NetworkRequest(url: testUrl, httpMethod: HttpMethod.post, connectPayload: testBody, httpHeaders: ["Accept": "text/html"], connectTimeout: 1.0, readTimeout: 1.0)
        NetworkService.shared.connectAsync(networkRequest: networkRequest, completionHandler: {connection in
            XCTAssertNil(connection.data)
            XCTAssertNil(connection.response)
            XCTAssertEqual("The request timed out.", connection.error?.localizedDescription)
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.5)
    }
    
    func testConnectAsync_initiatesConnection_whenValidUrl_noCompletionHandler() {
        let testUrl = URL(string: "https://test.com")!
        let networkRequest = NetworkRequest(url: testUrl)
        let mockSession = MockURLSession()
        NetworkService.shared.session = mockSession
        
        // test
        NetworkService.shared.connectAsync(networkRequest: networkRequest)
        
        // verify
        XCTAssertTrue(mockSession.dataTaskWithCompletionHandlerCalled)
    }
    
    // MARK: NetworkServiceOverrider tests
    
    func testShouldOverride_calledWithValidUrls_whenMultipleRequests() {
        let testPerformerOverrider = MockPerformerOverrider()
        
        // test
        NetworkServiceOverrider.shared.enableOverride(with:testPerformerOverrider)
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test1.com")!))
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "schema://test2.com")!))
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "http://test3.com")!))
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "invalid.url")!))
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test3.com?param=val&second=param")!))
        
        // verify
        // the url is checked if valid before calling the overrider
        XCTAssertEqual(2, testPerformerOverrider.shouldOverrideCalledWithUrls.count)
        XCTAssertEqual("https://test1.com", testPerformerOverrider.shouldOverrideCalledWithUrls[0].absoluteString)
        XCTAssertEqual("https://test3.com?param=val&second=param", testPerformerOverrider.shouldOverrideCalledWithUrls[1].absoluteString)
    }
    
    func testOverridenConnectAsync_called_whenMultipleRequests() {
        let testPerformerOverrider = MockPerformerOverrider()
        let request1 = NetworkRequest(url: URL(string: "https://test1.com")!, httpMethod: HttpMethod.post, connectPayload: "test body", httpHeaders: ["Accept": "text/html"], connectTimeout: 2.0, readTimeout: 3.0)
        let request2 = NetworkRequest(url: URL(string: "https://test2.com")!, httpMethod: HttpMethod.get, httpHeaders: ["Accept": "text/html"])
        let request3 = NetworkRequest(url: URL(string: "https://test3.com")!)
        let completionHandler : ((HttpConnection) -> Void) = { connection in
           print("say hi")
        }
    
        // test&verify
        NetworkServiceOverrider.shared.enableOverride(with:testPerformerOverrider)
        NetworkService.shared.connectAsync(networkRequest: request1, completionHandler: completionHandler)
        XCTAssertEqual(request1.url, testPerformerOverrider.connectAsyncCalledWithNetworkRequest?.url)
        XCTAssertNotNil(testPerformerOverrider.connectAsyncCalledWithCompletionHandler)
        testPerformerOverrider.reset()
        
        NetworkService.shared.connectAsync(networkRequest: request2, completionHandler: nil)
        XCTAssertEqual(request2.url, testPerformerOverrider.connectAsyncCalledWithNetworkRequest?.url)
        XCTAssertNil(testPerformerOverrider.connectAsyncCalledWithCompletionHandler)
        testPerformerOverrider.reset()
        
        NetworkService.shared.connectAsync(networkRequest: request3)
        XCTAssertEqual(request3.url, testPerformerOverrider.connectAsyncCalledWithNetworkRequest?.url)
        XCTAssertNil(testPerformerOverrider.connectAsyncCalledWithCompletionHandler)
    }
    
    func testOverridenConnectAsync_calledOnlyWhenShouldOverride_whenMultipleRequests() {
        let testPerformerOverrider = MockPerformerOverrider(overrideUrls: [URL(string: "https://test2.com")!])
        
        // test&verify
        NetworkServiceOverrider.shared.enableOverride(with:testPerformerOverrider)
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test1.com")!))
        XCTAssertFalse(testPerformerOverrider.connectAsyncCalled)
        testPerformerOverrider.reset()
        
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test2.com")!))
        XCTAssertEqual("https://test2.com", testPerformerOverrider.connectAsyncCalledWithNetworkRequest?.url.absoluteString)
        XCTAssertNil(testPerformerOverrider.connectAsyncCalledWithCompletionHandler)
        XCTAssertTrue(testPerformerOverrider.connectAsyncCalled)
    }
    
    // TODO: enable for AMSDK-9800
    func disable_testOverridenConnectAsync_addsDefaultHeaders_whenCalledWithHeaders() {
        let testPerformerOverrider = MockPerformerOverrider()
        let request1 = NetworkRequest(url: URL(string: "https://test1.com")!, httpMethod: HttpMethod.post, connectPayload: "test body", httpHeaders: ["Accept": "text/html"], connectTimeout: 2.0, readTimeout: 3.0)
        
        // test&verify
        NetworkServiceOverrider.shared.enableOverride(with:testPerformerOverrider)
        NetworkService.shared.connectAsync(networkRequest: request1)
        XCTAssertTrue(testPerformerOverrider.connectAsyncCalled)
        XCTAssertEqual(3, testPerformerOverrider.connectAsyncCalledWithNetworkRequest?.httpHeaders.count)
        XCTAssertNotNil(testPerformerOverrider.connectAsyncCalledWithNetworkRequest?.httpHeaders["Accept"])
        XCTAssertNotNil(testPerformerOverrider.connectAsyncCalledWithNetworkRequest?.httpHeaders["User-Agent"])
        XCTAssertNotNil(testPerformerOverrider.connectAsyncCalledWithNetworkRequest?.httpHeaders["Accept-Language"])
    }
    
    // TODO: enable for AMSDK-9800
    func disable_testOverridenConnectAsync_addsDefaultHeaders_whenCalledWithoutHeaders() {
        let testPerformerOverrider = MockPerformerOverrider()
        let request1 = NetworkRequest(url: URL(string: "https://test1.com")!)
        
        // test&verify
        NetworkServiceOverrider.shared.enableOverride(with:testPerformerOverrider)
        NetworkService.shared.connectAsync(networkRequest: request1)
        XCTAssertTrue(testPerformerOverrider.connectAsyncCalled)
        XCTAssertEqual(2, testPerformerOverrider.connectAsyncCalledWithNetworkRequest?.httpHeaders.count)
        XCTAssertNotNil(testPerformerOverrider.connectAsyncCalledWithNetworkRequest?.httpHeaders["User-Agent"])
        XCTAssertNotNil(testPerformerOverrider.connectAsyncCalledWithNetworkRequest?.httpHeaders["Accept-Language"])
    }
    
    func testOverridenConnectAsync_doesNotOverrideHeaders_whenCalledWithDefaultHeaders() {
        let testPerformerOverrider = MockPerformerOverrider()
        let request1 = NetworkRequest(url: URL(string: "https://test1.com")!, httpMethod: HttpMethod.get, httpHeaders: ["User-Agent": "test", "Accept-Language": "ro-RO"], connectTimeout: 2.0, readTimeout: 3.0)
        
        // test&verify
        NetworkServiceOverrider.shared.enableOverride(with:testPerformerOverrider)
        NetworkService.shared.connectAsync(networkRequest: request1)
        XCTAssertTrue(testPerformerOverrider.connectAsyncCalled)
        XCTAssertEqual(2, testPerformerOverrider.connectAsyncCalledWithNetworkRequest?.httpHeaders.count)
        XCTAssertEqual("test", testPerformerOverrider.connectAsyncCalledWithNetworkRequest?.httpHeaders["User-Agent"])
        XCTAssertEqual("ro-RO", testPerformerOverrider.connectAsyncCalledWithNetworkRequest?.httpHeaders["Accept-Language"])
    }

    func testReset_disablesOverride_whenCalled() {
        let testPerformerOverrider = MockPerformerOverrider()
        
        // test&verify
        NetworkServiceOverrider.shared.enableOverride(with:testPerformerOverrider)
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test1.com")!))
        XCTAssertTrue(testPerformerOverrider.shouldOverrideCalled)
        XCTAssertTrue(testPerformerOverrider.connectAsyncCalled)
        testPerformerOverrider.reset()
        
        NetworkServiceOverrider.shared.reset()
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test1.com")!))
        XCTAssertFalse(testPerformerOverrider.shouldOverrideCalled)
        XCTAssertFalse(testPerformerOverrider.connectAsyncCalled)
        testPerformerOverrider.reset()
    }
    
    func testEnableOverrideAndReset_work_whenCalledMultipleTimes() {
        let testPerformerOverrider = MockPerformerOverrider()
        
        // test&verify
        // enable overrider
        NetworkServiceOverrider.shared.enableOverride(with:testPerformerOverrider)
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test1.com")!))
        XCTAssertTrue(testPerformerOverrider.shouldOverrideCalled)
        XCTAssertTrue(testPerformerOverrider.connectAsyncCalled)
        testPerformerOverrider.reset()
        
        // disable overrider
        NetworkServiceOverrider.shared.reset()
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test1.com")!))
        XCTAssertFalse(testPerformerOverrider.shouldOverrideCalled)
        XCTAssertFalse(testPerformerOverrider.connectAsyncCalled)
        testPerformerOverrider.reset()
        
        // re-enable overrider
        NetworkServiceOverrider.shared.enableOverride(with:testPerformerOverrider)
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test1.com")!))
        XCTAssertTrue(testPerformerOverrider.shouldOverrideCalled)
        XCTAssertTrue(testPerformerOverrider.connectAsyncCalled)
    }
    
    func testEnableOverride_work_whenCalledWithTwoOverriders() {
        let testPerformerOverrider1 = MockPerformerOverrider(overrideUrls:[URL(string: "https://test1.com")!])
        let testPerformerOverrider2 = MockPerformerOverrider(overrideUrls:[URL(string: "https://test2.com")!])
        let testPerformerOverrider3 = MockPerformerOverrider()
        
        // test&verify
        // set first overrider
        NetworkServiceOverrider.shared.enableOverride(with:testPerformerOverrider1)
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test1.com")!))
        XCTAssertTrue(testPerformerOverrider1.shouldOverrideCalled)
        XCTAssertTrue(testPerformerOverrider1.connectAsyncCalled)
        testPerformerOverrider1.reset()
        
        // set second overrider, the first one should not be called anymore
        NetworkServiceOverrider.shared.enableOverride(with:testPerformerOverrider2)
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test1.com")!))
        XCTAssertTrue(testPerformerOverrider2.shouldOverrideCalled)
        XCTAssertFalse(testPerformerOverrider2.connectAsyncCalled)
        XCTAssertFalse(testPerformerOverrider1.shouldOverrideCalled)
        XCTAssertFalse(testPerformerOverrider1.connectAsyncCalled)
        testPerformerOverrider1.reset()
        testPerformerOverrider2.reset()
        
        // set third overrider, the other two should not be called anymore
        NetworkServiceOverrider.shared.enableOverride(with:testPerformerOverrider3)
        NetworkService.shared.connectAsync(networkRequest: NetworkRequest(url: URL(string: "https://test1.com")!))
        XCTAssertTrue(testPerformerOverrider3.shouldOverrideCalled)
        XCTAssertTrue(testPerformerOverrider3.connectAsyncCalled)
        XCTAssertFalse(testPerformerOverrider1.shouldOverrideCalled)
        XCTAssertFalse(testPerformerOverrider1.connectAsyncCalled)
        XCTAssertFalse(testPerformerOverrider2.shouldOverrideCalled)
        XCTAssertFalse(testPerformerOverrider2.connectAsyncCalled)
    }
}

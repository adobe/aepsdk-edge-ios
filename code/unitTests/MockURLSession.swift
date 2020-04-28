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


import Foundation

class MockURLSession: URLSession {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void

    // Properties that enable us to set exactly what data or error
    // we want our mocked URLSession to return for any request.
    var data: Data?
    var error: Error?
    var dataTaskWithCompletionHandlerCalled:Bool
    var calledWithUrlRequest: URLRequest?
    
    private let mockTask: MockTask
    
    init(data: Data? = nil, urlResponse: URLResponse? = nil, error: Error? = nil) {
        mockTask = MockTask(data: data, urlResponse: urlResponse, error:
            error)
        dataTaskWithCompletionHandlerCalled = false
    }

    override func dataTask(with: URLRequest, completionHandler: @escaping CompletionHandler) -> URLSessionDataTask {
        mockTask.completionHandler = completionHandler
        calledWithUrlRequest = with
        dataTaskWithCompletionHandlerCalled = true
        return mockTask
    }
}

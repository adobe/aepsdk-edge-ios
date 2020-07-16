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

import Foundation

class MockURLSession: URLSession {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void

    // Properties that enable us to set exactly what data or error
    // we want our mocked URLSession to return for any request.
    var data: Data?
    var error: Error?
    var dataTaskWithCompletionHandlerCalled: Bool
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

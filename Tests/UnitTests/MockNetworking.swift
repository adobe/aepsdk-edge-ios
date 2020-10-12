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

@testable import AEPEdge
import AEPServices
import Foundation

class MockNetworking: Networking {

    var connectAsyncCalled: Bool = false
    var connectAsyncCalledWithNetworkRequest: NetworkRequest?
    var connectAsyncCalledWithCompletionHandler: ((HttpConnection) -> Void)?
    var connectAsyncMockReturnConnection: HttpConnection = HttpConnection(data: "{}".data(using: .utf8), response: nil, error: nil)

    func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        print("Do nothing \(networkRequest)")
        connectAsyncCalled = true
        connectAsyncCalledWithNetworkRequest = networkRequest
        connectAsyncCalledWithCompletionHandler = completionHandler
        guard let unwrappedCompletionHandler = completionHandler else { return }
        unwrappedCompletionHandler(connectAsyncMockReturnConnection)
    }

    func reset() {
        connectAsyncCalled = false
        connectAsyncCalledWithNetworkRequest = nil
        connectAsyncCalledWithCompletionHandler = nil
    }
}

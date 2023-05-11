//
// Copyright 2023 Adobe. All rights reserved.
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
@testable import AEPServices
import Foundation
import XCTest

/// Overriding NetworkService used for functional tests when extending the TestBase
class MockTestNetworkService: TestNetworkService {
    private var delayedResponse: UInt32 = 0

    override func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        recordSentNetworkRequest(networkRequest)
        self.countDownExpected(networkRequest: networkRequest)
        guard let unwrappedCompletionHandler = completionHandler else { return }
        
        if self.delayedResponse > 0 {
            sleep(self.delayedResponse)
        }
        
        if let response = self.getMockResponsesFor(networkRequest: networkRequest).first {
            unwrappedCompletionHandler(response)
        } else {
            // Default mock response
            unwrappedCompletionHandler(
                HttpConnection(
                    data: "".data(using: .utf8),
                    response: HTTPURLResponse(url: networkRequest.url,
                                              statusCode: 200,
                                              httpVersion: nil,
                                              headerFields: nil),
                    error: nil)
            )
        }
    }
    
    override func reset() {
        delayedResponse = 0
        super.reset()
    }

    /// Sets the provided delay for all network responses, until reset
    /// - Parameter delaySec: delay in seconds
    func enableNetworkResponseDelay(delaySec: UInt32) {
        delayedResponse = delaySec
    }

    /// Sets the mock `HttpConnection` response connection for a given `NetworkRequest`. Should only be used
    /// when in mock mode.
    ///
    /// - Returns: `true` if the response was successfully set.
    func setMockResponseFor(networkRequest: NetworkRequest, response: HttpConnection?) {
        setResponseFor(networkRequest: networkRequest, responseConnection: response)
    }
    
    /// Sets the mock `HttpConnection` response connection for a given `NetworkRequest`. Should only be used
    /// when in mock mode.
    ///
    /// - Returns: `true` if the response was successfully set.
    func setMockResponseFor(url: String, httpMethod: HttpMethod, response: HttpConnection?) {
        guard let networkRequest = NetworkRequest(urlString: url, httpMethod: httpMethod) else {
            return
        }
        setResponseFor(networkRequest: networkRequest, responseConnection: response)
    }
    
    // MARK: Network request response helpers
    func getMockResponsesFor(networkRequest: NetworkRequest) -> [HttpConnection] {
        return networkResponses
            .filter { areNetworkRequestsEqual(lhs: $0.key, rhs: networkRequest) }
            .map { $0.value }
    }
}

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

@testable import AEPServices
import Foundation
import XCTest

/// `Networking` adhering network service utility used for tests that require mocked network requests and mocked responses
class MockNetworkService: Networking {
    private let helper: NetworkRequestHelper = NetworkRequestHelper()
    private var responseDelay: UInt32 = 0

    func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        helper.recordSentNetworkRequest(networkRequest)
        self.helper.countDownExpected(networkRequest: networkRequest)
        guard let unwrappedCompletionHandler = completionHandler else { return }

        if self.responseDelay > 0 {
            sleep(self.responseDelay)
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

    func reset() {
        responseDelay = 0
        helper.reset()
    }

    /// Sets the provided delay for all network responses, until reset
    /// - Parameter delaySec: delay in seconds
    func enableNetworkResponseDelay(timeInSeconds: UInt32) {
        responseDelay = timeInSeconds
    }

    /// Sets the mock `HttpConnection` response connection for a given `NetworkRequest`. Should only be used
    /// when in mock mode.
    func setMockResponseFor(networkRequest: NetworkRequest, responseConnection: HttpConnection?) {
        helper.setResponseFor(networkRequest: networkRequest, responseConnection: responseConnection)
    }

    /// Sets the mock `HttpConnection` response connection for a given `NetworkRequest`. Should only be used
    /// when in mock mode.
    func setMockResponseFor(url: String, httpMethod: HttpMethod, responseConnection: HttpConnection?) {
        guard let networkRequest = NetworkRequest(urlString: url, httpMethod: httpMethod) else {
            return
        }
        helper.setResponseFor(networkRequest: networkRequest, responseConnection: responseConnection)
    }

    // MARK: - Passthrough for shared helper APIs

    /// Set the expected number of times a `NetworkRequest` should be seen.
    ///
    /// - Parameters:
    ///   - url: the URL string of the `NetworkRequest` to set the expectation for
    ///   - httpMethod: the `HttpMethod` of the `NetworkRequest` to set the expectation for
    ///   - expectedCount: how many times a request with this url and httpMethod is expected to be sent, by default it is set to 1
    func setExpectationForNetworkRequest(url: String, httpMethod: HttpMethod, expectedCount: Int32 = 1, file: StaticString = #file, line: UInt = #line) {
        guard let networkRequest = NetworkRequest(urlString: url, httpMethod: httpMethod) else {
            return
        }
        helper.setExpectationForNetworkRequest(networkRequest: networkRequest, expectedCount: expectedCount, file: file, line: line)
    }

    func assertAllNetworkRequestExpectations(file: StaticString = #file, line: UInt = #line) {
        helper.assertAllNetworkRequestExpectations(file: file, line: line)
    }

    func getNetworkRequestsWith(url: String, httpMethod: HttpMethod, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [NetworkRequest] {
        helper.getNetworkRequestsWith(url: url, httpMethod: httpMethod, timeout: timeout, file: file, line: line)
    }

    // MARK: - Private helpers
    // MARK: Network request response helpers
    private func getMockResponsesFor(networkRequest: NetworkRequest) -> [HttpConnection] {
        return helper.getResponsesFor(networkRequest: networkRequest)
    }
}

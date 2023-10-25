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

/// `Networking` conforming network service utility used for tests that require mocked network requests and mocked responses
class MockNetworkService: Networking {
    private let helper: NetworkRequestHelper = NetworkRequestHelper()
    private var responseDelay: UInt32 = 0

    func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        if self.responseDelay > 0 {
            sleep(self.responseDelay)
        }

        if let response = self.getMockResponse(for: networkRequest) {
            completionHandler?(response)
        } else {
            // Default mock response
            completionHandler?(
                HttpConnection(
                    data: "".data(using: .utf8),
                    response: HTTPURLResponse(
                        url: networkRequest.url,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    ),
                    error: nil
                )
            )
        }
        // Do these countdown after notifying completion handler to avoid prematurely ungating awaits
        // before required network logic finishes
        helper.recordSentNetworkRequest(networkRequest)
        helper.countDownExpected(networkRequest: networkRequest)
    }

    func reset() {
        responseDelay = 0
        helper.reset()
    }

    /// Sets the provided delay for all network responses, until reset.
    /// - Parameter delaySec: delay in seconds
    /// - SeeAlso: ``reset()``
    func enableNetworkResponseDelay(timeInSeconds: UInt32) {
        responseDelay = timeInSeconds
    }

    /// Sets a mock network response for the provided network request.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest`for which the mock response is being set.
    ///   - responseConnection: The `HttpConnection` to set as a response. If `nil` is provided, a default HTTP status code `200` response is used.
    func setMockResponse(for networkRequest: NetworkRequest, responseConnection: HttpConnection) {
        helper.removeAllResponses(for: networkRequest)
        helper.addResponse(for: networkRequest, responseConnection: responseConnection)
    }

    /// Sets a mock network response for the provided network request.
    ///
    /// - Parameters:
    ///   - url: The URL `String` of the `NetworkRequest` for which the mock response is being set.
    ///   - httpMethod: The HTTP method of the `NetworkRequest` for which the mock response is being set.
    ///   - responseConnection: The `HttpConnection` to set as a response. If `nil` is provided, a default HTTP status code `200` response is used.
    func setMockResponse(url: String, httpMethod: HttpMethod, responseConnection: HttpConnection) {
        guard let networkRequest = NetworkRequest(urlString: url, httpMethod: httpMethod) else {
            return
        }
        setMockResponse(for: networkRequest, responseConnection: responseConnection)
    }

    // MARK: - Passthrough for shared helper APIs

    /// Sets the expected number of times a network request should be sent.
    ///
    /// - Parameters:
    ///   - url: The URL `String` of the `NetworkRequest` for which the expectation is set.
    ///   - httpMethod: The HTTP method of the `NetworkRequest` for which the expectation is set.
    ///   - expectedCount: The number of times the request is expected to be sent. The default value is 1.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func setExpectationForNetworkRequest(url: String, httpMethod: HttpMethod, expectedCount: Int32 = 1, file: StaticString = #file, line: UInt = #line) {
        guard let networkRequest = NetworkRequest(urlString: url, httpMethod: httpMethod) else {
            return
        }
        helper.setExpectation(for: networkRequest, expectedCount: expectedCount, file: file, line: line)
    }

    /// Asserts that the correct number of network requests were seen for all previously set network request expectations.
    /// - Parameters:
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - SeeAlso:
    ///     - ``setExpectationForNetworkRequest(url:httpMethod:expectedCount:file:line:)``
    func assertAllNetworkRequestExpectations(file: StaticString = #file, line: UInt = #line) {
        helper.assertAllNetworkRequestExpectations(file: file, line: line)
    }

    /// Returns the network request(s) sent through the Core NetworkService, or empty if none was found.
    ///
    /// Use this method after calling `setExpectationForNetworkRequest(url:httpMethod:expectedCount:file:line:)` to wait for expected requests.
    ///
    /// - Parameters:
    ///   - url: The URL `String` of the `NetworkRequest` to get.
    ///   - httpMethod: The HTTP method of the `NetworkRequest` to get.
    ///   - expectationTimeout: The duration (in seconds) to wait for **expected network requests** before failing, with a default of ``WAIT_NETWORK_REQUEST_TIMEOUT``. Otherwise waits for ``WAIT_TIMEOUT`` without failing.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - Returns: An array of `NetworkRequest`s that match the provided `url` and `httpMethod`. Returns an empty array if no matching requests were dispatched.
    ///
    /// - SeeAlso:
    ///     - ``setExpectationForNetworkRequest(url:httpMethod:expectedCount:file:line:)``
    func getNetworkRequestsWith(url: String, httpMethod: HttpMethod, expectationTimeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [NetworkRequest] {
        helper.getNetworkRequestsWith(url: url, httpMethod: httpMethod, expectationTimeout: expectationTimeout, file: file, line: line)
    }

    // MARK: - Private helpers
    // MARK: Network request response helpers
    private func getMockResponse(for networkRequest: NetworkRequest) -> HttpConnection? {
        return helper.getResponses(for: networkRequest)?.first
    }
}

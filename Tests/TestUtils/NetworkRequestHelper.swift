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

@testable import AEPServices
import Foundation
import XCTest

/// Implements shared utilities and logic for `NetworkService`/`Networking` class implementations
/// used for testing.
///
/// - See also:
///    - ``MockNetworkService``
///    - ``RealNetworkService``
class NetworkRequestHelper {
    private var sentNetworkRequests: [NetworkRequest: [NetworkRequest]] = [:]
    /// Matches sent `NetworkRequest`s with their corresponding `HttpConnection` response.
    private(set) var networkResponses: [NetworkRequest: HttpConnection] = [:]
    private var expectedNetworkRequests: [NetworkRequest: CountDownLatch] = [:]

    func recordSentNetworkRequest(_ networkRequest: NetworkRequest) {
        TestBase.log("Received connectAsync to URL \(networkRequest.url.absoluteString) and HTTPMethod \(networkRequest.httpMethod.toString())")
        if let equalNetworkRequest = sentNetworkRequests.first(where: { key, _ in
            networkRequest.isCustomEqual(key)
        }) {
            sentNetworkRequests[equalNetworkRequest.key]!.append(networkRequest)
        } else {
            sentNetworkRequests[networkRequest] = [networkRequest]
        }
    }

    func reset() {
        expectedNetworkRequests.removeAll()
        sentNetworkRequests.removeAll()
        networkResponses.removeAll()
    }

    func countDownExpected(networkRequest: NetworkRequest) {
        for expectedNetworkRequest in expectedNetworkRequests {
            if networkRequest.isCustomEqual(expectedNetworkRequest.key) {
                expectedNetworkRequest.value.countDown()
            }
        }
    }

    /// Starts the deadline timer for the given `NetworkRequest`, requiring all of its expected responses to have completed before the allotted time given in `timeout`.
    ///
    /// Note that it only sets the timer for the first `NetworkRequest` instance satisfying `areNetworkRequestsEqual`, using a dictionary backing.
    /// This method is not recommended for instances where:
    /// 1. Mutliple `NetworkRequest` instances would satisfy `areNetworkRequestsEqual` and all of them need the deadline timer started
    /// 2. Order of the deadline timer application is important
    private func awaitFor(networkRequest: NetworkRequest, timeout: TimeInterval) -> DispatchTimeoutResult? {
        for expectedNetworkRequest in expectedNetworkRequests {
            if networkRequest.isCustomEqual(expectedNetworkRequest.key) {
                return expectedNetworkRequest.value.await(timeout: timeout)
            }
        }

        return nil
    }

    /// Returns all of the original outgoing `NetworkRequest`s satisfying `NetworkRequest.isCustomEqual(_:)`.
    func getSentNetworkRequestsMatching(networkRequest: NetworkRequest) -> [NetworkRequest] {
        for request in sentNetworkRequests {
            if networkRequest.isCustomEqual(request.key) {
                return request.value
            }
        }

        return []
    }

    // MARK: - Network response helpers
    /// Sets the `HttpConnection` response connection for a given `NetworkRequest`
    func setResponseFor(networkRequest: NetworkRequest, responseConnection: HttpConnection?) {
        networkResponses[networkRequest] = responseConnection
    }

    /// Gets all network responses for `NetworkRequest`s matching the given `NetworkRequest`
    ///
    /// See:
    func getResponsesFor(networkRequest: NetworkRequest) -> [HttpConnection] {
        return networkResponses
            .filter { networkRequest.isCustomEqual($0.key) }
            .map { $0.value }
    }

    // MARK: Assertion helpers

    /// Set the expected number of times a `NetworkRequest` should be seen.
    ///
    /// - Parameters:
    ///   - networkRequest: the `NetworkRequest` to set the expectation for
    ///   - expectedCount: how many times a request with this url and httpMethod is expected to be sent, by default it is set to 1
    func setExpectationForNetworkRequest(networkRequest: NetworkRequest, expectedCount: Int32 = 1, file: StaticString = #file, line: UInt = #line) {
        guard expectedCount > 0 else {
            assertionFailure("Expected event count should be greater than 0")
            return
        }

        expectedNetworkRequests[networkRequest] = CountDownLatch(expectedCount)
    }

    /// For all previously set expections, asserts that the correct number of network requests were sent.
    /// - See also:
    ///     - `setExpectationNetworkRequest(url:httpMethod:)`
    func assertAllNetworkRequestExpectations(file: StaticString = #file, line: UInt = #line) {
        guard !expectedNetworkRequests.isEmpty else {
            assertionFailure("There are no network request expectations set, use this API after calling setExpectationNetworkRequest")
            return
        }

        for expectedRequest in expectedNetworkRequests {
            let waitResult = expectedRequest.value.await(timeout: 10)
            let expectedCount: Int32 = expectedRequest.value.getInitialCount()
            let receivedCount: Int32 = expectedRequest.value.getInitialCount() - expectedRequest.value.getCurrentCount()
            XCTAssertFalse(waitResult == DispatchTimeoutResult.timedOut, "Timed out waiting for network request(s) with URL \(expectedRequest.key.url.absoluteString) and HTTPMethod \(expectedRequest.key.httpMethod.toString()), expected \(expectedCount) but received \(receivedCount)", file: file, line: line)
            XCTAssertEqual(expectedCount, receivedCount, "Expected \(expectedCount) network request(s) for URL \(expectedRequest.key.url.absoluteString) and HTTPMethod \(expectedRequest.key.httpMethod.toString()), but received \(receivedCount)", file: file, line: line)
        }
    }

    /// Returns the `NetworkRequest`(s) sent through the Core NetworkService, or empty if none was found.
    /// Use this API after calling `setExpectationNetworkRequest(url:httpMethod:count:)` to wait for the right amount of time
    /// - Parameters:
    ///   - url: The URL for which to retrieved the network requests sent, should be a valid URL
    ///   - httpMethod: the `HttpMethod` for which to retrieve the network requests, along with the `url`
    ///   - timeout: how long should this method wait for the expected network requests, in seconds; by default it waits up to 1 second
    /// - Returns: list of network requests with the provided `url` and `httpMethod`, or empty if none was dispatched
    /// - See also:
    ///     - setExpectationNetworkRequest(url:httpMethod:)
    func getNetworkRequestsWith(url: String, httpMethod: HttpMethod, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [NetworkRequest] {
        guard let networkRequest = NetworkRequest(urlString: url, httpMethod: httpMethod) else {
            return []
        }

        awaitRequest(networkRequest, timeout: timeout)

        return getSentNetworkRequestsMatching(networkRequest: networkRequest)
    }

    func awaitRequest(_ networkRequest: NetworkRequest, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) {

        if let waitResult = awaitFor(networkRequest: networkRequest, timeout: timeout) {
            XCTAssertFalse(waitResult == DispatchTimeoutResult.timedOut, "Timed out waiting for network request(s) with URL \(networkRequest.url) and HTTPMethod \(networkRequest.httpMethod.toString())", file: file, line: line)
        } else {
            wait(TestConstants.Defaults.WAIT_TIMEOUT)
        }
    }

    /// - Parameters:
    ///   - timeout:how long should this method wait, in seconds; by default it waits up to 1 second
    func wait(_ timeout: UInt32? = TestConstants.Defaults.WAIT_TIMEOUT) {
        if let timeout = timeout {
            sleep(timeout)
        }
    }
}

extension URL {
    func queryParam(_ param: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
}

extension NetworkRequest {
    convenience init?(urlString: String, httpMethod: HttpMethod) {
        guard let url = URL(string: urlString) else {
            assertionFailure("Unable to convert the provided string \(urlString) to URL")
            return nil
        }
        self.init(url: url, httpMethod: httpMethod)
    }

    /// Custom equals compare based on host, scheme and URL path. Query params are not taken into consideration.
    func isCustomEqual(_ other: NetworkRequest) -> Bool { // Maybe isCustomEqual?
        return self.url.host?.lowercased() == other.url.host?.lowercased()
            && self.url.scheme?.lowercased() == other.url.scheme?.lowercased()
            && self.url.path.lowercased() == other.url.path.lowercased()
            && self.httpMethod.rawValue == other.httpMethod.rawValue
    }

    /// Converts the `connectPayload` into a flattened dictionary containing its data.
    /// This API fails the assertion if the request body cannot be parsed as JSON.
    /// - Returns: The JSON request body represented as a flattened dictionary
    func getFlattenedBody(file: StaticString = #file, line: UInt = #line) -> [String: Any] {
        if !self.connectPayload.isEmpty {
            if let payloadAsDictionary = try? JSONSerialization.jsonObject(with: self.connectPayload, options: []) as? [String: Any] {
                return flattenDictionary(dict: payloadAsDictionary)
            } else {
                XCTFail("Failed to parse networkRequest.connectionPayload to JSON", file: file, line: line)
            }
        }

        print("Connection payload is empty for network request with URL \(self.url.absoluteString), HTTPMethod \(self.httpMethod.toString())")
        return [:]
    }
}

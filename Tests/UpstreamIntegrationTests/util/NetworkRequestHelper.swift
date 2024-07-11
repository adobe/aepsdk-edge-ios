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
    private let queue: DispatchQueue = .init(label: "com.adobe.testutils.networkrequesthelper.queue")

    private var _orderedNetworkRequests: [NetworkRequest] = []
    /// Matches sent `NetworkRequest`s with their corresponding `HttpConnection` responses.
    private var _networkResponses: [TestableNetworkRequest: [HttpConnection]] = [:]

    private var sentNetworkRequests: [TestableNetworkRequest: [NetworkRequest]] = [:]
    private var expectedNetworkRequests: [TestableNetworkRequest: CountDownLatch] = [:]

    var orderedNetworkRequests: [NetworkRequest] {
        return queue.sync {
            return _orderedNetworkRequests.map { $0.deepCopy() }
        }
    }

    var networkResponses: [TestableNetworkRequest: [HttpConnection]] {
        return queue.sync {
            return _networkResponses.mapValues { value in
                return value.map { $0.deepCopy() }
            }
        }
    }

    func recordSentNetworkRequest(_ networkRequest: NetworkRequest) {
        print("Received connectAsync to URL \(networkRequest.url.absoluteString) and HTTPMethod \(networkRequest.httpMethod.toString())")

        queue.async { [weak self] in

            guard let self = self else { return }
            // Add to ordered list
            _orderedNetworkRequests.append(networkRequest)

            // Add to grouped collection
            let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)
            if let equalNetworkRequest = sentNetworkRequests.first(where: { key, _ in
                key == testableNetworkRequest
            }) {
                sentNetworkRequests[equalNetworkRequest.key]?.append(networkRequest)
            } else {
                sentNetworkRequests[testableNetworkRequest] = [networkRequest]
            }
        }
    }

    func reset() {
        queue.async { [weak self] in

            guard let self = self else { return }

            _orderedNetworkRequests.removeAll()
            _networkResponses.removeAll()
            expectedNetworkRequests.removeAll()
            sentNetworkRequests.removeAll()
        }
    }

    /// Decrements the expectation count for a given network request.
    ///
    /// - Parameter networkRequest: The `NetworkRequest` for which the expectation count should be decremented.
    func countDownExpected(networkRequest: NetworkRequest) {
        queue.async { [weak self] in

            guard let self = self else { return }

            for expectedNetworkRequest in expectedNetworkRequests where expectedNetworkRequest.key == TestableNetworkRequest(from: networkRequest) {
                expectedNetworkRequest.value.countDown()
            }
        }

//        for expectedNetworkRequest in expectedNetworkRequests where expectedNetworkRequest.key == TestableNetworkRequest(from: networkRequest) {
//            expectedNetworkRequest.value.countDown()
//        }
    }

    /// Starts the expectation timer for the given network request, validating that all expected responses are received within
    /// the provided `timeout` duration.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest` for which the expectation timer should be started.
    ///   - timeout: The maximum duration (in seconds) to wait for the expected responses before timing out.
    ///
    /// - Returns: A `DispatchTimeoutResult` with the result of the wait operation, or `nil` if the `NetworkRequest` does not match any expected request.
    private func awaitFor(networkRequest: NetworkRequest, timeout: TimeInterval) -> DispatchTimeoutResult? {
        queue.sync {
            for expectedNetworkRequest in expectedNetworkRequests where expectedNetworkRequest.key == TestableNetworkRequest(from: networkRequest) {
                return expectedNetworkRequest.value.await(timeout: timeout)
            }

            return nil
        }
    }

    ///  Returns all sent network requests that match the provided network request using the
    ///  `TestableNetworkRequest.isEqual(_:)` method.
    ///
    /// - Parameter networkRequest: The `NetworkRequest` for which to get matching requests.
    ///
    /// - Returns: An array of `NetworkRequest`s that match the specified `networkRequest`. If no matches are found, an empty array is returned.
    func getSentRequests(matching networkRequest: NetworkRequest) -> [NetworkRequest] {
        queue.sync {
            for request in sentNetworkRequests where request.key == TestableNetworkRequest(from: networkRequest) {
                return request.value
            }

            return []
        }
    }

    // MARK: - Network response helpers
    /// Adds a network response for the provided network request.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest`for which the response is being set.
    ///   - responseConnection: The `HttpConnection` to set as a response.
    func addResponse(for networkRequest: NetworkRequest, responseConnection: HttpConnection) {
        let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)

        queue.sync {
            if _networkResponses[testableNetworkRequest] != nil {
                _networkResponses[testableNetworkRequest]?.append(responseConnection)
            } else {
                _networkResponses[testableNetworkRequest] = [responseConnection]
            }
        }

    }

    /// Removes all network responses for the provided network request.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest` for which to remove all responses.
    func removeAllResponses(for networkRequest: NetworkRequest) {
        queue.async { [weak self] in

            guard let self = self else { return }

            let testableNetworkRequest = TestableNetworkRequest(from: networkRequest)
            _networkResponses[testableNetworkRequest] = nil
        }
    }

    /// Returns the network responses associated with the given network request.
    ///
    /// - Parameter networkRequest: The `NetworkRequest` for which the response should be retrieved.
    /// - Returns: The array of `HttpConnection` responses associated with the provided `NetworkRequest`, or `nil` if no response was found.
    func getResponses(for networkRequest: NetworkRequest) -> [HttpConnection]? {
        queue.sync {
            return _networkResponses[TestableNetworkRequest(from: networkRequest)]?.map { $0.deepCopy() }
        }
    }

    // MARK: Assertion helpers

    /// Sets the expected number of times a network request should be sent.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest` for which the expectation is set.
    ///   - expectedCount: The number of times the request is expected to be sent. The default value is 1.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func setExpectation(for networkRequest: NetworkRequest, expectedCount: Int32 = 1, file: StaticString = #file, line: UInt = #line) {
        guard expectedCount > 0 else {
            assertionFailure("Expected event count should be greater than 0", file: file, line: line)
            return
        }

        queue.sync {
            expectedNetworkRequests[TestableNetworkRequest(from: networkRequest)] = CountDownLatch(expectedCount)
        }
    }

    /// Asserts that the correct number of network requests were seen for all previously set network request expectations.
    /// - Parameters:
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - SeeAlso:
    ///     - ``setExpectationForNetworkRequest(url:httpMethod:)``
    func assertAllNetworkRequestExpectations(ignoreUnexpectedRequests: Bool = true, file: StaticString = #file, line: UInt = #line) {
        if expectedNetworkRequests.isEmpty {
            if !ignoreUnexpectedRequests {
                assertUnexpectedRequests(file: file, line: line)
            }
            return
        }

        for expectedRequest in expectedNetworkRequests {
            let waitResult = expectedRequest.value.await(timeout: 30)
            let expectedCount: Int32 = expectedRequest.value.getInitialCount()
            let receivedCount: Int32 = expectedRequest.value.getInitialCount() - expectedRequest.value.getCurrentCount()

                XCTAssertFalse(waitResult == DispatchTimeoutResult.timedOut,
                               """
                           Timed out waiting for network request(s) with URL \(expectedRequest.key.url.absoluteString) and HTTPMethod
                           \(expectedRequest.key.httpMethod.toString()), expected \(expectedCount) but received \(receivedCount)
                           """,
                               file: file,
                               line: line)

                XCTAssertEqual(expectedCount,
                               receivedCount,
                               """
                           Expected \(expectedCount) network request(s) for URL \(expectedRequest.key.url.absoluteString) and HTTPMethod
                           \(expectedRequest.key.httpMethod.toString()), but received \(receivedCount)
                           """,
                               file: file,
                               line: line)
        }
        if ignoreUnexpectedRequests { return }
        assertUnexpectedRequests()
    }

    func assertUnexpectedRequests(file: StaticString = #file, line: UInt = #line) {
        var unexpectedRequestsCount = 0
        var unexpectedRequestsAsString = ""
        queue.sync {

            for (sentRequest, requests) in sentNetworkRequests {
                let sentRequestURL = sentRequest.url.absoluteString
                let sentRequestHTTPMethod = sentRequest.httpMethod.toString()
                // Check if request is expected and it is over the expected count
                if let expectedRequest = expectedNetworkRequests[sentRequest] {
                    _ = expectedRequest.await(timeout: TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT)
                    let expectedCount: Int32 = expectedRequest.getInitialCount()
                    let receivedCount: Int32 = expectedRequest.getInitialCount() - expectedRequest.getCurrentCount()
                    XCTAssertEqual(expectedCount,
                                   receivedCount,
                                   """
                               Expected \(expectedCount) network request(s) for URL \(sentRequestURL) and HTTPMethod \(sentRequestHTTPMethod),
                               but received \(receivedCount)
                               """,
                                   file: file,
                                   line: line)
                }
                // Check for requests that don't have expectations set
                else {
                    unexpectedRequestsCount += requests.count
                    unexpectedRequestsAsString.append("(\(sentRequestURL), \(sentRequestHTTPMethod), \(requests.count)),")
                    print("NetworkRequestHelper - Received unexpected network request with URL: \(sentRequestURL) and HTTPMethod: \(sentRequestHTTPMethod)")
                }
            }

            XCTAssertEqual(0,
                           unexpectedRequestsCount,
                           """
                       Received \(unexpectedRequestsCount) unexpected network request(s): \(unexpectedRequestsAsString)
                       """,
                           file: file,
                           line: line)
        }
    }

    /// Returns the network request(s) sent through the Core NetworkService, or empty if none was found.
    ///
    /// Use this method after calling `setExpectationForNetworkRequest(networkRequest:expectedCount:file:line:)` to wait for expected requests.
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
    ///     - ``setExpectationForNetworkRequest(networkRequest:expectedCount:file:line:)``
    func getNetworkRequestsWith(url: String, httpMethod: HttpMethod, expectationTimeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [NetworkRequest] {
        guard let url = URL(string: url) else {
            return []
        }

        return getNetworkRequestsWith(url: url, httpMethod: httpMethod, expectationTimeout: expectationTimeout, file: file, line: line)
    }

    /// Returns the network request(s) sent through the Core NetworkService, or empty if none was found.
    ///
    /// Use this method after calling `setExpectationForNetworkRequest(networkRequest:expectedCount:file:line:)` to wait for expected requests.
    ///
    /// - Parameters:
    ///   - url: The `URL` of the `NetworkRequest` to get.
    ///   - httpMethod: The HTTP method of the `NetworkRequest` to get.
    ///   - expectationTimeout: The duration (in seconds) to wait for **expected network requests** before failing, with a default of ``WAIT_NETWORK_REQUEST_TIMEOUT``. Otherwise waits for ``WAIT_TIMEOUT`` without failing.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - Returns: An array of `NetworkRequest`s that match the provided `url` and `httpMethod`. Returns an empty array if no matching requests were dispatched.
    ///
    /// - SeeAlso:
    ///     - ``setExpectationForNetworkRequest(networkRequest:expectedCount:file:line:)``
    func getNetworkRequestsWith(url: URL, httpMethod: HttpMethod, expectationTimeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [NetworkRequest] {
        let networkRequest = NetworkRequest(url: url, httpMethod: httpMethod)

        awaitRequest(networkRequest, expectationTimeout: expectationTimeout)

        return getSentRequests(matching: networkRequest)
    }

    /// Waits for a specific network request expectation to be fulfilled within the provided timeout interval.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest` to await.
    ///   - expectationTimeout: The duration (in seconds) to wait for **expected network requests** before failing, with a default of ``WAIT_NETWORK_REQUEST_TIMEOUT``. Otherwise waits for ``WAIT_TIMEOUT`` without failing.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    private func awaitRequest(_ networkRequest: NetworkRequest, expectationTimeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) {

        if let waitResult = awaitFor(networkRequest: networkRequest, timeout: expectationTimeout) {
            XCTAssertFalse(waitResult == DispatchTimeoutResult.timedOut,
                           """
                           Timed out waiting for network request(s) with URL \(networkRequest.url)
                           and HTTPMethod \(networkRequest.httpMethod.toString())
                           """,
                           file: file,
                           line: line)
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

public extension NetworkRequest {
    convenience init?(urlString: String, httpMethod: HttpMethod) {
        guard let url = URL(string: urlString) else {
            assertionFailure("Unable to convert the provided string \(urlString) to URL")
            return nil
        }
        self.init(url: url, httpMethod: httpMethod)
    }

    /// Converts the `connectPayload` into a flattened dictionary containing its data.
    /// This API fails the assertion if the request body cannot be parsed as JSON.
    /// - Returns: The JSON request body represented as a flattened dictionary
//    func getFlattenedBody(file: StaticString = #file, line: UInt = #line) -> [String: Any] {
//        if !self.connectPayload.isEmpty {
//            if let payloadAsDictionary = try? JSONSerialization.jsonObject(with: self.connectPayload, options: []) as? [String: Any] {
//                return flattenDictionary(dict: payloadAsDictionary)
//            } else {
//                XCTFail("Failed to parse networkRequest.connectionPayload to JSON", file: file, line: line)
//            }
//        }
//
//        print("Connection payload is empty for network request with URL \(self.url.absoluteString), HTTPMethod \(self.httpMethod.toString())")
//        return [:]
//    }
}

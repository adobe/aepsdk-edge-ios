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
@testable import AEPServices
import Foundation
import XCTest

/// Overriding NetworkService used for functional tests when extending the TestBase
class FunctionalTestNetworkService: NetworkService {
    private var mockNetworkService: Bool
    private var receivedNetworkRequests: [NetworkRequest: [NetworkRequest]] = [:]
    /// Matches outgoing `NetworkRequest`s with their corresponding `HttpConnection` response.
    /// Mock or real server response controlled by `mockNetworkService`
    /// Mocked `HttpConnection` response can be set using `setResponseConnectionFor(networkRequest:responseConnection:)`
    private var networkResponses: [NetworkRequest: HttpConnection] = [:]
    private var expectedNetworkRequests: [NetworkRequest: CountDownLatch] = [:]
    private var delayedResponse: UInt32 = 0
    
    init(mockNetworkService: Bool) {
        self.mockNetworkService = mockNetworkService
        super.init()
    }

    override func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        TestBase.log("Received connectAsync to URL \(networkRequest.url.absoluteString) and HTTPMethod \(networkRequest.httpMethod.toString())")
        if var requests = receivedNetworkRequests[networkRequest] {
            requests.append(networkRequest)
            receivedNetworkRequests[networkRequest] = requests
        } else {
            receivedNetworkRequests[networkRequest] = [networkRequest]
        }

        // Using mocked reponses to network requests
        if mockNetworkService {
            countDownExpected(networkRequest: networkRequest)
            guard let unwrappedCompletionHandler = completionHandler else { return }
            
            if delayedResponse > 0 {
                sleep(delayedResponse)
            }
            
            if let response = getResponsesFor(networkRequest: networkRequest).first {
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
        // Using real network requests and receiving real responses
        else {
            super.connectAsync(networkRequest: networkRequest, completionHandler: { (connection: HttpConnection) in
                self.setResponseFor(networkRequest: networkRequest, responseConnection: connection)
                self.countDownExpected(networkRequest: networkRequest)
                    
                // Finally call the original completion handler
                completionHandler?(connection)
            })
            return
        }
    }

    func enableDelayedResponse(delaySec: UInt32) {
        delayedResponse = delaySec
    }

    func reset() {
        expectedNetworkRequests.removeAll()
        receivedNetworkRequests.removeAll()
        networkResponses.removeAll()
        delayedResponse = 0
    }

    /// Starts the deadline timer for the given `NetworkRequest`, requiring all of its expected responses to have completed before the allotted time given in `timeout`.
    ///
    /// Note that it only sets the timer for the first `NetworkRequest` instance satisfying `areNetworkRequestsEqual`, using a dictionary backing.
    /// This method is not recommended for instances where:
    /// 1. Mutliple `NetworkRequest` instances would satisfy `areNetworkRequestsEqual` and all of them need the deadline timer started
    /// 2. Order of the deadline timer application is important
    func awaitFor(networkRequest: NetworkRequest, timeout: TimeInterval) -> DispatchTimeoutResult? {
        for expectedNetworkRequest in expectedNetworkRequests {
            if areNetworkRequestsEqual(lhs: expectedNetworkRequest.key, rhs: networkRequest) {
                return expectedNetworkRequest.value.await(timeout: timeout)
            }
        }

        return nil
    }

    /// Returns all of the original outgoing `NetworkRequest`s for received network responses, satisfying `areNetworkRequestsEqual`.
    func getReceivedNetworkRequestKeysMatching(networkRequest: NetworkRequest) -> [NetworkRequest] {
        var matchingRequests: [NetworkRequest] = []
        for receivedRequest in receivedNetworkRequests {
            if areNetworkRequestsEqual(lhs: receivedRequest.key, rhs: networkRequest) {
                matchingRequests.append(receivedRequest.key)
            }
        }

        return matchingRequests
    }

    /// Sets the number of times a NetworkRequest is expected to be seen
    func setExpectedNetworkRequest(networkRequest: NetworkRequest, count: Int32) {
        expectedNetworkRequests[networkRequest] = CountDownLatch(count)
    }

    func getExpectedNetworkRequests() -> [NetworkRequest: CountDownLatch] {
        return expectedNetworkRequests
    }

    /// Sets the mock `HttpConnection` response connection for a given `NetworkRequest`. Should only be used
    /// when in mock mode.
    ///
    /// - Returns: `true` if the response was successfully set.
    func setMockResponseFor(networkRequest: NetworkRequest, response: HttpConnection?) {
        guard mockNetworkService else {
            XCTFail("Setting mock responses when not in mock network service mode is not allowed.")
            return
        }
        setResponseFor(networkRequest: networkRequest, responseConnection: response)
    }
    
    // MARK: Network request response helpers
    func getResponsesFor(networkRequest: NetworkRequest) -> [HttpConnection] {
        return networkResponses
            .filter { areNetworkRequestsEqual(lhs: $0.key, rhs: networkRequest) }
            .map { $0.value }
    }

    // MARK: - Private helpers
    // MARK: Network request expectation helpers
    private func countDownExpected(networkRequest: NetworkRequest) {
        for expectedNetworkRequest in expectedNetworkRequests {
            if areNetworkRequestsEqual(lhs: expectedNetworkRequest.key, rhs: networkRequest) {
                expectedNetworkRequest.value.countDown()
            }
        }
    }
    
    /// Sets the `HttpConnection` response connection for a given `NetworkRequest`
    private func setResponseFor(networkRequest: NetworkRequest, responseConnection: HttpConnection?) {
        networkResponses[networkRequest] = responseConnection
    }

    // MARK: General helpers
    /// Equals compare based on host, scheme and URL path. Query params are not taken into consideration
    private func areNetworkRequestsEqual(lhs: NetworkRequest, rhs: NetworkRequest) -> Bool {
        return lhs.url.host?.lowercased() == rhs.url.host?.lowercased()
            && lhs.url.scheme?.lowercased() == rhs.url.scheme?.lowercased()
            && lhs.url.path.lowercased() == rhs.url.path.lowercased()
            && lhs.httpMethod.rawValue == rhs.httpMethod.rawValue
    }
}

extension URL {
    func queryParam(_ param: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
}

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

/// Overriding NetworkService used for functional tests when extending the FunctionalTestBase
class FunctionalTestNetworkService: NetworkService {
    private var receivedNetworkRequests: [NetworkRequest: [NetworkRequest]] = [NetworkRequest: [NetworkRequest]]()
    private var responseMatchers: [NetworkRequest: HttpConnection] = [NetworkRequest: HttpConnection]()
    private var expectedNetworkRequests: [NetworkRequest: CountDownLatch] = [NetworkRequest: CountDownLatch]()
    private var delayedResponse: UInt32 = 0

    override func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        FunctionalTestBase.log("Received connectAsync to URL \(networkRequest.url.absoluteString) and HTTPMethod \(networkRequest.httpMethod.toString())")
        if var requests = receivedNetworkRequests[networkRequest] {
            requests.append(networkRequest)
        } else {
            receivedNetworkRequests[networkRequest] = [networkRequest]
        }

        countDownExpected(networkRequest: networkRequest)
        guard let unwrappedCompletionHandler = completionHandler else { return }

        if delayedResponse > 0 {
            sleep(delayedResponse)
        }

        if let response = getMatchedResponseForUrlAndHttpMethod(networkRequest: networkRequest) {
            unwrappedCompletionHandler(response)
        } else {
            // default response
            unwrappedCompletionHandler(HttpConnection(data: "".data(using: .utf8),
                                                      response: HTTPURLResponse(url: networkRequest.url,
                                                                                statusCode: 200,
                                                                                httpVersion: nil,
                                                                                headerFields: nil),
                                                      error: nil))
        }
    }

    func enableDelayedResponse(delaySec: UInt32) {
        delayedResponse = delaySec
    }

    func reset() {
        expectedNetworkRequests.removeAll()
        receivedNetworkRequests.removeAll()
        responseMatchers.removeAll()
        delayedResponse = 0
    }

    func awaitFor(networkRequest: NetworkRequest, timeout: TimeInterval) -> DispatchTimeoutResult? {
        for expectedNetworkRequest in expectedNetworkRequests {
            if areNetworkRequestsEqual(lhs: expectedNetworkRequest.key, rhs: networkRequest) {
                return expectedNetworkRequest.value.await(timeout: timeout)
            }
        }

        return nil
    }

    func getReceivedNetworkRequestsMatching(networkRequest: NetworkRequest) -> [NetworkRequest] {
        var matchingRequests: [NetworkRequest] = []
        for receivedRequest in receivedNetworkRequests {
            if areNetworkRequestsEqual(lhs: receivedRequest.key, rhs: networkRequest) {
                matchingRequests.append(receivedRequest.key)
            }
        }

        return matchingRequests
    }

    func setExpectedNetworkRequest(networkRequest: NetworkRequest, count: Int32) {
        expectedNetworkRequests[networkRequest] = CountDownLatch(count)
    }

    func getExpectedNetworkRequests() -> [NetworkRequest: CountDownLatch] {
        return expectedNetworkRequests
    }

    func setResponseConnectionFor(networkRequest: NetworkRequest, responseConnection: HttpConnection?) -> Bool {
        for responseMatcher in responseMatchers {
            if areNetworkRequestsEqual(lhs: responseMatcher.key, rhs: networkRequest) {
                // unable to override response matcher
                return false
            }
        }

        // add new entry if not present already
        responseMatchers[networkRequest] = responseConnection
        return true
    }

    private func countDownExpected(networkRequest: NetworkRequest) {
        for expectedNetworkRequest in expectedNetworkRequests {
            if areNetworkRequestsEqual(lhs: expectedNetworkRequest.key, rhs: networkRequest) {
                expectedNetworkRequest.value.countDown()
            }
        }
    }

    private func getMatchedResponseForUrlAndHttpMethod(networkRequest: NetworkRequest) -> HttpConnection? {
        for responseMatcher in responseMatchers {
            if areNetworkRequestsEqual(lhs: responseMatcher.key, rhs: networkRequest) {
                return responseMatcher.value
            }
        }

        return nil
    }

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

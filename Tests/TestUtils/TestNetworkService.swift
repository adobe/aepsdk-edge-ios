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

/// DO NOT use this class directly in tests. Use the child classes, either `MockTestNetworkService` or
/// `ServerTestNetworkService` depending on which is appropriate for your use case.
/// The base NetworkService class that implements shared utilities and logic for NetworkService class implementations
/// used for testing.
class TestNetworkService: NetworkService {
    private var sentNetworkRequests: [NetworkRequest: [NetworkRequest]] = [:]
    /// Matches sent `NetworkRequest`s with their corresponding `HttpConnection` response.
    private(set) var networkResponses: [NetworkRequest: HttpConnection] = [:]
    private var expectedNetworkRequests: [NetworkRequest: CountDownLatch] = [:]
    
    func recordSentNetworkRequest(_ networkRequest: NetworkRequest) {
        TestBase.log("Received connectAsync to URL \(networkRequest.url.absoluteString) and HTTPMethod \(networkRequest.httpMethod.toString())")
        if let equalNetworkRequest = sentNetworkRequests.first(where: { key, value in
            areNetworkRequestsEqual(lhs: networkRequest, rhs: key)
        }) {
            sentNetworkRequests[equalNetworkRequest.key]!.append(networkRequest)
        }
        else {
            sentNetworkRequests[networkRequest] = [networkRequest]
        }
    }

    func reset() {
        expectedNetworkRequests.removeAll()
        sentNetworkRequests.removeAll()
        networkResponses.removeAll()
    }
    
    /// Equals compare based on host, scheme and URL path. Query params are not taken into consideration
    func areNetworkRequestsEqual(lhs: NetworkRequest, rhs: NetworkRequest) -> Bool {
        return lhs.url.host?.lowercased() == rhs.url.host?.lowercased()
            && lhs.url.scheme?.lowercased() == rhs.url.scheme?.lowercased()
            && lhs.url.path.lowercased() == rhs.url.path.lowercased()
            && lhs.httpMethod.rawValue == rhs.httpMethod.rawValue
    }
    
    func countDownExpected(networkRequest: NetworkRequest) {
        for expectedNetworkRequest in expectedNetworkRequests {
            if areNetworkRequestsEqual(lhs: expectedNetworkRequest.key, rhs: networkRequest) {
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
    func awaitFor(networkRequest: NetworkRequest, timeout: TimeInterval) -> DispatchTimeoutResult? {
        for expectedNetworkRequest in expectedNetworkRequests {
            if areNetworkRequestsEqual(lhs: expectedNetworkRequest.key, rhs: networkRequest) {
                return expectedNetworkRequest.value.await(timeout: timeout)
            }
        }

        return nil
    }

    /// Returns all of the original outgoing `NetworkRequest`s satisfying `areNetworkRequestsEqual(lhs:rhs:)`.
    func getSentNetworkRequestsMatching(networkRequest: NetworkRequest) -> [NetworkRequest] {
        var matchingRequests: [NetworkRequest] = []
        for receivedRequest in sentNetworkRequests {
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
    
    // MARK: Network request response helpers
    /// Sets the `HttpConnection` response connection for a given `NetworkRequest`
    func setResponseFor(networkRequest: NetworkRequest, responseConnection: HttpConnection?) {
        networkResponses[networkRequest] = responseConnection
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
}

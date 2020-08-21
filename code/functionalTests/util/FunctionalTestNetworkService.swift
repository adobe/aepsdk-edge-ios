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

@testable import AEPExperiencePlatform
@testable import AEPServices
import Foundation

// NetworkRequest extension used for compares in Dictionaries where NetworkRequest is the key
extension NetworkRequest: Hashable {

    /// Equals compare based on host, scheme and URL path. Query params are not taken into consideration
    public static func == (lhs: NetworkRequest, rhs: NetworkRequest) -> Bool {
        return lhs.url.host?.lowercased() == rhs.url.host?.lowercased()
            && lhs.url.scheme?.lowercased() == rhs.url.scheme?.lowercased()
            && lhs.url.path.lowercased() == rhs.url.path.lowercased()
            && lhs.httpMethod.rawValue == rhs.httpMethod.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(url.scheme)
        hasher.combine(url.host)
        hasher.combine(url.path)
        hasher.combine(httpMethod.rawValue)
    }
}

/// Overriding NetworkService used for functional tests when extending the FunctionalTestBase
class FunctionalTestNetworkService: NetworkService {
    var receivedNetworkRequests: [NetworkRequest: [NetworkRequest]] = [NetworkRequest: [NetworkRequest]]()
    var responseMatchers: [NetworkRequest: HttpConnection] = [NetworkRequest: HttpConnection]()
    var expectedNetworkRequests: [NetworkRequest: CountDownLatch] = [NetworkRequest: CountDownLatch]()

    override func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        FunctionalTestBase.log("Received connectAsync to URL \(networkRequest.url.absoluteString) and HTTPMethod \(networkRequest.httpMethod.toString())")
        if var requests = receivedNetworkRequests[networkRequest] {
            requests.append(networkRequest)
        } else {
            receivedNetworkRequests[networkRequest] = [networkRequest]
        }

        if let _ = expectedNetworkRequests[networkRequest] {
            expectedNetworkRequests[networkRequest]?.countDown()
        }

        guard let unwrappedCompletionHandler = completionHandler else { return }
        if let response = responseMatchers[networkRequest] {
            unwrappedCompletionHandler(response)
        } else {
            // default response
            unwrappedCompletionHandler(HttpConnection(data: "".data(using: .utf8), response: HTTPURLResponse(url: networkRequest.url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil))
        }
    }

    func reset() {
        receivedNetworkRequests.removeAll()
        responseMatchers.removeAll()
    }
}

extension URL {
    func queryParam(_ param: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
}

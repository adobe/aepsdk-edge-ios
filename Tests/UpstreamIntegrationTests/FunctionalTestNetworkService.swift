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

protocol NetworkRequestDelegate: AnyObject {
    func handleNetworkResponse(httpConnection: HttpConnection)
}
/// Overriding NetworkService used for functional tests when extending the FunctionalTestBase
class FunctionalTestNetworkService: NetworkService {
    private let LOG_SOURCE = "NetworkService"
    private var sessions = ThreadSafeDictionary<String, URLSession>(identifier: "com.adobe.networkservice.sessions")
    var networkRequestResponseHandles: [NetworkRequest: HttpConnection] = [:]
    weak var testingDelegate: NetworkRequestDelegate?
    private var receivedNetworkRequests: [NetworkRequest: [NetworkRequest]] = [NetworkRequest: [NetworkRequest]]()
    private var responseMatchers: [NetworkRequest: HttpConnection] = [NetworkRequest: HttpConnection]()
    private var expectedNetworkRequests: [NetworkRequest: CountDownLatch] = [NetworkRequest: CountDownLatch]()
    private var delayedResponse: UInt32 = 0

    // The completionHandler is prepopulated with implementations from the callsite (in this case, Edge extension)
    // we want to copy this data for our own testing validation against the raw data
    // since HttpConnection is a struct, we can insert it into our local data store without worry of the instance changing over time (outside of our own manipulations)
    
    // actually, i think we dont want to handle the raw httpconnection since there can be streaming etc;
    // since all responses to an event should be dispatched through mobile core anyways, a listener with the right configuration should be
    // able to capture all response events, not just a direct response?
    override func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
//        FunctionalTestBase.log("Received connectAsync to URL \(networkRequest.url.absoluteString) and HTTPMethod \(networkRequest.httpMethod.toString())")
        // MARK: Functional test logic
        print("Received connectAsync to URL \(networkRequest.url.absoluteString) and HTTPMethod \(networkRequest.httpMethod.toString())")
        if var requests = receivedNetworkRequests[networkRequest] {
            requests.append(networkRequest)
        } else {
            receivedNetworkRequests[networkRequest] = [networkRequest]
        }

        countDownExpected(networkRequest: networkRequest)
        // NOTE: remove mocked response section
//        guard let unwrappedCompletionHandler = completionHandler else { return }
//
//        if delayedResponse > 0 {
//            sleep(delayedResponse)
//        }
//
//        if let response = getMatchedResponseForUrlAndHttpMethod(networkRequest: networkRequest) {
//            unwrappedCompletionHandler(response)
//        } else {
//            // default response
//            unwrappedCompletionHandler(HttpConnection(data: "".data(using: .utf8),
//                                                      response: HTTPURLResponse(url: networkRequest.url,
//                                                                                statusCode: 200,
//                                                                                httpVersion: nil,
//                                                                                headerFields: nil),
//                                                      error: nil))
//        }
        
        // MARK: Real network request logic
        if !networkRequest.url.absoluteString.starts(with: "https") {
            Log.warning(label: LOG_SOURCE, "Network request for (\(networkRequest.url.absoluteString)) could not be created, only https requests are accepted.")
            if let closure = completionHandler {
                closure(HttpConnection(data: nil, response: nil, error: NetworkServiceError.invalidUrl))
            }
            return
        }

        let urlRequest = createURLRequest(networkRequest: networkRequest)
        let urlSession = createURLSession(networkRequest: networkRequest)

        // initiate the network request
        Log.debug(label: LOG_SOURCE, "Initiated (\(networkRequest.httpMethod.toString())) network request to (\(networkRequest.url.absoluteString)).")
        let task = urlSession.dataTask(with: urlRequest, completionHandler: { data, response, error in
            if let closure = completionHandler {
                let httpConnection = HttpConnection(data: data, response: response as? HTTPURLResponse, error: error)
                if let testingDelegate = self.testingDelegate {
                    testingDelegate.handleNetworkResponse(httpConnection: httpConnection)
                }
                
                closure(httpConnection)
            }
        })
        task.resume()
    }

    /// Creates an `URLRequest` with the provided parameters and adds the SDK default headers. The cache policy used is reloadIgnoringLocalCacheData.
    /// - Parameter networkRequest: `NetworkRequest`
    private func createURLRequest(networkRequest: NetworkRequest) -> URLRequest {
        var request = URLRequest(url: networkRequest.url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = networkRequest.httpMethod.toString()

        if !networkRequest.connectPayload.isEmpty, networkRequest.httpMethod == .post {
            request.httpBody = networkRequest.connectPayload
        }

        for (key, val) in networkRequest.httpHeaders {
            request.setValue(val, forHTTPHeaderField: key)
        }

        return request
    }
    

    // MARK: - Functional testing helper methods
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

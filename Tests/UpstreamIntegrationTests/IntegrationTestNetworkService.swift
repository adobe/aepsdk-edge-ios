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

protocol NetworkRequestDelegate: AnyObject {
    func handleNetworkResponse(httpConnection: HttpConnection)
}
/// Overriding NetworkService used for integration tests, allowing for capture of network responses for testing
class IntegrationTestNetworkService: NetworkService {
    private let LOG_SOURCE = "IntegrationTestNetworkService"
    weak var testingDelegate: NetworkRequestDelegate?
    
    override func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        super.connectAsync(networkRequest: networkRequest) { (connection: HttpConnection) in
            print("Received connectAsync to URL \(networkRequest.url.absoluteString) and HTTPMethod \(networkRequest.httpMethod.toString())")
            if let testingDelegate = self.testingDelegate {
                testingDelegate.handleNetworkResponse(httpConnection: connection)
            }
            // Finally call the original completion handler
            completionHandler?(connection)
        }
    }
}

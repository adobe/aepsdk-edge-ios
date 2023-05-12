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
import XCTest

/// Overriding NetworkService used for integration tests
class RealTestNetworkService: NetworkService {
    private let helper: NetworkRequestHelper = NetworkRequestHelper()
    
    override func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        helper.recordSentNetworkRequest(networkRequest)
        super.connectAsync(networkRequest: networkRequest, completionHandler: { (connection: HttpConnection) in
            self.helper.setResponseFor(networkRequest: networkRequest, responseConnection: connection)
            self.helper.countDownExpected(networkRequest: networkRequest)
                
            // Finally call the original completion handler
            completionHandler?(connection)
        })
    }
    
    func getResponsesFor(networkRequest: NetworkRequest, timeout: TimeInterval = TestConstants.Defaults.WAIT_NETWORK_REQUEST_TIMEOUT, file: StaticString = #file, line: UInt = #line) -> [HttpConnection] {
        helper.awaitRequest(networkRequest, timeout: timeout, file: file, line: line)
        return helper.networkResponses
            .filter { networkRequest == $0.key }
            .map { $0.value }
    }
    
    // MARK: - Passthrough for shared helper APIs
    func reset() {
        helper.reset()
    }
    
    func setExpectationForNetworkRequest(url: String, httpMethod: HttpMethod, expectedCount: Int32 = 1, file: StaticString = #file, line: UInt = #line) {
        helper.setExpectationForNetworkRequest(url: url, httpMethod: httpMethod, expectedCount: expectedCount, file: file, line: line)
    }
}

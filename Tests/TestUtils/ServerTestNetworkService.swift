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

/// Overriding NetworkService used for functional tests when extending the TestBase
class ServerTestNetworkService: TestNetworkService {
    
    override func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        recordSentNetworkRequest(networkRequest)
        super.connectAsync(networkRequest: networkRequest, completionHandler: { (connection: HttpConnection) in
            self.setResponseFor(networkRequest: networkRequest, responseConnection: connection)
            self.countDownExpected(networkRequest: networkRequest)
                
            // Finally call the original completion handler
            completionHandler?(connection)
        })
    }
    
    func getResponsesFor(networkRequest: NetworkRequest) -> [HttpConnection] {
        return networkResponses
            .filter { areNetworkRequestsEqual(lhs: $0.key, rhs: networkRequest) }
            .map { $0.value }
    }
}

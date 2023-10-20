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

@testable import AEPServices
import Foundation
import XCTest

/// Overriding NetworkService used for tests that require real outgoing network requests
class RealNetworkService: NetworkService {
    private let helper: NetworkRequestHelper = NetworkRequestHelper()

    override func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        helper.recordSentNetworkRequest(networkRequest)
        super.connectAsync(networkRequest: networkRequest, completionHandler: { (connection: HttpConnection) in
            self.helper.addResponse(for: networkRequest, responseConnection: connection)
            self.helper.countDownExpected(networkRequest: networkRequest)

            // Finally call the original completion handler
            completionHandler?(connection)
        })
    }

    /// Immediately returns the associated responses (if any) for the provided network request **without awaiting**.
    ///
    /// Note: To properly await network responses for a given request, make sure to set an expectation
    /// using `setExpectation(for:)` then await the expectation using `assertAllNetworkRequestExpectations()`.
    ///
    /// - Parameter networkRequest: The `NetworkRequest` for which the response should be returned.
    /// - Returns: The array of `HttpConnection` responses for the given request or `nil` if not found.
    /// - seeAlso: ``assertAllNetworkRequestExpectations``
    func getResponses(for networkRequest: NetworkRequest) -> [HttpConnection]? {
        return helper.getResponses(for: networkRequest)
    }

    // MARK: - Passthrough for shared helper APIs
    /// Asserts that the correct number of network requests were seen for all previously set network request expectations.
    /// - Parameters:
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    /// - SeeAlso: ``setExpectation(for:)``
    func assertAllNetworkRequestExpectations(file: StaticString = #file, line: UInt = #line) {
        helper.assertAllNetworkRequestExpectations(file: file, line: line)
    }

    func reset() {
        helper.reset()
    }

    /// Sets the expected number of times a network request should be sent.
    ///
    /// - Parameters:
    ///   - networkRequest: The `NetworkRequest` to set the expectation for.
    ///   - expectedCount: The number of times the request is expected to be sent. The default value is 1.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func setExpectation(for networkRequest: NetworkRequest, expectedCount: Int32 = 1, file: StaticString = #file, line: UInt = #line) {
        helper.setExpectation(for: networkRequest, expectedCount: expectedCount, file: file, line: line)
    }
}

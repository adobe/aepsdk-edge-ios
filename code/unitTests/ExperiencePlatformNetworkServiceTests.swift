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

import XCTest

@testable import ACPExperiencePlatform

class ExperiencePlatformNetworkServiceTests: XCTestCase {
    
    let testNetworkService = MockNetworkServiceOverrider()
    
    public override func setUp() {
        AEPServiceProvider.shared.networkService = testNetworkService
    }
    
    class MockResponseCallback : ResponseCallback {
        var onResponseCalled: Bool = false
        var onErrorCalled: Bool = false
        var onCompleteCalled: Bool = false
        
        func onResponse(jsonResponse: String) {
            onResponseCalled = true
        }
        
        func onError(jsonError: String) {
            onErrorCalled = true
        }
        
        func onComplete() {
            onCompleteCalled = true
        }
    }
    
    func testStrings() {
        let testStr : String = "\u{00A9}{\"some\":\"thing\\n\"}\u{00F8}" +
        "\u{00A9}{" +
        "  \"may\": {" +
        "    \"include\": \"nested\"," +
        "    \"objects\": [" +
        "      \"and\"," +
        "      \"arrays\"" +
        "    ]" +
        "  }" +
        "}\u{00F8}";
        let requestConfigRecordSeparator: Character = "\u{00A9}"
        let requestConfigLineFeed: Character = "\u{00F8}"
        // todo
        
    }
    
    func testDoRequest_whenRequestHeadersAreEmpty_setsDefaultHeaders() {

        // setup
        var jsonBody: Data = "{}".data(using: .utf8)!
        var url: URL = URL(string: "https://test.com")!
        var mockResponseCallback = MockResponseCallback()

        // test
        let networkService = ExperiencePlatformNetworkService()
        let retryResult = networkService.doRequest(url:url, jsonBody:jsonBody, requestHeaders: [:], responseCallback: mockResponseCallback, retryTimes: 0)

        // verify
        // TODO: update network service and add assertions
    }
    
    func testDoRequest_whenRequestHeadersExist_RequestHeadersAppendedOnNetworkCall() {
        
    }
    
    func testDoRequest_whenConnection_ResponseCode200_ReturnsRetryNo_AndCallsResponseCallback_AndNoErrorCallback() {
        
    }
    
    func testDoRequest_whenConnection_ResponseCode204_ReturnsRetryNo_AndNoResponseCallback_AndNoErrorCallback() {
        
    }
    
    func testHandleStreamingResponse_EmptyResponse() {
        let networkService = ExperiencePlatformNetworkService()
        
    }
}
  

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
import Foundation

/// Mock for the internal `ResponseCallback`, used by the `EdgeNetworkService`
class MockResponseCallback: ResponseCallback {
    var onResponseCalled: Bool = false
    var onResponseJsonResponse: [String] = []
    var onErrorCalled: Bool = false
    var onErrorJsonError: [String] = []
    var onCompleteCalled: Bool = false

    func onResponse(jsonResponse: String) {
        onResponseCalled = true
        onResponseJsonResponse.append(jsonResponse)
    }

    func onError(jsonError: String) {
        onErrorCalled = true
        onErrorJsonError.append(jsonError)
    }

    func onComplete() {
        onCompleteCalled = true
    }
}

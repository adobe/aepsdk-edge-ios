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

import AEPEdge
import Foundation

/// Mock class for public `EdgeResponseHandler` used for testing. Initialize it with expected responses and errors count and
/// call await before making the assertions.
class MockResponseHandler: EdgeResponseHandler {
    var onResponseHandles: [EdgeEventHandle] = []
    var onErrorHandles: [EdgeEventError] = []
    var onCompleteCalled: Bool = false

    private var responseLatch: CountDownLatch?
    private var errorLatch: CountDownLatch?
    private var completeLatch: CountDownLatch = CountDownLatch(1)

    /// Initializer with expected count of responses and/or errors
    /// - Parameters:
    ///   - expectedResponses: expected count of onResponse updates / event handles, if not set it is 0
    ///   - expectedErrors: expected count of onError updates / event errors, if not set it is 0
    init(expectedResponses: Int32 = 0, expectedErrors: Int32 = 0) {
        if expectedResponses > 0 {
            responseLatch = CountDownLatch(expectedResponses)
        }

        if expectedErrors > 0 {
            errorLatch = CountDownLatch(expectedErrors)
        }
    }

    func onResponseUpdate(eventHandle: EdgeEventHandle) {
        onResponseHandles.append(eventHandle)
        responseLatch?.countDown()
    }

    func onErrorUpdate(error: EdgeEventError) {
        onErrorHandles.append(error)
        errorLatch?.countDown()
    }

    func onComplete() {
        onCompleteCalled = true
        completeLatch.countDown()
    }

    /// Waits for the expected responses and errors
    func await() {
        _ = responseLatch?.await()
        _ = errorLatch?.await()
        _ = completeLatch.await()
    }
}

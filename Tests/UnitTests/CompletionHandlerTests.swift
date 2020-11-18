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

import AEPCore
@testable import AEPEdge
import XCTest

class CompletionHandlerTests: XCTestCase {
    private let requestEventId = "requestEventId"
    // swiftlint:disable force_try
    private var eventHandle: EdgeEventHandle = {
        let json: [String: Any] = ["payload": [["key1": "value1", "key2": 2]], "type": "testType"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        return try! JSONDecoder().decode(EdgeEventHandle.self, from: jsonData)
    }()
    private var eventError: EdgeEventError = {
        let json: [String: Any] = ["message": "Error message", "code": "789", "namespace": "test.namespace"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        return try! JSONDecoder().decode(EdgeEventError.self, from: jsonData)
    }()
    // swiftlint:enable force_try
    private let uniqueEventId = "123"

    override func setUp() {
        continueAfterFailure = false // fail so nil checks stop execution
    }

    func testRegisterCompletionHandler_thenEventHandlerReceived_completionCalled() {
        let expectation = self.expectation(description: "Completion handler invoked")
        ResponseCallbackHandler.shared.registerCompletionHandler(requestEventId: uniqueEventId, completionHandler: { (handles: [EdgeEventHandle], errors: [EdgeEventError]) in
            XCTAssertEqual(1, handles.count)
            XCTAssertEqual(0, errors.count)
            expectation.fulfill()
        })
        ResponseCallbackHandler.shared.eventHandleReceived(eventHandle, requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)

        wait(for: [expectation], timeout: 2)
    }

    func testRegisterTwoCompletionHandlers_thenEventHandlerReceived_completionCalledForCorrectOne() {
        let expectation = self.expectation(description: "Completion handler invoked")
        ResponseCallbackHandler.shared.registerCompletionHandler(requestEventId: "567", completionHandler: { (_ handles: [EdgeEventHandle], _ errors: [EdgeEventError]) in
            XCTFail("Unexpected call")
        })
        ResponseCallbackHandler.shared.registerCompletionHandler(requestEventId: uniqueEventId, completionHandler: { (handles: [EdgeEventHandle], errors: [EdgeEventError]) in
            XCTAssertEqual(1, handles.count)
            XCTAssertEqual(0, errors.count)
            expectation.fulfill()
        })
        ResponseCallbackHandler.shared.eventHandleReceived(eventHandle, requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)
        wait(for: [expectation], timeout: 2)
    }

    func testRegisterCompletionHandler_thenUnregisterCallbacks_thenNewEventHandleReceived() {
        let expectation = self.expectation(description: "Completion handler invoked")
        expectation.assertForOverFulfill = true
        ResponseCallbackHandler.shared.registerCompletionHandler(requestEventId: uniqueEventId, completionHandler: { (handles: [EdgeEventHandle], errors: [EdgeEventError]) in
            XCTAssertEqual(1, handles.count)
            XCTAssertEqual(0, errors.count)
            expectation.fulfill()
        })
        ResponseCallbackHandler.shared.eventHandleReceived(eventHandle, requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.eventHandleReceived(eventHandle, requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)
        wait(for: [expectation], timeout: 2)
    }

    func testRegisterCompletionCallback_withEmptyUniqueEvent_doesNotCrash() {
        XCTAssertNoThrow(ResponseCallbackHandler.shared.registerCompletionHandler(requestEventId: "", completionHandler: { (_ handles: [EdgeEventHandle], _ errors: [EdgeEventError]) in }))
    }

    // error handling
    func testRegisterCompletionHandler_thenEventErrorReceived_completionCalled() {
        let expectation = self.expectation(description: "Completion handler invoked")
        expectation.assertForOverFulfill = true
        ResponseCallbackHandler.shared.registerCompletionHandler(requestEventId: uniqueEventId, completionHandler: { (handles: [EdgeEventHandle], errors: [EdgeEventError]) in
            XCTAssertEqual(0, handles.count)
            XCTAssertEqual(1, errors.count)
            expectation.fulfill()
        })

        ResponseCallbackHandler.shared.eventErrorReceived(eventError, requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)
        wait(for: [expectation], timeout: 2)
    }

    func testRegisterTwoCompletionHandlers_thenEventErrorReceived_completionCalledForCorrectOne() {
        let expectation = self.expectation(description: "Completion handler invoked")
        ResponseCallbackHandler.shared.registerCompletionHandler(requestEventId: "567", completionHandler: { (_ handles: [EdgeEventHandle], _ errors: [EdgeEventError]) in
            XCTFail("Unexpected call")
        })
        ResponseCallbackHandler.shared.registerCompletionHandler(requestEventId: uniqueEventId, completionHandler: { (handles: [EdgeEventHandle], errors: [EdgeEventError]) in
            XCTAssertEqual(0, handles.count)
            XCTAssertEqual(1, errors.count)
            expectation.fulfill()
        })

        ResponseCallbackHandler.shared.eventErrorReceived(eventError, requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)
        wait(for: [expectation], timeout: 2)
    }

    func testRegisterCompletionHandler_thenUnregisterCallbacks_thenNewEventErrorReceived() {
        let expectation = self.expectation(description: "Completion handler invoked")
        expectation.assertForOverFulfill = true
        ResponseCallbackHandler.shared.registerCompletionHandler(requestEventId: uniqueEventId, completionHandler: { (handles: [EdgeEventHandle], errors: [EdgeEventError]) in
            XCTAssertEqual(0, handles.count)
            XCTAssertEqual(1, errors.count)
            expectation.fulfill()
        })
        ResponseCallbackHandler.shared.eventErrorReceived(eventError, requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.eventErrorReceived(eventError, requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)
        wait(for: [expectation], timeout: 2)
    }

    func testRegisterCompletionHandler_thenUnregisterCallbacks_completionCalled() {
        let expectation = self.expectation(description: "Completion handler invoked")
        ResponseCallbackHandler.shared.registerCompletionHandler(requestEventId: uniqueEventId, completionHandler: { (handles: [EdgeEventHandle], errors: [EdgeEventError]) in
            XCTAssertEqual(0, handles.count)
            XCTAssertEqual(0, errors.count)
            expectation.fulfill()
        })
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)
        wait(for: [expectation], timeout: 2)
    }

    func testRegisterCompletionHandler_thenUnregisterCallbacksMultipleTimes_completionCalledOnce() {
        let expectation = self.expectation(description: "Completion handler invoked")
        expectation.assertForOverFulfill = true
        ResponseCallbackHandler.shared.registerCompletionHandler(requestEventId: uniqueEventId, completionHandler: { (handles: [EdgeEventHandle], errors: [EdgeEventError]) in
            XCTAssertEqual(0, handles.count)
            XCTAssertEqual(0, errors.count)
            expectation.fulfill()
        })
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)

        wait(for: [expectation], timeout: 2)
    }

    func testRegisterCompletionHandler_thenUnregisterCallbacksForOtherEventIds_completionNotCalled() {
        ResponseCallbackHandler.shared.registerCompletionHandler(requestEventId: uniqueEventId, completionHandler: { (_ handles: [EdgeEventHandle], _ errors: [EdgeEventError]) in
            XCTFail("Unexpected call")
        })
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: "888")
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: "999")
    }

    func testRegisterCompletionHandler_thenUnregisterCallbacks_thenEventErrorReceivedMultipleTimes_completionCalled() {
        let expectation1 = self.expectation(description: "Completion handler 1 invoked")
        expectation1.assertForOverFulfill = true
        ResponseCallbackHandler.shared.registerCompletionHandler(requestEventId: uniqueEventId, completionHandler: { (handles: [EdgeEventHandle], errors: [EdgeEventError]) in
            XCTAssertEqual(2, handles.count)
            XCTAssertEqual(1, errors.count)
            expectation1.fulfill()
        })
        let expectation2 = self.expectation(description: "Completion handler 2 invoked")
        expectation2.assertForOverFulfill = true
        ResponseCallbackHandler.shared.registerCompletionHandler(requestEventId: "888", completionHandler: { (handles: [EdgeEventHandle], errors: [EdgeEventError]) in
            XCTAssertEqual(1, handles.count)
            XCTAssertEqual(2, errors.count)
            expectation2.fulfill()
        })

        ResponseCallbackHandler.shared.eventHandleReceived(eventHandle, requestEventId: "888")
        ResponseCallbackHandler.shared.eventErrorReceived(eventError, requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.eventHandleReceived(eventHandle, requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.eventErrorReceived(eventError, requestEventId: "888")
        ResponseCallbackHandler.shared.eventHandleReceived(eventHandle, requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.eventErrorReceived(eventError, requestEventId: "888")
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: "888")
        wait(for: [expectation1, expectation2], timeout: 2)
    }
}

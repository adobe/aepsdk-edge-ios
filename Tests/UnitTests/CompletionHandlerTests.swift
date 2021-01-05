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
    // swiftlint:enable force_try
    private let uniqueEventId = "123"
    private let uniqueEventId2 = "888"
    private let uniqueEventId3 = "999"

    override func setUp() {
        continueAfterFailure = false // fail so nil checks stop execution
    }

    override func tearDown() {
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId)
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId2)
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId3)
    }

    // MARK: - register completion handler, expect event handles
    func testRegisterCompletionHandler_thenEventHandleReceived_completionCalled() {
        let expectation = self.expectation(description: "Completion handler invoked")
        expectation.assertForOverFulfill = true
        CompletionHandlersManager.shared.registerCompletionHandler(forRequestEventId: uniqueEventId, completion: { (handles: [EdgeEventHandle]) in
            XCTAssertEqual(1, handles.count)
            expectation.fulfill()
        })
        CompletionHandlersManager.shared.eventHandleReceived(forRequestEventId: uniqueEventId, eventHandle)
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId)

        wait(for: [expectation], timeout: 2)
    }

    func testRegisterTwoCompletionHandlers_thenEventHandleReceived_completionCalledForCorrectOne() {
        let expectation1 = self.expectation(description: "Unexpected call")
        expectation1.isInverted = true
        let expectation2 = self.expectation(description: "Completion handler invoked")
        expectation2.assertForOverFulfill = true

        CompletionHandlersManager.shared.registerCompletionHandler(forRequestEventId: uniqueEventId2, completion: { (_ handles: [EdgeEventHandle]) in
            expectation1.fulfill()
        })
        CompletionHandlersManager.shared.registerCompletionHandler(forRequestEventId: uniqueEventId, completion: { (handles: [EdgeEventHandle]) in
            XCTAssertEqual(1, handles.count)
            expectation2.fulfill()
        })
        CompletionHandlersManager.shared.eventHandleReceived(forRequestEventId: uniqueEventId, eventHandle)
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId)
        wait(for: [expectation1, expectation2], timeout: 0.2)
    }

    func testRegisterCompletionHandlers_thenEventHandleMultipleTimes_completionCalled() {
        let expectation1 = self.expectation(description: "Completion handler 1 invoked")
        expectation1.assertForOverFulfill = true
        CompletionHandlersManager.shared.registerCompletionHandler(forRequestEventId: uniqueEventId, completion: { (handles: [EdgeEventHandle]) in
            XCTAssertEqual(3, handles.count)
            expectation1.fulfill()
        })
        let expectation2 = self.expectation(description: "Completion handler 2 invoked")
        expectation2.assertForOverFulfill = true
        CompletionHandlersManager.shared.registerCompletionHandler(forRequestEventId: uniqueEventId2, completion: { (handles: [EdgeEventHandle]) in
            XCTAssertEqual(2, handles.count)
            expectation2.fulfill()
        })

        CompletionHandlersManager.shared.eventHandleReceived(forRequestEventId: uniqueEventId2, eventHandle)
        CompletionHandlersManager.shared.eventHandleReceived(forRequestEventId: uniqueEventId, eventHandle)
        CompletionHandlersManager.shared.eventHandleReceived(forRequestEventId: uniqueEventId, eventHandle)
        CompletionHandlersManager.shared.eventHandleReceived(forRequestEventId: uniqueEventId2, eventHandle)
        CompletionHandlersManager.shared.eventHandleReceived(forRequestEventId: uniqueEventId, eventHandle)
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId)
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId2)
        wait(for: [expectation1, expectation2], timeout: 2)
    }

    // MARK: - unregister completion handlers
    func testRegisterCompletionHandler_thenUnregister_thenNewEventHandleReceived() {
        let expectation = self.expectation(description: "Completion handler invoked")
        expectation.assertForOverFulfill = true
        CompletionHandlersManager.shared.registerCompletionHandler(forRequestEventId: uniqueEventId, completion: { (handles: [EdgeEventHandle]) in
            XCTAssertEqual(1, handles.count)
            expectation.fulfill()
        })
        CompletionHandlersManager.shared.eventHandleReceived(forRequestEventId: uniqueEventId, eventHandle)
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId)
        CompletionHandlersManager.shared.eventHandleReceived(forRequestEventId: uniqueEventId, eventHandle)
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId)
        wait(for: [expectation], timeout: 0.2)
    }

    func testRegisterCompletionHandler_thenUnregister_completionCalled() {
        let expectation = self.expectation(description: "Completion handler invoked")
        expectation.assertForOverFulfill = true
        CompletionHandlersManager.shared.registerCompletionHandler(forRequestEventId: uniqueEventId, completion: { (handles: [EdgeEventHandle]) in
            XCTAssertEqual(0, handles.count)
            expectation.fulfill()
        })
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId)
        wait(for: [expectation], timeout: 0.2)
    }

    func testRegisterCompletionHandler_thenUnregisterMultipleTimes_completionCalledOnce() {
        let expectation = self.expectation(description: "Completion handler invoked")
        expectation.assertForOverFulfill = true
        CompletionHandlersManager.shared.registerCompletionHandler(forRequestEventId: uniqueEventId, completion: { (handles: [EdgeEventHandle]) in
            XCTAssertEqual(0, handles.count)
            expectation.fulfill()
        })
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId)
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId)
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId)

        wait(for: [expectation], timeout: 0.2)
    }

    func testRegisterCompletionHandler_thenUnregisterForOtherEventIds_completionNotCalled() {
        let expectation = self.expectation(description: "Unexpected call")
        expectation.isInverted = true
        CompletionHandlersManager.shared.registerCompletionHandler(forRequestEventId: uniqueEventId, completion: { (_ handles: [EdgeEventHandle]) in
            expectation.fulfill()
        })
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId2)
        CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: uniqueEventId3)
        wait(for: [expectation], timeout: 0.2)
    }

    // MARK: - nil, empty
    func testUnregisterCompletionHandler_withEmptyUniqueEvent_doesNotCrash() {
        XCTAssertNoThrow(CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: ""))
    }

    func testRegisterCompletionHandler_withEmptyUniqueEvent_doesNotCrash() {
        XCTAssertNoThrow(CompletionHandlersManager.shared.registerCompletionHandler(forRequestEventId: "", completion: { (_ handles: [EdgeEventHandle]) in }))
    }

    func testRegisterCompletionHandler_withNilCompletionHandler_doesNotCrash() {
        XCTAssertNoThrow(CompletionHandlersManager.shared.registerCompletionHandler(forRequestEventId: uniqueEventId, completion: nil))
    }

    func testEventHandleReceived_withEmptyUniqueEvent_doesNotCrash() {
        XCTAssertNoThrow(CompletionHandlersManager.shared.eventHandleReceived(forRequestEventId: "", eventHandle))
    }

    func testEventHandleReceived_withNilUniqueEvent_doesNotCrash() {
        XCTAssertNoThrow(CompletionHandlersManager.shared.eventHandleReceived(forRequestEventId: nil, eventHandle))
    }

    func testEventHandleReceived_withUnregisteredUniqueEvent_doesNotCrash() {
        XCTAssertNoThrow(CompletionHandlersManager.shared.eventHandleReceived(forRequestEventId: uniqueEventId, eventHandle))
    }
}

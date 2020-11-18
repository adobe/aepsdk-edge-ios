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

class ResponseHandlerTests: XCTestCase {
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

    func testRegisterResponseHandler_thenEventHandlerReceived_onResponseUpdateCalled() {
        let mockResponseHandler = MockEdgeResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: uniqueEventId, responseHandler: mockResponseHandler)
        ResponseCallbackHandler.shared.eventHandleReceived(eventHandle, requestEventId: uniqueEventId)

        XCTAssertEqual(1, mockResponseHandler.onResponseCalledTimes)
        let data = flattenDictionary(dict: mockResponseHandler.onResponseReceivedData)
        XCTAssertEqual(3, data.count)
        XCTAssertEqual("value1", data["payload[0].key1"] as? String)
        XCTAssertEqual(2, data["payload[0].key2"] as? Int)
        XCTAssertEqual("testType", data["type"] as? String)
    }

    func testRegisterTwoResponseHandlers_thenEventHandlerReceived_onResponseUpdateCalled() {
        let mockResponseHandler1 = MockEdgeResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: "567", responseHandler: mockResponseHandler1)
        let mockResponseHandler2 = MockEdgeResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: uniqueEventId, responseHandler: mockResponseHandler2)

        ResponseCallbackHandler.shared.eventHandleReceived(eventHandle, requestEventId: uniqueEventId)

        XCTAssertEqual(0, mockResponseHandler1.onResponseCalledTimes)
        XCTAssertEqual(1, mockResponseHandler2.onResponseCalledTimes)
        let data = flattenDictionary(dict: mockResponseHandler2.onResponseReceivedData)
        XCTAssertEqual(3, data.count)
        XCTAssertEqual("value1", data["payload[0].key1"] as? String)
        XCTAssertEqual(2, data["payload[0].key2"] as? Int)
        XCTAssertEqual("testType", data["type"] as? String)
    }

    func testNoRegisterResponseHandler_thenEventHandleReceived_doesNotCrash() {
        XCTAssertNoThrow(ResponseCallbackHandler.shared.eventHandleReceived(eventHandle, requestEventId: uniqueEventId), "eventHandleReceived should skip if no registered handler")
    }

    func testNoRegisterResponseHandler_thenUnregisterCallbacks_doesNotCrash() {
        let uniqueEventId = "123"
        XCTAssertNoThrow(ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId), "unregisterCallbacks should skip if no registered handler")
    }

    func testRegisterResponseHandler_thenUnregisterCallbacks_thenEventHandleReceived() {
        let uniqueEventId = "123"
        var data: [String: Any] = [:]
        data["key1"] = "value1"
        data["key2"] = 2
        data[requestEventId] = uniqueEventId

        let mockResponseHandler = MockEdgeResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: uniqueEventId, responseHandler: mockResponseHandler)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)

        ResponseCallbackHandler.shared.eventHandleReceived(eventHandle, requestEventId: uniqueEventId) // should not call the callback

        XCTAssertEqual(0, mockResponseHandler.onResponseCalledTimes)
    }

    func testRegisterResponseHandler_withEmptyUniqueEvent_doesNotCrash() {
        XCTAssertNoThrow(ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: "", responseHandler: MockEdgeResponseHandler()))
    }

    func testRegisterResponseHandler_withNilResponseHandler_thenEventHandleReceived_doesNotCrash() {
        let uniqueEventId = "123"
        ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: uniqueEventId, responseHandler: nil)
        XCTAssertNoThrow(ResponseCallbackHandler.shared.eventHandleReceived(eventHandle, requestEventId: uniqueEventId), "eventHandleReceived should skip when nil responseHandler")
    }

    func testRegisterResponseHandler_withNilResponseHandler_thenUnregisterCallbacks_doesNotCrash() {
        let uniqueEventId = "123"
        ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: uniqueEventId, responseHandler: nil)
        XCTAssertNoThrow(ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId), "unregisterCallbacks should skip when nil responseHandler")
    }

    func testUnregisterCallbacks_withEmptyUniqueEvent_doesNotCrash() {
        XCTAssertNoThrow(ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: ""), "unregisterCallbacks should skip when empty unique event id")
    }

    // error handling
    func testRegisterResponseHandler_thenEventErrorReceived_onErrorUpdateCalled() {
        let mockResponseHandler = MockEdgeResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: uniqueEventId, responseHandler: mockResponseHandler)
        ResponseCallbackHandler.shared.eventErrorReceived(eventError, requestEventId: uniqueEventId)

        XCTAssertEqual(1, mockResponseHandler.onErrorUpdateCalledTimes)
        guard let error = mockResponseHandler.onErrorUpdateData else {
            XCTFail("No error received")
            return
        }
        XCTAssertEqual("789", error.code)
        XCTAssertEqual("test.namespace", error.namespace)
        XCTAssertEqual("Error message", error.message)
    }

    func testRegisterTwoResponseHandlers_thenEventErrorReceived_onResponseUpdateCalled() {
        let mockResponseHandler1 = MockEdgeResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: "567", responseHandler: mockResponseHandler1)
        let mockResponseHandler2 = MockEdgeResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: uniqueEventId, responseHandler: mockResponseHandler2)

        ResponseCallbackHandler.shared.eventErrorReceived(eventError, requestEventId: uniqueEventId)

        XCTAssertEqual(0, mockResponseHandler1.onErrorUpdateCalledTimes)
        XCTAssertEqual(1, mockResponseHandler2.onErrorUpdateCalledTimes)
        guard let error = mockResponseHandler2.onErrorUpdateData else {
            XCTFail("No error received")
            return
        }
        XCTAssertEqual("789", error.code)
        XCTAssertEqual("test.namespace", error.namespace)
        XCTAssertEqual("Error message", error.message)
    }

    func testNoRegisterResponseHandler_thenEventErrorReceived_doesNotCrash() {
        XCTAssertNoThrow(ResponseCallbackHandler.shared.eventErrorReceived(eventError, requestEventId: uniqueEventId), "eventErrorReceived should skip if no registered handler")
    }

    func testRegisterResponseHandler_thenUnregisterCallbacks_thenEventErrorReceived() {
        let mockResponseHandler = MockEdgeResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: uniqueEventId, responseHandler: mockResponseHandler)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)

        ResponseCallbackHandler.shared.eventErrorReceived(eventError, requestEventId: uniqueEventId) // should not call the callback

        XCTAssertEqual(0, mockResponseHandler.onErrorUpdateCalledTimes)
    }

    func testRegisterResponseHandler_thenUnregisterCallbacks_callsOnComplete() {
        let mockResponseHandler = MockEdgeResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: uniqueEventId, responseHandler: mockResponseHandler)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)

        XCTAssertEqual(1, mockResponseHandler.onCompleteCalledTimes)
    }

    func testRegisterResponseHandler_thenUnregisterCallbacksMultipleTimes_callsOnCompleteOnce() {
        let mockResponseHandler = MockEdgeResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: uniqueEventId, responseHandler: mockResponseHandler)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)

        XCTAssertEqual(1, mockResponseHandler.onCompleteCalledTimes)
    }

    func testRegisterResponseHandler_thenUnregisterCallbacksForOtherEventIds_doesNotCallOnComplete() {
        let mockResponseHandler = MockEdgeResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: uniqueEventId, responseHandler: mockResponseHandler)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: "888")
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: "999")

        XCTAssertEqual(0, mockResponseHandler.onCompleteCalledTimes)
    }

    func testRegisterResponseHandler_thenUnregisterCallbacks_thenEventErrorReceived_doesNotUpdate() {
        let mockResponseHandler = MockEdgeResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(requestEventId: uniqueEventId, responseHandler: mockResponseHandler)
        ResponseCallbackHandler.shared.unregisterCallbacks(requestEventId: uniqueEventId)
        ResponseCallbackHandler.shared.eventHandleReceived(eventHandle, requestEventId: uniqueEventId) // should not call the callback
        ResponseCallbackHandler.shared.eventErrorReceived(eventError, requestEventId: uniqueEventId) // should not call the callback

        XCTAssertEqual(1, mockResponseHandler.onCompleteCalledTimes)
        XCTAssertEqual(0, mockResponseHandler.onResponseCalledTimes)
        XCTAssertEqual(0, mockResponseHandler.onErrorUpdateCalledTimes)
    }
}

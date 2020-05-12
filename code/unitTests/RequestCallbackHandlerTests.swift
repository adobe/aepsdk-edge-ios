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
import ACPCore
@testable import ACPExperiencePlatform

class RequestCallbackHandlerTests: XCTestCase {
    private let requestEventId = "requestEventId"
    
    override func setUp() {
        continueAfterFailure = false // fail so nil checks stop execution
    }
    
    func testRegisterResponseHandler_thenInvokeResponseHandler() {
        let uniqueEventId = "123"
        var data: [String: Any] = [:]
        data["key1"] = "value1"
        data["key2"] = 2
        data[requestEventId] = uniqueEventId

        let mockResponseHandler = MockExperiencePlatformResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(uniqueEventId: uniqueEventId, responseHandler: mockResponseHandler)

        ResponseCallbackHandler.shared.invokeResponseHandler(eventData: data)
        
        XCTAssertEqual(1, mockResponseHandler.onResponseCalledTimes)
        XCTAssertEqual(3, mockResponseHandler.onResponseReceivedData.count)
        XCTAssertEqual("value1", mockResponseHandler.onResponseReceivedData["key1"] as? String)
        XCTAssertEqual(2, mockResponseHandler.onResponseReceivedData["key2"] as? Int)
        XCTAssertEqual(uniqueEventId, mockResponseHandler.onResponseReceivedData[requestEventId] as? String)
    }
    
    func testRegisterTwoResponseHandlers_thenInvokeResponseHandler() {
        let uniqueEventId = "123"
        var data: [String: Any] = [:]
        data["key1"] = "value1"
        data["key2"] = 2
        data[requestEventId] = uniqueEventId

        let mockResponseHandler1 = MockExperiencePlatformResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(uniqueEventId: "567", responseHandler: mockResponseHandler1)
        let mockResponseHandler2 = MockExperiencePlatformResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(uniqueEventId: uniqueEventId, responseHandler: mockResponseHandler2)

        ResponseCallbackHandler.shared.invokeResponseHandler(eventData: data)
        
        XCTAssertEqual(0, mockResponseHandler1.onResponseCalledTimes)
        XCTAssertEqual(1, mockResponseHandler2.onResponseCalledTimes)
        XCTAssertEqual(3, mockResponseHandler2.onResponseReceivedData.count)
        XCTAssertEqual("value1", mockResponseHandler2.onResponseReceivedData["key1"] as? String)
        XCTAssertEqual(2, mockResponseHandler2.onResponseReceivedData["key2"] as? Int)
        XCTAssertEqual(uniqueEventId, mockResponseHandler2.onResponseReceivedData[requestEventId] as? String)
    }
    
    func testNoRegisterResponseHandler_thenInvokeResponseHandler_doesNotCrash() {
        let uniqueEventId = "123"
        var data: [String: Any] = [:]
        data["key1"] = "value1"
        data["key2"] = 2
        data[requestEventId] = uniqueEventId
        
        XCTAssertNoThrow(ResponseCallbackHandler.shared.invokeResponseHandler(eventData: data), "invokeResponseHandler should skip if no registered handler")
    }
    
    func testNoRegisterResponseHandler_thenUnregisterResponseHandler_doesNotCrash() {
        let uniqueEventId = "123"
        XCTAssertNoThrow(ResponseCallbackHandler.shared.unregisterResponseHandler(uniqueEventId: uniqueEventId), "unregisterResponseHandler should skip if no registered handler")
    }
    
    func testRegisterResponseHandler_thenUnregisterResponseHandler() {
        let uniqueEventId = "123"
        var data: [String: Any] = [:]
        data["key1"] = "value1"
        data["key2"] = 2
        data[requestEventId] = uniqueEventId

        let mockResponseHandler = MockExperiencePlatformResponseHandler()
        ResponseCallbackHandler.shared.registerResponseHandler(uniqueEventId: uniqueEventId, responseHandler: mockResponseHandler)
        ResponseCallbackHandler.shared.unregisterResponseHandler(uniqueEventId: uniqueEventId)

        ResponseCallbackHandler.shared.invokeResponseHandler(eventData: data) // should not call the callback
        
        XCTAssertEqual(0, mockResponseHandler.onResponseCalledTimes)
    }
    
    func testRegisterResponseHandler_withEmptyUniqueEvent_doesNotCrash() {
        XCTAssertNoThrow(ResponseCallbackHandler.shared.registerResponseHandler(uniqueEventId: "", responseHandler: MockExperiencePlatformResponseHandler()))
    }
    
    func testRegisterResponseHandlers_withNilResponseHandler_thenInvokeResponseHandler_doesNotCrash() {
        let uniqueEventId = "123"
        ResponseCallbackHandler.shared.registerResponseHandler(uniqueEventId: uniqueEventId, responseHandler: nil)
        XCTAssertNoThrow(ResponseCallbackHandler.shared.invokeResponseHandler(eventData: ["key":"value"]), "invokeResponseHandler should skip when nil responseHandler")
    }
    
    func testRegisterResponseHandlers_withNilResponseHandler_thenUnregisterResponseHandler_doesNotCrash() {
        let uniqueEventId = "123"
        ResponseCallbackHandler.shared.registerResponseHandler(uniqueEventId: uniqueEventId, responseHandler: nil)
        XCTAssertNoThrow(ResponseCallbackHandler.shared.unregisterResponseHandler(uniqueEventId: uniqueEventId), "unregisterResponseHandler should skip when nil responseHandler")
    }
    
    func testUnregisterResponseHandler_withEmptyUniqueEvent_doesNotCrash() {
        XCTAssertNoThrow(ResponseCallbackHandler.shared.unregisterResponseHandler(uniqueEventId: ""), "unregisterResponseHandler should skip when empty unique event id")
    }
}

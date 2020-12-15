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

class NetworkResponseHandlerFunctionalTests: FunctionalTestBase {
    private let event1 = Event(name: "e1", type: "eventType", source: "eventSource", data: nil)
    private let event2 = Event(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private let networkResponseHandler = NetworkResponseHandler()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: processResponseOnError

    func testProcessResponseOnError_WhenEmptyJsonError_doesNotHandleError() {
        let jsonError = ""
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: "123")
        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(0, dispatchEvents.count)
    }

    func testProcessResponseOnError_WhenInvalidJsonError_doesNotHandleError() {
        let jsonError = "{ ivalid json }"
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: "123")
        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(0, dispatchEvents.count)
    }

    func testProcessResponseOnError_WhenGenericJsonError_dispatchesEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1)
        let jsonError = "{\n" +
            "\"type\": \"https://ns.adobe.com/aep/errors/EXEG-0201-503\",\n" +
            "\"title\": \"Request to Data platform failed with an unknown exception\"" +
            "\n}"
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: "123")
        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT, timeout: 5)
        XCTAssertEqual(1, dispatchEvents.count)

        guard let receivedData = dispatchEvents[0].data else {
            XCTFail("Invalid event data")
            return
        }

        let flattenReceivedData: [String: Any] = flattenDictionary(dict: receivedData)
        XCTAssertEqual(3, flattenReceivedData.count)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0201-503", flattenReceivedData["type"] as? String)
        XCTAssertEqual("Request to Data platform failed with an unknown exception", flattenReceivedData["title"] as? String)
        XCTAssertEqual("123", flattenReceivedData["requestId"] as? String)
    }

    func testProcessResponseOnError_WhenOneEventJsonError_dispatchesEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1)
        let jsonError = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [],\n" +
            "      \"errors\": [\n" +
            "        {\n" +
            "          \"status\": 500,\n" +
            "          \"type\": \"https://ns.adobe.com/aep/errors/EXEG-0201-503\",\n" +
            "          \"title\": \"Failed due to unrecoverable system error: java.lang.IllegalStateException: Expected BEGIN_ARRAY but was BEGIN_OBJECT at path $.commerce.purchases\"\n"
            +
            "        }\n" +
            "      ]\n" +
            "    }"
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: "123")
        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(1, dispatchEvents.count)

        guard let receivedData = dispatchEvents[0].data else {
            XCTFail("Invalid event data")
            return
        }

        let flattenReceivedData: [String: Any] = flattenDictionary(dict: receivedData)
        XCTAssertEqual(4, flattenReceivedData.count)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0201-503", flattenReceivedData["type"] as? String)
        XCTAssertEqual(500, flattenReceivedData["status"] as? Int)
        XCTAssertEqual("Failed due to unrecoverable system error: java.lang.IllegalStateException: Expected BEGIN_ARRAY but was BEGIN_OBJECT at path $.commerce.purchases", flattenReceivedData["title"] as? String)
        XCTAssertEqual("123", flattenReceivedData["requestId"] as? String)
    }

    func testProcessResponseOnError_WhenValidEventIndex_dispatchesPairedEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1)
        let requestId = "123"
        let jsonError =  "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [],\n" +
            "      \"errors\": [\n" +
            "        {\n" +
            "          \"status\": 100,\n" +
            "          \"type\": \"personalization\",\n" +
            "          \"title\": \"Button color not found\",\n" +
            "           \"eventIndex\": 0\n" +
            "        }\n" +
            "      ]\n" +
            "    }"
        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: requestId)
        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(1, dispatchEvents.count)

        guard let receivedData = dispatchEvents[0].data else {
            XCTFail("Invalid event data")
            return
        }

        let flattenReceivedData: [String: Any] = flattenDictionary(dict: receivedData)
        XCTAssertEqual(6, flattenReceivedData.count)
        XCTAssertEqual("personalization", flattenReceivedData["type"] as? String)
        XCTAssertEqual(100, flattenReceivedData["status"] as? Int)
        XCTAssertEqual("Button color not found", flattenReceivedData["title"] as? String)
        XCTAssertEqual(0, flattenReceivedData["eventIndex"] as? Int)
        XCTAssertEqual(requestId, flattenReceivedData["requestId"] as? String)
        XCTAssertEqual(event1.id.uuidString, flattenReceivedData["requestEventId"] as? String)
    }

    func testProcessResponseOnError_WhenUnknownEventIndex_doesNotCrash() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1)
        let requestId = "123"
        let jsonError =  "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [],\n" +
            "      \"errors\": [\n" +
            "        {\n" +
            "          \"status\": 100,\n" +
            "          \"type\": \"personalization\",\n" +
            "          \"title\": \"Button color not found\",\n" +
            "           \"eventIndex\": 10\n" +
            "        }\n" +
            "      ]\n" +
            "    }"
        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: requestId)
        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(1, dispatchEvents.count)

        guard let receivedData = dispatchEvents[0].data else {
            XCTFail("Invalid event data")
            return
        }

        let flattenReceivedData: [String: Any] = flattenDictionary(dict: receivedData)
        XCTAssertEqual(5, flattenReceivedData.count)
        XCTAssertEqual("personalization", flattenReceivedData["type"] as? String)
        XCTAssertEqual(100, flattenReceivedData["status"] as? Int)
        XCTAssertEqual("Button color not found", flattenReceivedData["title"] as? String)
        XCTAssertEqual(10, flattenReceivedData["eventIndex"] as? Int)
        XCTAssertEqual(requestId, flattenReceivedData["requestId"] as? String)
    }
    func testProcessResponseOnError_WhenUnknownRequestId_doesNotCrash() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1)
        let requestId = "123"
        let jsonError =  "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [],\n" +
            "      \"errors\": [\n" +
            "        {\n" +
            "          \"status\": 100,\n" +
            "          \"type\": \"personalization\",\n" +
            "          \"title\": \"Button color not found\",\n" +
            "           \"eventIndex\": 0\n" +
            "        }\n" +
            "      ]\n" +
            "    }"
        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: "567")
        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(1, dispatchEvents.count)

        guard let receivedData = dispatchEvents[0].data else {
            XCTFail("Invalid event data")
            return
        }

        let flattenReceivedData: [String: Any] = flattenDictionary(dict: receivedData)
        XCTAssertEqual(5, flattenReceivedData.count)
        XCTAssertEqual("personalization", flattenReceivedData["type"] as? String)
        XCTAssertEqual(100, flattenReceivedData["status"] as? Int)
        XCTAssertEqual("Button color not found", flattenReceivedData["title"] as? String)
        XCTAssertEqual(0, flattenReceivedData["eventIndex"] as? Int)
        XCTAssertEqual("567", flattenReceivedData["requestId"] as? String)
    }
    func testProcessResponseOnError_WhenTwoEventJsonError_dispatchesTwoEvents() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 2)
        let requestId = "123"
        let jsonError =  "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [],\n" +
            "      \"errors\": [\n" +
            "        {\n" +
            "          \"status\": 0,\n" +
            "          \"type\": \"https://ns.adobe.com/aep/errors/EXEG-0201-503\",\n" +
            "          \"title\": \"Failed due to unrecoverable system error: java.lang.IllegalStateException: Expected BEGIN_ARRAY but was BEGIN_OBJECT at path $.commerce.purchases\"\n"
            +
            "        },\n" +
            "        {\n" +
            "          \"status\": 2003,\n" +
            "          \"type\": \"personalization\",\n" +
            "          \"title\": \"Failed to process personalization event\"\n" +
            "        }\n" +
            "      ]\n" +
            "    }"
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: requestId)
        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(2, dispatchEvents.count)

        guard let receivedData1 = dispatchEvents[0].data else {
            XCTFail("Invalid event data for event 1")
            return
        }
        let flattenReceivedData1: [String: Any] = flattenDictionary(dict: receivedData1)
        XCTAssertEqual(4, flattenReceivedData1.count)
        XCTAssertEqual(0, flattenReceivedData1["status"] as? Int)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0201-503", flattenReceivedData1["type"] as? String)
        XCTAssertEqual("Failed due to unrecoverable system error: java.lang.IllegalStateException: Expected BEGIN_ARRAY but was BEGIN_OBJECT at path $.commerce.purchases", flattenReceivedData1["title"] as? String)
        XCTAssertEqual(requestId, flattenReceivedData1["requestId"] as? String)

        guard let receivedData2 = dispatchEvents[1].data else {
            XCTFail("Invalid event data for event 2")
            return
        }
        let flattenReceivedData2: [String: Any] = flattenDictionary(dict: receivedData2)
        XCTAssertEqual(4, flattenReceivedData2.count)
        XCTAssertEqual(2003, flattenReceivedData2["status"] as? Int)
        XCTAssertEqual("personalization", flattenReceivedData2["type"] as? String)
        XCTAssertEqual("Failed to process personalization event", flattenReceivedData2["title"] as? String)
        XCTAssertEqual(requestId, flattenReceivedData2["requestId"] as? String)
    }
    // MARK: processResponseOnSuccess

    func testProcessResponseOnSuccess_WhenEmptyJsonResponse_doesNotDispatchEvent() {
        let jsonResponse = ""
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "123")
        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE,
                                                     source: FunctionalTestConst.EventSource.RESPONSE_CONTENT)
        XCTAssertEqual(0, dispatchEvents.count)
    }

    func testProcessResponseOnSuccess_WhenInvalidJsonResponse_doesNotDispatchEvent() {
        let jsonResponse = "{ ivalid json }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "123")
        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE,
                                                     source: FunctionalTestConst.EventSource.RESPONSE_CONTENT)
        XCTAssertEqual(0, dispatchEvents.count)
    }

    func testProcessResponseOnSuccess_WhenOneEventHandle_dispatchesEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"state:store\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"key\": \"s_ecid\",\n" +
            "                    \"value\": \"MCMID|29068398647607325310376254630528178721\",\n" +
            "                    \"maxAge\": 15552000\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "123")

        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: "state:store")
        XCTAssertEqual(1, dispatchEvents.count)
        guard let receivedData = dispatchEvents[0].data else {
            XCTFail("Invalid event data")
            return
        }

        let flattenReceivedData: [String: Any] = flattenDictionary(dict: receivedData)
        XCTAssertEqual(5, flattenReceivedData.count)
        XCTAssertEqual("state:store", flattenReceivedData["type"] as? String)
        XCTAssertEqual("123", flattenReceivedData["requestId"] as? String)
        XCTAssertEqual("s_ecid", flattenReceivedData["payload[0].key"] as? String)
        XCTAssertEqual("MCMID|29068398647607325310376254630528178721", flattenReceivedData["payload[0].value"] as? String)
        XCTAssertEqual(15552000, flattenReceivedData["payload[0].maxAge"] as? Int)
    }

    func testProcessResponseOnSuccess_WhenOneEventHandle_emptyEventHandleType_dispatchesEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"key\": \"s_ecid\",\n" +
            "                    \"value\": \"MCMID|29068398647607325310376254630528178721\",\n" +
            "                    \"maxAge\": 15552000\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "123")

        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT)
        XCTAssertEqual(1, dispatchEvents.count)
        guard let receivedData = dispatchEvents[0].data else {
            XCTFail("Invalid event data")
            return
        }

        let flattenReceivedData: [String: Any] = flattenDictionary(dict: receivedData)
        XCTAssertEqual(5, flattenReceivedData.count)
        XCTAssertEqual("123", flattenReceivedData["requestId"] as? String)
        XCTAssertEqual("s_ecid", flattenReceivedData["payload[0].key"] as? String)
        XCTAssertEqual("MCMID|29068398647607325310376254630528178721", flattenReceivedData["payload[0].value"] as? String)
        XCTAssertEqual(15552000, flattenReceivedData["payload[0].maxAge"] as? Int)
    }

    func testProcessResponseOnSuccess_WhenOneEventHandle_nilEventHandleType_dispatchesEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"key\": \"s_ecid\",\n" +
            "                    \"value\": \"MCMID|29068398647607325310376254630528178721\",\n" +
            "                    \"maxAge\": 15552000\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "123")

        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT)
        XCTAssertEqual(1, dispatchEvents.count)
        guard let receivedData = dispatchEvents[0].data else {
            XCTFail("Invalid event data")
            return
        }

        let flattenReceivedData: [String: Any] = flattenDictionary(dict: receivedData)
        XCTAssertEqual(4, flattenReceivedData.count)
        XCTAssertEqual("123", flattenReceivedData["requestId"] as? String)
        XCTAssertEqual("s_ecid", flattenReceivedData["payload[0].key"] as? String)
        XCTAssertEqual("MCMID|29068398647607325310376254630528178721", flattenReceivedData["payload[0].value"] as? String)
        XCTAssertEqual(15552000, flattenReceivedData["payload[0].maxAge"] as? Int)
    }

    func testProcessResponseOnSuccess_WhenTwoEventHandles_dispatchesTwoEvents() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT, expectedCount: 2)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "            {\n" +
            "            \"type\": \"state:store\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"key\": \"s_ecid\",\n" +
            "                    \"value\": \"MCMID|29068398647607325310376254630528178721\",\n" +
            "                    \"maxAge\": 15552000\n" +
            "                }\n" +
            "            ]},\n" +
            "           {\n" +
            "            \"type\": \"identity:persist\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"id\": \"29068398647607325310376254630528178721\",\n" +
            "                    \"namespace\": {\n" +
            "                        \"code\": \"ECID\"\n" +
            "                    }\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "123")

        var dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: "state:store")
        dispatchEvents += getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: "identity:persist")
        XCTAssertEqual(2, dispatchEvents.count)
        // verify event 1
        guard let receivedData1 = dispatchEvents[0].data else {
            XCTFail("Invalid event data for event 1")
            return
        }
        let flattenReceivedData1: [String: Any] = flattenDictionary(dict: receivedData1)
        XCTAssertEqual(5, flattenReceivedData1.count)
        XCTAssertEqual("state:store", flattenReceivedData1["type"] as? String)
        XCTAssertEqual("123", flattenReceivedData1["requestId"] as? String)
        XCTAssertEqual("s_ecid", flattenReceivedData1["payload[0].key"] as? String)
        XCTAssertEqual("MCMID|29068398647607325310376254630528178721", flattenReceivedData1["payload[0].value"] as? String)
        XCTAssertEqual(15552000, flattenReceivedData1["payload[0].maxAge"] as? Int)

        // verify event 2
        guard let receivedData2 = dispatchEvents[1].data else {
            XCTFail("Invalid event data for event 2")
            return
        }
        let flattenReceivedData2: [String: Any] = flattenDictionary(dict: receivedData2)
        XCTAssertEqual(4, flattenReceivedData2.count)
        XCTAssertEqual("identity:persist", flattenReceivedData2["type"] as? String)
        XCTAssertEqual("123", flattenReceivedData2["requestId"] as? String)
        XCTAssertEqual("29068398647607325310376254630528178721", flattenReceivedData2["payload[0].id"] as? String)
        XCTAssertEqual("ECID", flattenReceivedData2["payload[0].namespace.code"] as? String)
    }

    func testProcessResponseOnSuccess_WhenEventHandleWithEventIndex_dispatchesEventWithRequestEventId() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT, expectedCount: 2)
        let requestId = "123"
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "            {\n" +
            "            \"type\": \"state:store\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"key\": \"s_ecid\",\n" +
            "                    \"value\": \"MCMID|29068398647607325310376254630528178721\",\n" +
            "                    \"maxAge\": 15552000\n" +
            "                }\n" +
            "            ]},\n" +
            "           {\n" +
            "            \"type\": \"pairedeventexample\",\n" +
            "            \"eventIndex\": 1,\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"id\": \"123612123812381\"\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: requestId)

        // verify event 1
        var dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE,
                                                     source: "state:store")
        dispatchEvents += getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE,
                                                  source: "pairedeventexample")
        XCTAssertEqual(2, dispatchEvents.count)
        guard let receivedData1 = dispatchEvents[0].data else {
            XCTFail("Invalid event data for event 1")
            return
        }
        let flattenReceivedData1: [String: Any] = flattenDictionary(dict: receivedData1)
        XCTAssertEqual(5, flattenReceivedData1.count)
        XCTAssertEqual("state:store", flattenReceivedData1["type"] as? String)
        XCTAssertEqual("123", flattenReceivedData1["requestId"] as? String)
        XCTAssertEqual("s_ecid", flattenReceivedData1["payload[0].key"] as? String)
        XCTAssertEqual("MCMID|29068398647607325310376254630528178721", flattenReceivedData1["payload[0].value"] as? String)
        XCTAssertEqual(15552000, flattenReceivedData1["payload[0].maxAge"] as? Int)

        // verify event 2
        guard let receivedData2 = dispatchEvents[1].data else {
            XCTFail("Invalid event data for event 2")
            return
        }
        let flattenReceivedData2: [String: Any] = flattenDictionary(dict: receivedData2)
        XCTAssertEqual(5, flattenReceivedData2.count)
        XCTAssertEqual("pairedeventexample", flattenReceivedData2["type"] as? String)
        XCTAssertEqual("123", flattenReceivedData2["requestId"] as? String)
        XCTAssertEqual(1, flattenReceivedData2["eventIndex"] as? Int)
        XCTAssertEqual(event2.id.uuidString, flattenReceivedData2["requestEventId"] as? String)
        XCTAssertEqual("123612123812381", flattenReceivedData2["payload[0].id"] as? String)
    }

    func testProcessResponseOnSuccess_WhenEventHandleWithUnknownEventIndex_dispatchesUnpairedEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let requestId = "123"
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"pairedeventexample\",\n" +
            "            \"eventIndex\": 10,\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"id\": \"123612123812381\"\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"

        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: requestId)

        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: "pairedeventexample")
        XCTAssertEqual(1, dispatchEvents.count)
        guard let receivedData1 = dispatchEvents[0].data else {
            XCTFail("Invalid event data for event 1")
            return
        }
        let flattenReceivedData1: [String: Any] = flattenDictionary(dict: receivedData1)
        XCTAssertEqual(4, flattenReceivedData1.count)
        XCTAssertEqual("pairedeventexample", flattenReceivedData1["type"] as? String)
        XCTAssertEqual("123", flattenReceivedData1["requestId"] as? String)
        XCTAssertEqual(10, flattenReceivedData1["eventIndex"] as? Int)
        XCTAssertEqual("123612123812381", flattenReceivedData1["payload[0].id"] as? String)
    }

    func testProcessResponseOnSuccess_WhenUnknownRequestId_doesNotCrash() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE,
                            source: FunctionalTestConst.EventSource.RESPONSE_CONTENT,
                            expectedCount: 1)
        let requestId = "123"
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"pairedeventexample\",\n" +
            "            \"eventIndex\": 0,\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"id\": \"123612123812381\"\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"

        networkResponseHandler.addWaitingEvents(requestId: "567", batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: requestId)

        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE,
                                                     source: "pairedeventexample")
        XCTAssertEqual(1, dispatchEvents.count)
        guard let receivedData1 = dispatchEvents[0].data else {
            XCTFail("Invalid event data for event 1")
            return
        }
        let flattenReceivedData1: [String: Any] = flattenDictionary(dict: receivedData1)
        XCTAssertEqual(4, flattenReceivedData1.count)
        XCTAssertEqual("pairedeventexample", flattenReceivedData1["type"] as? String)
        XCTAssertEqual("123", flattenReceivedData1["requestId"] as? String)
        XCTAssertEqual(0, flattenReceivedData1["eventIndex"] as? Int)
        XCTAssertEqual("123612123812381", flattenReceivedData1["payload[0].id"] as? String)
    }

    // MARK: processResponseOnSuccess with mixed event handles, errors, warnings

    func testProcessResponseOnSuccess_WhenEventHandleAndError_dispatchesTwoEvents() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE,
                            source: FunctionalTestConst.EventSource.RESPONSE_CONTENT,
                            expectedCount: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE,
                            source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT,
                            expectedCount: 1)
        let requestId = "123"
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "            {\n" +
            "            \"type\": \"state:store\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"key\": \"s_ecid\",\n" +
            "                    \"value\": \"MCMID|29068398647607325310376254630528178721\",\n" +
            "                    \"maxAge\": 15552000\n" +
            "                }\n" +
            "            ]}],\n" +
            "      \"errors\": [" +
            "        {\n" +
            "          \"status\": 2003,\n" +
            "          \"type\": \"personalization\",\n" +
            "          \"title\": \"Failed to process personalization event\"\n" +
            "        }\n" +
            "       ]\n" +
            "    }"

        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: requestId)

        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: "state:store")
        XCTAssertEqual(1, dispatchEvents.count)
        guard let receivedData1 = dispatchEvents[0].data else {
            XCTFail("Invalid event data for event 1")
            return
        }
        let flattenReceivedData1: [String: Any] = flattenDictionary(dict: receivedData1)
        XCTAssertEqual(5, flattenReceivedData1.count)
        XCTAssertEqual("state:store", flattenReceivedData1["type"] as? String)
        XCTAssertEqual("123", flattenReceivedData1["requestId"] as? String)
        XCTAssertEqual("s_ecid", flattenReceivedData1["payload[0].key"] as? String)
        XCTAssertEqual("MCMID|29068398647607325310376254630528178721", flattenReceivedData1["payload[0].value"] as? String)
        XCTAssertEqual(15552000, flattenReceivedData1["payload[0].maxAge"] as? Int)

        let dispatchErrorEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(1, dispatchErrorEvents.count)
        guard let receivedData2 = dispatchErrorEvents[0].data else {
            XCTFail("Invalid event data for event 2")
            return
        }

        let flattenReceivedData2: [String: Any] = flattenDictionary(dict: receivedData2)
        XCTAssertEqual(4, flattenReceivedData2.count)
        XCTAssertEqual("personalization", flattenReceivedData2["type"] as? String)
        XCTAssertEqual(2003, flattenReceivedData2["status"] as? Int)
        XCTAssertEqual("Failed to process personalization event", flattenReceivedData2["title"] as? String)
        XCTAssertEqual("123", flattenReceivedData2["requestId"] as? String)
    }

    func testProcessResponseOnSuccess_WhenErrorAndWarning_dispatchesTwoEvents() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 2)
        let requestId = "123"
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [],\n" +
            "      \"errors\": [" +
            "        {\n" +
            "          \"status\": 2003,\n" +
            "          \"title\": \"Failed to process personalization event\",\n" +
            "          \"eventIndex\": 2 \n" +
            "        }\n" +
            "       ],\n" +
            "      \"warnings\": [" +
            "        {\n" +
            "          \"type\": \"https://ns.adobe.com/aep/errors/EXEG-0204-200\",\n" +
            "          \"status\": 98,\n" +
            "          \"title\": \"Some Informative stuff here\",\n" +
            "          \"eventIndex\": 10, \n" +
            "          \"report\": {" +
            "             \"cause\": {" +
            "                \"message\": \"Some Informative stuff here\",\n" +
            "                \"code\": 202\n" +
            "             }" +
            "          }" +
            "        }\n" +
            "       ]\n" +
            "    }"

        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: requestId)

        let dispatchEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(2, dispatchEvents.count)
        guard let receivedData1 = dispatchEvents[0].data else {
            XCTFail("Invalid event data for event 1")
            return
        }
        let flattenReceivedData1: [String: Any] = flattenDictionary(dict: receivedData1)
        XCTAssertEqual(4, flattenReceivedData1.count)
        XCTAssertEqual(2003, flattenReceivedData1["status"] as? Int)
        XCTAssertEqual("Failed to process personalization event", flattenReceivedData1["title"] as? String)
        XCTAssertEqual(2, flattenReceivedData1["eventIndex"] as? Int)
        XCTAssertEqual("123", flattenReceivedData1["requestId"] as? String)

        guard let receivedData2 = dispatchEvents[1].data else {
            XCTFail("Invalid event data for event 2")
            return
        }
        let flattenReceivedData2: [String: Any] = flattenDictionary(dict: receivedData2)
        XCTAssertEqual(7, flattenReceivedData2.count)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0204-200", flattenReceivedData2["type"] as? String)
        XCTAssertEqual(98, flattenReceivedData2["status"] as? Int)
        XCTAssertEqual("Some Informative stuff here", flattenReceivedData2["title"] as? String)
        XCTAssertEqual("Some Informative stuff here", flattenReceivedData2["report.cause.message"] as? String)
        XCTAssertEqual(202, flattenReceivedData2["report.cause.code"] as? Int)
        XCTAssertEqual(10, flattenReceivedData2["eventIndex"] as? Int)
        XCTAssertEqual("123", flattenReceivedData2["requestId"] as? String)
    }
}

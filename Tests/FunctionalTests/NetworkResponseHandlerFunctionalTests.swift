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
@testable import AEPServices
import AEPTestUtils
import XCTest

// swiftlint:disable type_body_length
class NetworkResponseHandlerFunctionalTests: TestBase, AnyCodableAsserts {
    private let event1 = Event(name: "e1", type: "eventType", source: "eventSource", data: nil)
    private let event2 = Event(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private let requestSendCompletionTrueEventData: [String: Any] = ["xdm": ["testString": "xdm"], "request": [ "sendCompletion": true ]]
    private let requestSendCompletionFalseEventData: [String: Any] = ["xdm": ["testString": "xdm"], "request": [ "sendCompletion": false ]]
    private var networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (_: String?, _: TimeInterval?) -> Void in  })
    private let dataStore = NamedCollectionDataStore(name: EdgeConstants.EXTENSION_NAME)

    override func setUp() {
        super.setUp()

        setExpectationEvent(type: TestConstants.EventType.HUB, source: TestConstants.EventSource.SHARED_STATE, expectedCount: 1)

        MobileCore.registerExtensions([InstrumentedExtension.self]) // start MobileCore
        continueAfterFailure = false

        assertExpectedEvents(ignoreUnexpectedEvents: false, timeout: 2)
        resetTestExpectations()
    }

    // MARK: processResponseOnError

    func testProcessResponseOnError_WhenEmptyJsonError_doesNotHandleError() {
        let jsonError = ""
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: "123")
        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(0, dispatchEvents.count)
    }

    func testProcessResponseOnError_WhenInvalidJsonError_doesNotHandleError() {
        let jsonError = "{ invalid json }"
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: "123")
        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(0, dispatchEvents.count)
    }

    func testProcessResponseOnError_WhenGenericJsonError_dispatchesEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1)
        let jsonError = "{\n" +
            "\"type\": \"https://ns.adobe.com/aep/errors/EXEG-0201-503\",\n" +
            "\"title\": \"Request to Data platform failed with an unknown exception\"" +
            "\n}"
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: "123")
        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, timeout: 5)
        XCTAssertEqual(1, dispatchEvents.count)

        let expected = """
        {
          "requestId": "123",
          "title": "Request to Data platform failed with an unknown exception",
          "type": "https://ns.adobe.com/aep/errors/EXEG-0201-503"
        }
        """

        assertEqual(expected: expected, actual: dispatchEvents[0])
    }

    func testProcessResponseOnError_WhenOneEventJsonError_dispatchesEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1)
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
        networkResponseHandler.addWaitingEvents(requestId: "123", batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: "123")
        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(1, dispatchEvents.count)

        // Parent ID chained to default event index 0
        XCTAssertEqual(event1.id, dispatchEvents[0].parentID)

        let expected = """
        {
          "requestEventId": "\(event1.id.uuidString)",
          "requestId": "123",
          "status": 500,
          "title": "Failed due to unrecoverable system error: java.lang.IllegalStateException: Expected BEGIN_ARRAY but was BEGIN_OBJECT at path $.commerce.purchases",
          "type": "https://ns.adobe.com/aep/errors/EXEG-0201-503"
        }
        """

        assertEqual(expected: expected, actual: dispatchEvents[0])
    }

    func testProcessResponseOnError_WhenValidEventIndex_dispatchesPairedEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1)
        let requestId = "123"
        let jsonError = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [],\n" +
            "      \"errors\": [\n" +
            "        {\n" +
            "          \"status\": 100,\n" +
            "          \"type\": \"personalization\",\n" +
            "          \"title\": \"Button color not found\",\n" +
            "          \"report\": {\n" +
            "            \"eventIndex\": 1\n" +
            "           }\n" +
            "        }\n" +
            "      ]\n" +
            "    }"
        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: requestId)
        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(1, dispatchEvents.count)

        // Parent ID chained to event with index 1
        XCTAssertEqual(event2.id, dispatchEvents[0].parentID)

        let expected = """
        {
          "requestEventId": "\(event2.id.uuidString)",
          "requestId": "\(requestId)",
          "status": 100,
          "title": "Button color not found",
          "type": "personalization"
        }
        """

        assertEqual(expected: expected, actual: dispatchEvents[0])
    }

    func testProcessResponseOnError_WhenUnknownEventIndex_doesNotCrash() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1)
        let requestId = "123"
        let jsonError = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [],\n" +
            "      \"errors\": [\n" +
            "        {\n" +
            "          \"status\": 100,\n" +
            "          \"type\": \"personalization\",\n" +
            "          \"title\": \"Button color not found\",\n" +
            "          \"report\": {\n" +
            "           \"eventIndex\": 10\n" +
            "           }\n" +
            "        }\n" +
            "      ]\n" +
            "    }"
        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: requestId)
        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(1, dispatchEvents.count)

        // Parent ID not chained as no event at index 10
        XCTAssertNil(dispatchEvents[0].parentID)

        let expected = """
        {
          "requestId": "\(requestId)",
          "status": 100,
          "title": "Button color not found",
          "type": "personalization"
        }
        """

        assertEqual(expected: expected, actual: dispatchEvents[0])
    }
    func testProcessResponseOnError_WhenUnknownRequestId_doesNotCrash() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1)
        let requestId = "123"
        let jsonError = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [],\n" +
            "      \"errors\": [\n" +
            "        {\n" +
            "          \"status\": 100,\n" +
            "          \"type\": \"personalization\",\n" +
            "          \"title\": \"Button color not found\",\n" +
            "          \"report\": {\n" +
            "           \"eventIndex\": 0\n" +
            "           }\n" +
            "        }\n" +
            "      ]\n" +
            "    }"
        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: "567")
        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(1, dispatchEvents.count)

        // Parent ID not chained as request ID is unknown (does not match any waiting event list)
        XCTAssertNil(dispatchEvents[0].parentID)

        let expected = """
        {
          "requestId": "567",
          "status": 100,
          "title": "Button color not found",
          "type": "personalization"
        }
        """

        assertEqual(expected: expected, actual: dispatchEvents[0])
    }
    func testProcessResponseOnError_WhenTwoEventJsonError_dispatchesTwoEvents() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 2)
        let requestId = "123"
        let jsonError = "{\n" +
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

        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: requestId)
        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(2, dispatchEvents.count)

        // Event chained to event1 as default event index is 0
        XCTAssertEqual(event1.id, dispatchEvents[0].parentID)

        let expected_event1 = """
        {
          "requestEventId": "\(event1.id.uuidString)",
          "requestId": "\(requestId)",
          "status": 0,
          "title": "Failed due to unrecoverable system error: java.lang.IllegalStateException: Expected BEGIN_ARRAY but was BEGIN_OBJECT at path $.commerce.purchases",
          "type": "https://ns.adobe.com/aep/errors/EXEG-0201-503"
        }
        """

        assertEqual(expected: expected_event1, actual: dispatchEvents[0])

        // Event chained to event1 as default event index is 0
        XCTAssertEqual(event1.id, dispatchEvents[1].parentID)

        let expected_event2 = """
        {
          "requestEventId": "\(event1.id.uuidString)",
          "requestId": "\(requestId)",
          "status": 2003,
          "title": "Failed to process personalization event",
          "type": "personalization"
        }
        """

        assertEqual(expected: expected_event2, actual: dispatchEvents[1])
    }
    // MARK: processResponseOnSuccess

    func testProcessResponseOnSuccess_WhenEmptyJsonResponse_doesNotDispatchEvent() {
        let jsonResponse = ""
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "123")
        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                     source: TestConstants.EventSource.RESPONSE_CONTENT)
        XCTAssertEqual(0, dispatchEvents.count)
    }

    func testProcessResponseOnSuccess_WhenInvalidJsonResponse_doesNotDispatchEvent() {
        let jsonResponse = "{ invalid json }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "123")
        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                     source: TestConstants.EventSource.RESPONSE_CONTENT)
        XCTAssertEqual(0, dispatchEvents.count)
    }

    /// Tests that when an event is processed after a reset event that the store payloads are saved
    func testProcessResponseOnSuccess_afterResetEvent_savesStorePayloads() {
        networkResponseHandler.setLastReset(date: Date(timeIntervalSince1970: Date().timeIntervalSince1970 - 10)) // date is before `event.timestamp`
        let event = Event(name: "test", type: "test-type", source: "test-source", data: nil)

        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8",
                                                batchedEvents: [event])

        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
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
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        // verify saved to store manager
        let storeResponsePayloadManager = StoreResponsePayloadManager(EdgeConstants.DataStoreKeys.STORE_NAME)
        XCTAssertFalse(storeResponsePayloadManager.getActivePayloadList().isEmpty)
    }

    func testProcessResponseOnSuccess_beforeResetEvent_doesNotSaveStorePayloads() {
        let event = Event(name: "test", type: "test-type", source: "test-source", data: nil)
        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8",
                                                batchedEvents: [event])

        networkResponseHandler.setLastReset(date: Date(timeIntervalSince1970: Date().timeIntervalSince1970 + 10)) // date is after `event.timestamp` // date is after `event.timestamp`

        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
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
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        // verify not saved to store manager
        let storeResponsePayloadManager = StoreResponsePayloadManager(EdgeConstants.DataStoreKeys.STORE_NAME)
        XCTAssertTrue(storeResponsePayloadManager.getActivePayloadList().isEmpty)
    }

    /// Tests that when an event is processed after a persisted reset event that the store payloads are saved
    func testProcessResponseOnSuccess_afterPersistedResetEvent_savesStorePayloads() {
        dataStore.set(key: EdgeConstants.DataStoreKeys.RESET_IDENTITIES_DATE, value: Date().timeIntervalSince1970 - 10) // date is before `event.timestamp`
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (_: String?, _: TimeInterval?) -> Void in  }) // loads reset time on init

        let event = Event(name: "test", type: "test-type", source: "test-source", data: nil)

        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8",
                                                batchedEvents: [event])

        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
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
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        // verify saved to store manager
        let storeResponsePayloadManager = StoreResponsePayloadManager(EdgeConstants.DataStoreKeys.STORE_NAME)
        XCTAssertFalse(storeResponsePayloadManager.getActivePayloadList().isEmpty)
    }

    /// Tests that when an event is processed before a persisted reset event that the store payloads are not saved
    func testProcessResponseOnSuccess_beforePersistedResetEvent_doesNotSaveStorePayloads() {
        let event = Event(name: "test", type: "test-type", source: "test-source", data: nil)

        dataStore.set(key: EdgeConstants.DataStoreKeys.RESET_IDENTITIES_DATE, value: Date().timeIntervalSince1970 + 10) // date is after `event.timestamp`
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (_: String?, _: TimeInterval?) -> Void in  }) // loads reset time on init
        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8",
                                                batchedEvents: [event])

        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
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
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        // verify not saved to store manager
        let storeResponsePayloadManager = StoreResponsePayloadManager(EdgeConstants.DataStoreKeys.STORE_NAME)
        XCTAssertTrue(storeResponsePayloadManager.getActivePayloadList().isEmpty)
    }

    func testProcessResponseOnSuccess_WhenOneEventHandle_dispatchesEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
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

        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: "state:store")
        XCTAssertEqual(1, dispatchEvents.count)

        let expected = """
        {
          "payload": [
            {
              "key": "s_ecid",
              "maxAge": 15552000,
              "value": "MCMID|29068398647607325310376254630528178721"
            }
          ],
          "requestId": "123",
          "type": "state:store"
        }
        """

        assertEqual(expected: expected, actual: dispatchEvents[0])
    }

    func testProcessResponseOnSuccess_WhenOneEventHandle_emptyEventHandlePayload_dispatchesEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"state:store\",\n" +
            "            \"payload\": []" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "123")

        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: "state:store")
        XCTAssertEqual(1, dispatchEvents.count)

        let expected = """
        {
          "payload": [],
          "requestId": "123",
          "type": "state:store"
        }
        """

        assertEqual(expected: expected, actual: dispatchEvents[0])
    }

    func testProcessResponseOnSuccess_WhenOneEventHandle_noEventHandlePayload_dispatchesEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"state:store\"\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "123")

        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: "state:store")
        XCTAssertEqual(1, dispatchEvents.count)

        let expected = """
        {
          "requestId": "123",
          "type": "state:store"
        }
        """

        assertEqual(expected: expected, actual: dispatchEvents[0])
    }

    func testProcessResponseOnSuccess_WhenOneEventHandle_emptyEventHandleType_dispatchesEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
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

        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT)
        XCTAssertEqual(1, dispatchEvents.count)

        let expected = """
        {
          "payload": [
            {
              "key": "s_ecid",
              "maxAge": 15552000,
              "value": "MCMID|29068398647607325310376254630528178721"
            }
          ],
          "requestId": "123",
          "type": "STRING_TYPE"
        }
        """

        assertExactMatch(
            expected: expected,
            actual: dispatchEvents[0],
            pathOptions: CollectionEqualCount(scope: .subtree), ValueTypeMatch(paths: "type"))
    }

    func testProcessResponseOnSuccess_WhenOneEventHandle_nilEventHandleType_dispatchesEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
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

        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT)
        XCTAssertEqual(1, dispatchEvents.count)

        let expected = """
        {
          "payload": [
            {
              "key": "s_ecid",
              "maxAge": 15552000,
              "value": "MCMID|29068398647607325310376254630528178721"
            }
          ],
          "requestId": "123"
        }
        """

        assertEqual(expected: expected, actual: dispatchEvents[0])
    }

    func testProcessResponseOnSuccess_WhenTwoEventHandles_dispatchesTwoEvents() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 2)
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

        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8", batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        var dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: "state:store")
        dispatchEvents += getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: "identity:persist")
        XCTAssertEqual(2, dispatchEvents.count)
        // Verify event 1
        // Event chained to event1 as default event index is 0
        XCTAssertEqual(event1.id, dispatchEvents[0].parentID)

        let expected_event1 = """
        {
          "payload": [
            {
              "key": "s_ecid",
              "maxAge": 15552000,
              "value": "MCMID|29068398647607325310376254630528178721"
            }
          ],
          "requestEventId": "\(event1.id.uuidString)",
          "requestId": "d81c93e5-7558-4996-a93c-489d550748b8",
          "type": "state:store"
        }
        """

        assertEqual(expected: expected_event1, actual: dispatchEvents[0])

        // Verify event 2
        // Event chained to event1 as default event index is 0
        XCTAssertEqual(event1.id, dispatchEvents[1].parentID)

        let expected_event2 = """
        {
          "payload": [
            {
              "id": "29068398647607325310376254630528178721",
              "namespace": {
                "code": "ECID"
              }
            }
          ],
          "requestEventId": "\(event1.id.uuidString)",
          "requestId": "d81c93e5-7558-4996-a93c-489d550748b8",
          "type": "identity:persist"
        }
        """

        assertEqual(expected: expected_event2, actual: dispatchEvents[1])
    }

    func testProcessResponseOnSuccess_WhenEventHandleWithEventIndex_dispatchesEventWithRequestEventId() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 2)
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

        // Verify
        var dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                     source: "state:store")
        dispatchEvents += getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                  source: "pairedeventexample")
        XCTAssertEqual(2, dispatchEvents.count)

        // Verify event 1
        // Event chained to event1 as default event index is 0
        XCTAssertEqual(event1.id, dispatchEvents[0].parentID)

        let expected_event1 = """
        {
          "payload": [
            {
              "key": "s_ecid",
              "maxAge": 15552000,
              "value": "MCMID|29068398647607325310376254630528178721"
            }
          ],
          "requestEventId": "\(event1.id.uuidString)",
          "requestId": "123",
          "type": "state:store"
        }
        """

        assertEqual(expected: expected_event1, actual: dispatchEvents[0])

        // Verify event 2
        // Event chained to event2 as event index is 1
        XCTAssertEqual(event2.id, dispatchEvents[1].parentID)

        let expected_event2 = """
        {
          "payload": [
            {
              "id": "123612123812381"
            }
          ],
          "requestEventId": "\(event2.id.uuidString)",
          "requestId": "123",
          "type": "pairedeventexample"
        }
        """

        assertEqual(expected: expected_event2, actual: dispatchEvents[1])
    }

    func testProcessResponseOnSuccess_WhenEventHandleWithUnknownEventIndex_dispatchesUnpairedEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
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

        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: "pairedeventexample")
        XCTAssertEqual(1, dispatchEvents.count)
        // Parent ID nil as event index does not match any waiting event
        XCTAssertNil(dispatchEvents[0].parentID)

        let expected = """
        {
          "payload": [
            {
              "id": "123612123812381"
            }
          ],
          "requestId": "123",
          "type": "pairedeventexample"
        }
        """

        assertEqual(expected: expected, actual: dispatchEvents[0])
    }

    func testProcessResponseOnSuccess_WhenUnknownRequestId_doesNotCrash() {
        setExpectationEvent(type: TestConstants.EventType.EDGE,
                            source: TestConstants.EventSource.RESPONSE_CONTENT,
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

        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                     source: "pairedeventexample")
        XCTAssertEqual(1, dispatchEvents.count)
        // Parent ID nil as request ID does not match any waiting events
        XCTAssertNil(dispatchEvents[0].parentID)

        let expected = """
        {
          "payload": [
            {
              "id": "123612123812381"
            }
          ],
          "requestId": "123",
          "type": "pairedeventexample"
        }
        """

        assertEqual(expected: expected, actual: dispatchEvents[0])
    }

    // MARK: processResponseOnSuccess with mixed event handles, errors, warnings

    func testProcessResponseOnSuccess_WhenEventHandleAndError_dispatchesTwoEvents() {
        setExpectationEvent(type: TestConstants.EventType.EDGE,
                            source: TestConstants.EventSource.RESPONSE_CONTENT,
                            expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.EDGE,
                            source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT,
                            expectedCount: 1)
        let requestId = "123"
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "            {\n" +
            "            \"type\": \"state:store\",\n" +
            "            \"eventIndex\": 1, \n" +
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
            "          \"title\": \"Failed to process personalization event\",\n" +
            "          \"report\": {\n" +
            "            \"eventIndex\": 1 \n" +
            "           }\n" +
            "        }\n" +
            "       ]\n" +
            "    }"

        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: requestId)

        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: "state:store")
        XCTAssertEqual(1, dispatchEvents.count)
        // Event chained to event2 as event index is 1
        XCTAssertEqual(event2.id, dispatchEvents[0].parentID)

        let expected_event = """
        {
          "payload": [
            {
              "key": "s_ecid",
              "maxAge": 15552000,
              "value": "MCMID|29068398647607325310376254630528178721"
            }
          ],
          "requestEventId": "\(event2.id.uuidString)",
          "requestId": "123",
          "type": "state:store"
        }
        """

        assertEqual(expected: expected_event, actual: dispatchEvents[0])

        let dispatchErrorEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(1, dispatchErrorEvents.count)
        // Event chained to event2 as event index is 1
        XCTAssertEqual(event2.id, dispatchErrorEvents[0].parentID)

        let expected_errorEvent = """
        {
          "requestEventId": "\(event2.id.uuidString)",
          "requestId": "123",
          "status": 2003,
          "title": "Failed to process personalization event",
          "type": "personalization"
        }
        """

        assertEqual(expected: expected_errorEvent, actual: dispatchErrorEvents[0])
    }

    func testProcessResponseOnSuccess_WhenErrorAndWarning_dispatchesTwoEvents() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 2)
        let requestId = "123"
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [],\n" +
            "      \"errors\": [" +
            "        {\n" +
            "          \"status\": 2003,\n" +
            "          \"title\": \"Failed to process personalization event\",\n" +
            "          \"report\": {\n" +
            "            \"eventIndex\": 1 \n" +
            "           }\n" +
            "        }\n" +
            "       ],\n" +
            "      \"warnings\": [" +
            "        {\n" +
            "          \"type\": \"https://ns.adobe.com/aep/errors/EXEG-0204-200\",\n" +
            "          \"status\": 98,\n" +
            "          \"title\": \"Some Informative stuff here\",\n" +
            "          \"report\": {" +
            "             \"eventIndex\": 0, \n" +
            "             \"cause\": {" +
            "                \"message\": \"Some Informative stuff here\",\n" +
            "                \"code\": 202\n" +
            "             }" +
            "          }" +
            "        }\n" +
            "       ]\n" +
            "    }"

        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: requestId)

        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(2, dispatchEvents.count)
        // Event chained to event2 as event index is 1
        XCTAssertEqual(event2.id, dispatchEvents[0].parentID)

        let expected_event1 = """
        {
          "requestEventId": "\(event2.id.uuidString)",
          "requestId": "123",
          "status": 2003,
          "title": "Failed to process personalization event"
        }
        """

        assertEqual(expected: expected_event1, actual: dispatchEvents[0])

        // Event chained to event1 as event index is 0
        XCTAssertEqual(event1.id, dispatchEvents[1].parentID)

        let expected_event2 = """
        {
          "report": {
            "cause": {
              "code": 202,
              "message": "Some Informative stuff here"
            }
          },
          "requestEventId": "\(event1.id.uuidString)",
          "requestId": "123",
          "status": 98,
          "title": "Some Informative stuff here",
          "type": "https://ns.adobe.com/aep/errors/EXEG-0204-200"
        }
        """

        assertEqual(expected: expected_event2, actual: dispatchEvents[1])
    }

    func testProcessResponseOnSuccess_WhenEventHandleAndErrorAndWarning_dispatchesThreeEvents() {
        setExpectationEvent(type: TestConstants.EventType.EDGE,
                            source: TestConstants.EventSource.RESPONSE_CONTENT,
                            expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.EDGE,
                            source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT,
                            expectedCount: 2)
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
            "       ],\n" +
            "      \"warnings\": [" +
            "        {\n" +
            "          \"type\": \"https://ns.adobe.com/aep/errors/EXEG-0204-200\",\n" +
            "          \"status\": 98,\n" +
            "          \"title\": \"Some Informative stuff here\",\n" +
            "          \"report\": {" +
            "             \"cause\": {" +
            "                \"message\": \"Some Informative stuff here\",\n" +
            "                \"code\": 202\n" +
            "             }" +
            "          }" +
            "        }\n" +
            "       ]\n" +
            "    }"

        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event1])
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: requestId)

        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: "state:store")
        XCTAssertEqual(1, dispatchEvents.count)
        // Event chained to event1 as event index defaults to 0
        XCTAssertEqual(event1.id, dispatchEvents[0].parentID)

        let expected_event = """
        {
          "payload": [
            {
              "key": "s_ecid",
              "maxAge": 15552000,
              "value": "MCMID|29068398647607325310376254630528178721"
            }
          ],
          "requestEventId": "\(event1.id.uuidString)",
          "requestId": "123",
          "type": "state:store"
        }
        """

        assertEqual(expected: expected_event, actual: dispatchEvents[0])

        let dispatchErrorEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        XCTAssertEqual(2, dispatchErrorEvents.count)
        // Event chained to event1 as event index defaults to 0
        XCTAssertEqual(event1.id, dispatchErrorEvents[0].parentID)

        let expected_errorEvent1 = """
        {
          "requestEventId": "\(event1.id.uuidString)",
          "requestId": "123",
          "status": 2003,
          "title": "Failed to process personalization event",
          "type": "personalization"
        }
        """

        assertEqual(expected: expected_errorEvent1, actual: dispatchErrorEvents[0])

        // Event chained to event1 as event index defaults to 0
        XCTAssertEqual(event1.id, dispatchErrorEvents[1].parentID)

        let expected_errorEvent2 = """
        {
          "report": {
            "cause": {
              "code": 202,
              "message": "Some Informative stuff here"
            }
          },
          "requestEventId": "\(event1.id.uuidString)",
          "requestId": "123",
          "status": 98,
          "title": "Some Informative stuff here",
          "type": "https://ns.adobe.com/aep/errors/EXEG-0204-200"
        }
        """

        assertEqual(expected: expected_errorEvent2, actual: dispatchErrorEvents[1])
    }

    // MARK: locationHint:result

    func testProcessResponseOnSuccess_WhenLocationHintResultEventHandle_dispatchesEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"locationHint:result\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"scope\": \"EdgeNetwork\",\n" +
            "                    \"hint\": \"or2\",\n" +
            "                    \"ttlSeconds\": 1800\n" +
            "                },\n" +
            "                {\n" +
            "                    \"scope\": \"Target\",\n" +
            "                    \"hint\": \"edge34\",\n" +
            "                    \"ttlSeconds\": 600\n" +
            "                }\n" +
            "            ]\n" +
            "        }]\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "123")

        let dispatchEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: "locationHint:result")
        XCTAssertEqual(1, dispatchEvents.count)

        let expected = """
        {
          "payload": [
            {
              "hint": "or2",
              "scope": "EdgeNetwork",
              "ttlSeconds": 1800
            },
            {
              "hint": "edge34",
              "scope": "Target",
              "ttlSeconds": 600
            }
          ],
          "requestId": "123",
          "type": "locationHint:result"
        }
        """

        assertEqual(expected: expected, actual: dispatchEvents[0])
    }

    /// Tests that when an event is processed after a reset event that the location hint is updated
    func testProcessResponseOnSuccess_afterResetEvent_updatesLocationHint() {
        var locationHintResultHint: String?
        var locationHintResultTtlSeconds: TimeInterval?
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (hint: String?, ttlSeconds: TimeInterval?) -> Void in
            locationHintResultHint = hint
            locationHintResultTtlSeconds = ttlSeconds
        })

        networkResponseHandler.setLastReset(date: Date(timeIntervalSince1970: Date().timeIntervalSince1970 - 10)) // date is before `event.timestamp`
        let event = Event(name: "test", type: "test-type", source: "test-source", data: nil)

        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8",
                                                batchedEvents: [event])

        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"locationHint:result\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"scope\": \"EdgeNetwork\",\n" +
            "                    \"hint\": \"or2\",\n" +
            "                    \"ttlSeconds\": 1800\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        // verify saved location hint
        XCTAssertEqual("or2", locationHintResultHint)
        XCTAssertEqual(1800, locationHintResultTtlSeconds)
    }

    func testProcessResponseOnSuccess_beforeResetEvent_doesNotUpdateLocationHint() {
        let event = Event(name: "test", type: "test-type", source: "test-source", data: nil)

        var locationHintResultHint: String?
        var locationHintResultTtlSeconds: TimeInterval?
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (hint: String?, ttlSeconds: TimeInterval?) -> Void in
            locationHintResultHint = hint
            locationHintResultTtlSeconds = ttlSeconds
        })

        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8",
                                                batchedEvents: [event])

        networkResponseHandler.setLastReset(date: Date(timeIntervalSince1970: Date().timeIntervalSince1970 + 10)) // date is after `event.timestamp` // date is after `event.timestamp`

        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"locationHint:result\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"scope\": \"EdgeNetwork\",\n" +
            "                    \"hint\": \"or2\",\n" +
            "                    \"ttlSeconds\": 1800\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        // verify location hint not saved
        XCTAssertNil(locationHintResultHint)
        XCTAssertNil(locationHintResultTtlSeconds)
    }

    /// Tests that when an event is processed after a persisted reset event that the location hint is updated
    func testProcessResponseOnSuccess_afterPersistedResetEvent_updatesLocationHint() {
        dataStore.set(key: EdgeConstants.DataStoreKeys.RESET_IDENTITIES_DATE, value: Date().timeIntervalSince1970 - 10) // date is before `event.timestamp`

        var locationHintResultHint: String?
        var locationHintResultTtlSeconds: TimeInterval?
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (hint: String?, ttlSeconds: TimeInterval?) -> Void in
            locationHintResultHint = hint
            locationHintResultTtlSeconds = ttlSeconds
        }) // loads reset time on init

        let event = Event(name: "test", type: "test-type", source: "test-source", data: nil)

        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8",
                                                batchedEvents: [event])

        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"locationHint:result\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"scope\": \"EdgeNetwork\",\n" +
            "                    \"hint\": \"or2\",\n" +
            "                    \"ttlSeconds\": 1800\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        // verify saved location hint
        XCTAssertEqual("or2", locationHintResultHint)
        XCTAssertEqual(1800, locationHintResultTtlSeconds)
    }

    /// Tests that when an event is processed before a persisted reset event that the location hint is not updated
    func testProcessResponseOnSuccess_beforePersistedResetEvent_doesNotUpdateLocationHint() {
        let event = Event(name: "test", type: "test-type", source: "test-source", data: nil)

        dataStore.set(key: EdgeConstants.DataStoreKeys.RESET_IDENTITIES_DATE, value: Date().timeIntervalSince1970 + 10) // date is after `event.timestamp`

        var locationHintResultHint: String?
        var locationHintResultTtlSeconds: TimeInterval?
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (hint: String?, ttlSeconds: TimeInterval?) -> Void in
            locationHintResultHint = hint
            locationHintResultTtlSeconds = ttlSeconds
        }) // loads reset time on init
        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8",
                                                batchedEvents: [event])

        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"locationHint:result\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"scope\": \"EdgeNetwork\",\n" +
            "                    \"hint\": \"or2\",\n" +
            "                    \"ttlSeconds\": 1800\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        // verify location hint not saved
        XCTAssertNil(locationHintResultHint)
        XCTAssertNil(locationHintResultTtlSeconds)
    }

    func testProcessResponseOnSuccess_whenEdgeNetworkNotInScope_doesNotUpdateLocationHint() {
        var locationHintResultHint: String?
        var locationHintResultTtlSeconds: TimeInterval?
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (hint: String?, ttlSeconds: TimeInterval?) -> Void in
            locationHintResultHint = hint
            locationHintResultTtlSeconds = ttlSeconds
        }) // loads reset time on init

        let event = Event(name: "test", type: "test-type", source: "test-source", data: nil)

        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8",
                                                batchedEvents: [event])

        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"locationHint:result\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"scope\": \"Target\",\n" +
            "                    \"hint\": \"edge34\",\n" +
            "                    \"ttlSeconds\": 1800\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        // verify location hint not saved
        XCTAssertNil(locationHintResultHint)
        XCTAssertNil(locationHintResultTtlSeconds)
    }

    func testProcessResponseOnSuccess_whenEventHandleHasBothStateStoreAndLocationHintResult_stateStoreSaved_locationHintUpdated() {
        var locationHintResultHint: String?
        var locationHintResultTtlSeconds: TimeInterval?
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (hint: String?, ttlSeconds: TimeInterval?) -> Void in
            locationHintResultHint = hint
            locationHintResultTtlSeconds = ttlSeconds
        }) // loads reset time on init

        let event = Event(name: "test", type: "test-type", source: "test-source", data: nil)

        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8",
                                                batchedEvents: [event])

        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"locationHint:result\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"scope\": \"EdgeNetwork\",\n" +
            "                    \"hint\": \"or2\",\n" +
            "                    \"ttlSeconds\": 1800\n" +
            "                }\n" +
            "            ]},\n" +
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
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        // verify saved location hint
        XCTAssertEqual("or2", locationHintResultHint)
        XCTAssertEqual(1800, locationHintResultTtlSeconds)

        // verify saved to store manager
        let storeResponsePayloadManager = StoreResponsePayloadManager(EdgeConstants.DataStoreKeys.STORE_NAME)
        XCTAssertFalse(storeResponsePayloadManager.getActivePayloadList().isEmpty)
    }

    func testProcessResponseOnSuccess_whenLocationHintHandleDoesNotHaveHint_thenLocationHintNotUpdated() {
        var locationHintResultHint: String?
        var locationHintResultTtlSeconds: TimeInterval?
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (hint: String?, ttlSeconds: TimeInterval?) -> Void in
            locationHintResultHint = hint
            locationHintResultTtlSeconds = ttlSeconds
        })

        let event = Event(name: "test", type: "test-type", source: "test-source", data: nil)

        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8",
                                                batchedEvents: [event])

        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"locationHint:result\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"scope\": \"EdgeNetwork\",\n" +
            "                    \"ttlSeconds\": 1800\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        // verify saved location hint
        XCTAssertNil(locationHintResultHint)
        XCTAssertNil(locationHintResultTtlSeconds)
    }

    func testProcessResponseOnSuccess_whenLocationHintHandleHasEmptyHint_thenLocationHintNotUpdated() {
        var locationHintResultHint: String?
        var locationHintResultTtlSeconds: TimeInterval?
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (hint: String?, ttlSeconds: TimeInterval?) -> Void in
            locationHintResultHint = hint
            locationHintResultTtlSeconds = ttlSeconds
        })

        let event = Event(name: "test", type: "test-type", source: "test-source", data: nil)

        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8",
                                                batchedEvents: [event])

        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"locationHint:result\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"scope\": \"EdgeNetwork\",\n" +
            "                    \"hint\": \"\",\n" +
            "                    \"ttlSeconds\": 1800\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        // verify saved location hint
        XCTAssertNil(locationHintResultHint)
        XCTAssertNil(locationHintResultTtlSeconds)
    }

    func testProcessResponseOnSuccess_whenLocationHintHandleDoesNotHaveTtl_thenLocationHintNotUpdated() {
        var locationHintResultHint: String?
        var locationHintResultTtlSeconds: TimeInterval?
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (hint: String?, ttlSeconds: TimeInterval?) -> Void in
            locationHintResultHint = hint
            locationHintResultTtlSeconds = ttlSeconds
        })

        let event = Event(name: "test", type: "test-type", source: "test-source", data: nil)

        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8",
                                                batchedEvents: [event])

        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"locationHint:result\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"scope\": \"EdgeNetwork\",\n" +
            "                    \"hint\": \"or2\"\n" +
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        // verify saved location hint
        XCTAssertNil(locationHintResultHint)
        XCTAssertNil(locationHintResultTtlSeconds)
    }

    func testProcessResponseOnSuccess_whenLocationHintHandleHasIncorrectTtlType_thenLocationHintNotUpdated() {
        var locationHintResultHint: String?
        var locationHintResultTtlSeconds: TimeInterval?
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (hint: String?, ttlSeconds: TimeInterval?) -> Void in
            locationHintResultHint = hint
            locationHintResultTtlSeconds = ttlSeconds
        })

        let event = Event(name: "test", type: "test-type", source: "test-source", data: nil)

        networkResponseHandler.addWaitingEvents(requestId: "d81c93e5-7558-4996-a93c-489d550748b8",
                                                batchedEvents: [event])

        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        let jsonResponse = "{\n" +
            "      \"requestId\": \"d81c93e5-7558-4996-a93c-489d550748b8\",\n" +
            "      \"handle\": [" +
            "           {\n" +
            "            \"type\": \"locationHint:result\",\n" +
            "            \"payload\": [\n" +
            "                {\n" +
            "                    \"scope\": \"EdgeNetwork\",\n" +
            "                    \"ttlSeconds\": \"1800\"\n" + // String but should be Int
            "                }\n" +
            "            ]\n" +
            "        }],\n" +
            "      \"errors\": []\n" +
            "    }"
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: "d81c93e5-7558-4996-a93c-489d550748b8")

        // verify saved location hint
        XCTAssertNil(locationHintResultHint)
        XCTAssertNil(locationHintResultTtlSeconds)
    }

    // MARK: processResponseOnComplete
    func testProcessResponseOnComplete_ifCompletionEventNotRequested_doesNotDispatchEvent() {
        networkResponseHandler.addWaitingEvent(requestId: "123", event: event1)
        networkResponseHandler.processResponseOnComplete(requestId: "123")

        assertUnexpectedEvents()
    }

    func testProcessResponseOnComplete_whenNoEventRequestsCompletion_thenNoEventDispatched() {
        networkResponseHandler.addWaitingEvents(requestId: "123", batchedEvents: [event1, event2])
        networkResponseHandler.processResponseOnComplete(requestId: "123")

        assertUnexpectedEvents()
    }

    func testProcessResponseOnComplete_whenEventRequestsCompletion_thenDispatchCompleteEvent() {
        let requestID = "123"
        let requestEvent1 = Event(name: "test1", type: "testType", source: "testSource", data: requestSendCompletionTrueEventData)
        networkResponseHandler.addWaitingEvent(requestId: requestID, event: requestEvent1)
        networkResponseHandler.processResponseOnComplete(requestId: requestID)
        let dispatchedEvents = getDispatchedEventsWith(type: EventType.edge, source: TestConstants.EventSource.CONTENT_COMPLETE)

        XCTAssertEqual(1, dispatchedEvents.count)

        let expectedEventData = """
        {
            "requestId": "\(requestID)"
        }
        """
        assertResponseCompleteEventWithData(expectedEventData: expectedEventData, parentEventIDs: [requestEvent1.id])
    }

    func testProcessResponseOnComplete_ifCompletionEventRequested_dispatchesEvent() {
        let requestID = "123"
        let requestEvent1 = Event(name: "test1", type: "testType", source: "testSource", data: requestSendCompletionTrueEventData)
        let requestEvent2 = Event(name: "test2", type: "testType", source: "testSource", data: nil)
        networkResponseHandler.addWaitingEvents(requestId: requestID, batchedEvents: [requestEvent1, requestEvent2])
        networkResponseHandler.processResponseOnComplete(requestId: requestID)

        let expectedEventData = """
        {
            "requestId": "\(requestID)"
        }
        """

        assertResponseCompleteEventWithData(expectedEventData: expectedEventData, parentEventIDs: [requestEvent1.id])
    }

    func testProcessResponseOnComplete_ifMultipleCompletionEventRequested_dispatchesMultipleEvents() {
        let requestID = "123"
        let requestEvent1 = Event(name: "test1", type: "testType", source: "testSource", data: requestSendCompletionTrueEventData)
        let requestEvent2 = Event(name: "test2", type: "testType", source: "testSource", data: requestSendCompletionTrueEventData)

        networkResponseHandler.addWaitingEvents(requestId: requestID, batchedEvents: [requestEvent1, requestEvent2])
        networkResponseHandler.processResponseOnComplete(requestId: requestID)

        let expectedEventData = """
        {
            "requestId": "\(requestID)"
        }
        """

        assertResponseCompleteEventWithData(expectedEventData: expectedEventData, parentEventIDs: [requestEvent1.id, requestEvent2.id])
    }

    func testProcessResponseOnComplete_ifCompletionEventRequestFalse_doesNotDispatchEvent() {
        let requestID = "123"
        let requestEvent1 = Event(name: "test1", type: "testType", source: "testSource", data: requestSendCompletionFalseEventData)
        let requestEvent2 = Event(name: "test2", type: "testType", source: "testSource", data: requestSendCompletionTrueEventData)

        networkResponseHandler.addWaitingEvents(requestId: requestID, batchedEvents: [requestEvent1, requestEvent2])
        networkResponseHandler.processResponseOnComplete(requestId: requestID)

        let expectedEventData = """
        {
            "requestId": "\(requestID)"
        }
        """

        assertResponseCompleteEventWithData(expectedEventData: expectedEventData, parentEventIDs: [requestEvent2.id])
    }

    private func assertResponseCompleteEventWithData(expectedEventData: String, parentEventIDs: [UUID], file: StaticString = #file, line: UInt = #line) {
        let dispatchedCompleteEvents = getDispatchedEventsWith(type: EventType.edge, source: TestConstants.EventSource.CONTENT_COMPLETE)
        XCTAssertEqual(parentEventIDs.count, dispatchedCompleteEvents.count)

        for (id, completeEvent) in zip(parentEventIDs, dispatchedCompleteEvents) {
            XCTAssertEqual(TestConstants.EventName.CONTENT_COMPLETE, completeEvent.name)
            XCTAssertEqual(TestConstants.EventType.EDGE, completeEvent.type)
            XCTAssertEqual(TestConstants.EventSource.CONTENT_COMPLETE, completeEvent.source)
            XCTAssertEqual(id, completeEvent.responseID)
            XCTAssertEqual(id, completeEvent.parentID)

            assertEqual(expected: expectedEventData, actual: completeEvent, file: file, line: line)
        }
    }
}

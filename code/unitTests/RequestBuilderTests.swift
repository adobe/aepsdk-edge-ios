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
@testable import AEPExperiencePlatform
import AEPServices
import XCTest

class RequestBuilderTests: XCTestCase {
    let testDataStoreName = "Testing"

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        ServiceProvider.shared.namedKeyValueService.remove(collectionName: testDataStoreName, key: "storePayloads")
    }

    func testGetRequestPayload_allParameters_verifyMetadata() {
        let request = RequestBuilder()
        request.enableResponseStreaming(recordSeparator: "A", lineFeed: "B")
        request.experienceCloudId = "ecid"

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["data": ["key": "value"]])

        let requestPayload = request.getRequestPayload([event])

        XCTAssertEqual("A", requestPayload?.meta?.konductorConfig?.streaming?.recordSeparator)
        XCTAssertEqual("B", requestPayload?.meta?.konductorConfig?.streaming?.lineFeed)
        XCTAssertTrue(requestPayload?.meta?.konductorConfig?.streaming?.enabled ?? false)
        guard let ecid = requestPayload?.xdm?.identityMap?.getItemsFor(namespace: "ECID")?[0] else {
            XCTFail("ECID missing")
            return
        }
        XCTAssertEqual("ecid", ecid.id)
    }

    func testGetRequestPayload_withEventXdm_verifyEventId_verifyTimestamp() {
        let request = RequestBuilder()
        request.enableResponseStreaming(recordSeparator: "A", lineFeed: "B")
        request.experienceCloudId = "ecid"

        var events: [Event] = []

        events.append(Event(name: "Request Test 1",
                            type: "type",
                            source: "source",
                            data: ["xdm": ["application": ["name": "myapp"]]]))

        events.append(Event(name: "Request Test 2",
                            type: "type",
                            source: "source",
                            data: ["xdm": ["environment": ["type": "widget"]]]))

        let requestPayload = request.getRequestPayload(events)

        let flattenEvent0: [String: Any] = flattenDictionary(dict: requestPayload?.events?[0]["xdm"]?.dictionaryValue ?? [:])
        let flattenEvent1: [String: Any] = flattenDictionary(dict: requestPayload?.events?[1]["xdm"]?.dictionaryValue ?? [:])
        XCTAssertEqual("myapp", flattenEvent0["application.name"] as? String)
        XCTAssertEqual(events[0].id.uuidString, flattenEvent0["_id"] as? String)
        XCTAssertEqual(timestampToISO8601(events[0].timestamp), flattenEvent0["timestamp"] as? String)

        XCTAssertEqual("widget", flattenEvent1["environment.type"] as? String)
        XCTAssertEqual(events[1].id.uuidString, flattenEvent1["_id"] as? String)
        XCTAssertEqual(timestampToISO8601(events[1].timestamp), flattenEvent1["timestamp"] as? String)
    }

    func testGetRequestPayload_withStorePayload_responseContainsStateEntries() {
        let manager = StoreResponsePayloadManager(testDataStoreName)
        manager.saveStorePayloads([StoreResponsePayload(payload: StorePayload(key: "key", value: "value", maxAge: 3600))])

        let request = RequestBuilder(dataStoreName: testDataStoreName)
        request.enableResponseStreaming(recordSeparator: "A", lineFeed: "B")
        request.experienceCloudId = "ecid"

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["data": ["key": "value"]])

        let requestPayload = request.getRequestPayload([event])

        XCTAssertEqual("key", requestPayload?.meta?.state?.entries?[0].key)
        XCTAssertEqual(3600.0, requestPayload?.meta?.state?.entries?[0].maxAge)
        XCTAssertEqual("value", requestPayload?.meta?.state?.entries?[0].value)
    }

    func testGetRequestPayload_withoutStorePayload_responseDoesNotContainsStateEntries() {
        let request = RequestBuilder(dataStoreName: testDataStoreName)
        request.enableResponseStreaming(recordSeparator: "A", lineFeed: "B")
        request.experienceCloudId = "ecid"

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["data": ["key": "value"]])

        let requestPayload = request.getRequestPayload([event])

        XCTAssertNil(requestPayload?.meta?.state)
    }

    func testGetRequestPayload_withDatasetId_responseContainsCollectMeta() {
        let request = RequestBuilder(dataStoreName: testDataStoreName)

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["data": ["key": "value"],
                                 "xdm": ["application": ["name": "myapp"]],
                                 "datasetId": "customDatasetId"])

        let requestPayload = request.getRequestPayload([event])

        let flattenEventMeta = flattenDictionary(dict: requestPayload?.events?[0]["meta"]?.dictionaryValue as! [String: Any])
        XCTAssertEqual(1, flattenEventMeta.count)
        XCTAssertEqual("customDatasetId", flattenEventMeta["collect.datasetId"] as? String)
        XCTAssertNil(requestPayload?.events?[0]["datasetId"])
        XCTAssertNotNil(requestPayload?.events?[0]["xdm"])
        XCTAssertNotNil(requestPayload?.events?[0]["data"])

        XCTAssertNil(requestPayload?.meta?.state)
    }

    func testGetRequestPayload_withoutDatasetId_responseDoesNotContainCollectMeta() {
        let request = RequestBuilder(dataStoreName: testDataStoreName)

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["data": ["key": "value"],
                                 "xdm": ["application": ["name": "myapp"]]])

        let requestPayload = request.getRequestPayload([event])

        XCTAssertNil(requestPayload?.events?[0]["meta"])
        XCTAssertNotNil(requestPayload?.events?[0]["xdm"])
        XCTAssertNotNil(requestPayload?.events?[0]["data"])
    }

    func testGetRequestPayload_withNilOrEmptyDatasetId_responseDoesNotContainCollectMeta() {
        let request = RequestBuilder(dataStoreName: testDataStoreName)

        let event1 = Event(name: "Request Test1",
                           type: "type",
                           source: "source",
                           data: ["xdm": ["application": ["name": "myapp"]],
                                  "datasetId": ""])

        let event2 = Event(name: "Request Test2",
                           type: "type",
                           source: "source",
                           data: ["data": ["key": "value"],
                                  "datasetId": "        "])

        var eventData: [String: Any] = [:]
        eventData["data"] = ["key": "value"]
        eventData["xdm"] = ["application": ["name": "myapp"]]
        eventData["datasetId"] = nil
        let event3 = Event(name: "Request Test3",
                           type: "type",
                           source: "source",
                           data: eventData)

        let requestPayload = request.getRequestPayload([event1, event2, event3])

        XCTAssertEqual(3, requestPayload?.events?.count)
        XCTAssertNil(requestPayload?.events?[0]["meta"])
        XCTAssertNil(requestPayload?.events?[0]["datasetId"])
        XCTAssertNotNil(requestPayload?.events?[0]["xdm"])
        XCTAssertNil(requestPayload?.events?[0]["data"])

        XCTAssertNil(requestPayload?.events?[1]["meta"])
        XCTAssertNil(requestPayload?.events?[1]["datasetId"])
        XCTAssertNotNil(requestPayload?.events?[1]["xdm"])
        XCTAssertNotNil(requestPayload?.events?[1]["data"])

        XCTAssertNil(requestPayload?.events?[2]["meta"])
        XCTAssertNil(requestPayload?.events?[2]["datasetId"])
        XCTAssertNotNil(requestPayload?.events?[2]["xdm"])
        XCTAssertNotNil(requestPayload?.events?[2]["data"])
    }
}

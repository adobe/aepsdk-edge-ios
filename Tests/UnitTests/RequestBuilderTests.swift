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
import AEPServices
import AEPTestUtils
import XCTest

class RequestBuilderTests: XCTestCase, AnyCodableAsserts {
    let testDataStoreName = "Testing"

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        ServiceProvider.shared.namedKeyValueService.remove(collectionName: testDataStoreName, key: "storePayloads")
    }

    func testGetPayloadWithExperienceEvents_allParameters_verifyMetadata() {
        let request = RequestBuilder()
        request.enableResponseStreaming(recordSeparator: "A", lineFeed: "B")
        request.xdmPayloads = AnyCodable.from(dictionary: buildIdentityMap())!
        request.sdkConfig = SDKConfig(datastream: Datastream(original: "datastreamID"))
        request.configOverrides = AnyCodable.from(dictionary: ["test": ["key": "val"]])

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["data": ["key": "value"]])

        let requestPayload = request.getPayloadWithExperienceEvents([event])

        XCTAssertEqual("A", requestPayload?.meta?.konductorConfig?.streaming?.recordSeparator)
        XCTAssertEqual("B", requestPayload?.meta?.konductorConfig?.streaming?.lineFeed)
        XCTAssertTrue(requestPayload?.meta?.konductorConfig?.streaming?.enabled ?? false)
        XCTAssertEqual("datastreamID", requestPayload?.meta?.sdkConfig?.datastream?.original)

        let expectedConfigOverrideJSON = #"""
        {
          "test": {
            "key": "val"
          }
        }
        """#
        assertEqual(expected: getAnyCodable(expectedConfigOverrideJSON)!, actual: AnyCodable(requestPayload?.meta?.configOverrides))
        
        let expectedRequestIdentityMapJSON = #"""
        {
          "ECID": [
            {
              "id": "ecid"
            }
          ]
        }
        """#
        // Does NOT strictly validate collection counts
        assertExactMatch(expected: getAnyCodable(expectedRequestIdentityMapJSON)!, actual: requestPayload?.xdm?["identityMap"])
    }

    func testGetPayloadWithExperienceEvents_withEventXdm_verifyEventId_verifyTimestamp() {
        let request = RequestBuilder()
        request.enableResponseStreaming(recordSeparator: "A", lineFeed: "B")
        request.xdmPayloads = AnyCodable.from(dictionary: buildIdentityMap())!

        var events: [Event] = []

        events.append(Event(name: "Request Test 1",
                            type: "type",
                            source: "source",
                            data: ["xdm": ["application": ["name": "myapp"]]]))

        events.append(Event(name: "Request Test 2",
                            type: "type",
                            source: "source",
                            data: ["xdm": ["environment": ["type": "widget"]]]))

        let requestPayload = request.getPayloadWithExperienceEvents(events)
        
        let expectedEvent0XDMJSON = #"""
        {
          "application": {
            "name": "myapp"
          },
          "_id": "\#(events[0].id.uuidString)",
          "timestamp": "\#(timestampToISO8601(events[0].timestamp))"
        }
        """#
        assertEqual(expected: getAnyCodable(expectedEvent0XDMJSON)!, actual: requestPayload?.events?[0]["xdm"])
        
        let expectedEvent1XDMJSON = #"""
        {
          "environment": {
            "type": "widget"
          },
          "_id": "\#(events[1].id.uuidString)",
          "timestamp": "\#(timestampToISO8601(events[1].timestamp))"
        }
        """#
        assertEqual(expected: getAnyCodable(expectedEvent1XDMJSON)!, actual: requestPayload?.events?[1]["xdm"])
    }

    func testGetPayloadWithExperienceEvents_withStorePayload_responseContainsStateEntries() {
        let manager = StoreResponsePayloadManager(testDataStoreName)
        manager.saveStorePayloads([StoreResponsePayload(payload: StorePayload(key: "key", value: "value", maxAge: 3600))])

        let request = RequestBuilder(dataStoreName: testDataStoreName)
        request.enableResponseStreaming(recordSeparator: "A", lineFeed: "B")
        request.xdmPayloads = AnyCodable.from(dictionary: buildIdentityMap())!

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["data": ["key": "value"]])

        let requestPayload = request.getPayloadWithExperienceEvents([event])

        XCTAssertEqual("key", requestPayload?.meta?.state?.entries?[0].key)
        XCTAssertEqual(3600.0, requestPayload?.meta?.state?.entries?[0].maxAge)
        XCTAssertEqual("value", requestPayload?.meta?.state?.entries?[0].value)
    }

    func testGetPayloadWithExperienceEvents_withoutStorePayload_responseDoesNotContainsStateEntries() {
        let request = RequestBuilder(dataStoreName: testDataStoreName)
        request.enableResponseStreaming(recordSeparator: "A", lineFeed: "B")
        request.xdmPayloads = AnyCodable.from(dictionary: buildIdentityMap())!

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["data": ["key": "value"]])

        let requestPayload = request.getPayloadWithExperienceEvents([event])

        XCTAssertNil(requestPayload?.meta?.state)
    }

    func testGetPayloadWithExperienceEvents_withDatasetId_responseContainsCollectMeta() {
        let request = RequestBuilder(dataStoreName: testDataStoreName)

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["data": ["key": "value"],
                                 "xdm": ["application": ["name": "myapp"]],
                                 "datasetId": "customDatasetId"])

        let requestPayload = request.getPayloadWithExperienceEvents([event])

        let expectedMetaJSON = #"""
        {
          "collect": {
            "datasetId": "customDatasetId"
          }
        }
        """#
        assertEqual(expected: getAnyCodable(expectedMetaJSON)!, actual: requestPayload?.events?[0]["meta"])
        
        XCTAssertNil(requestPayload?.events?[0]["datasetId"])
        XCTAssertNotNil(requestPayload?.events?[0]["xdm"])
        XCTAssertNotNil(requestPayload?.events?[0]["data"])

        XCTAssertNil(requestPayload?.meta?.state)
    }

    func testGetPayloadWithExperienceEvents_withoutDatasetId_responseDoesNotContainCollectMeta() {
        let request = RequestBuilder(dataStoreName: testDataStoreName)

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["data": ["key": "value"],
                                 "xdm": ["application": ["name": "myapp"]]])

        let requestPayload = request.getPayloadWithExperienceEvents([event])

        XCTAssertNil(requestPayload?.events?[0]["meta"])
        XCTAssertNotNil(requestPayload?.events?[0]["xdm"])
        XCTAssertNotNil(requestPayload?.events?[0]["data"])
    }

    func testGetPayloadWithExperienceEvents_withNilOrEmptyDatasetId_responseDoesNotContainCollectMeta() {
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

        let requestPayload = request.getPayloadWithExperienceEvents([event1, event2, event3])

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

    func testGetPayloadWithExperienceEvents_withQuery_responseContainsQuery() {
        let request = RequestBuilder(dataStoreName: testDataStoreName)

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["query": ["key": "value"]])

        let requestPayload = request.getPayloadWithExperienceEvents([event])
        
        let expectedQueryJSON = #"""
        {
          "key": "value"
        }
        """#
        // Strictly validates query collection count
        assertEqual(expected: getAnyCodable(expectedQueryJSON)!, actual: requestPayload?.events?[0]["query"])
    }

    func testGetPayloadWithExperienceEventsDoesNotOverwriteTimestampWhenValidTimestampPresent() {
        // setup
        let testTimestamp = "2021-06-01T00:00:20Z"
        let request = RequestBuilder(dataStoreName: testDataStoreName)

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["data": ["key": "value"],
                                 "xdm": ["application": ["name": "myapp"], "timestamp": testTimestamp]])

        // test
        let requestPayload = request.getPayloadWithExperienceEvents([event])

        // verify
        XCTAssertNotNil(requestPayload)
        XCTAssertEqual(1, requestPayload?.events?.count)
        let flattenEvent = flattenDictionary(dict: requestPayload?.events?[0]["xdm"]?.dictionaryValue ?? [:])
        XCTAssertEqual(testTimestamp, flattenEvent["timestamp"] as? String)
        
        let expectedXDMJSON = #"""
        {
          "timestamp": "\#(testTimestamp)"
        }
        """#
        assertExactMatch(expected: getAnyCodable(expectedXDMJSON)!, actual: requestPayload?.events?[0]["xdm"])
    }

    func testGetPayloadWithExperienceEventsDoesNotOverwriteTimestampWhenInvalidTimestampPresent() {
        // setup
        let testTimestamp = "invalidTimestamp"
        let request = RequestBuilder(dataStoreName: testDataStoreName)

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["data": ["key": "value"],
                                 "xdm": ["application": ["name": "myapp"], "timestamp": testTimestamp]])

        // test
        let requestPayload = request.getPayloadWithExperienceEvents([event])

        // verify
        XCTAssertNotNil(requestPayload)
        XCTAssertEqual(1, requestPayload?.events?.count)
        
        let expectedXDMJSON = #"""
        {
          "timestamp": "\#(testTimestamp)"
        }
        """#
        assertExactMatch(expected: getAnyCodable(expectedXDMJSON)!, actual: requestPayload?.events?[0]["xdm"])
    }

    func testGetPayloadWithExperienceEventsSetsEventTimestampWhenProvidedTimestampIsEmpty() {
        // setup
        let testTimestamp = ""
        let request = RequestBuilder(dataStoreName: testDataStoreName)

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["data": ["key": "value"],
                                 "xdm": ["application": ["name": "myapp"], "timestamp": testTimestamp]])

        // test
        let requestPayload = request.getPayloadWithExperienceEvents([event])

        // verify
        XCTAssertNotNil(requestPayload)
        XCTAssertEqual(1, requestPayload?.events?.count)
        
        let expectedXDMJSON = #"""
        {
          "timestamp": "\#(timestampToISO8601(event.timestamp))"
        }
        """#
        assertExactMatch(expected: getAnyCodable(expectedXDMJSON)!, actual: requestPayload?.events?[0]["xdm"])
    }

    func testGetPayloadWithExperienceEventsSetsEventTimestampWhenProvidedTimestampIsMissing() {
        // setup
        let request = RequestBuilder(dataStoreName: testDataStoreName)

        let event = Event(name: "Request Test",
                          type: "type",
                          source: "source",
                          data: ["data": ["key": "value"],
                                 "xdm": ["application": ["name": "myapp"]]])

        // test
        let requestPayload = request.getPayloadWithExperienceEvents([event])

        // verify
        XCTAssertNotNil(requestPayload)
        XCTAssertEqual(1, requestPayload?.events?.count)
        
        let expectedXDMJSON = #"""
        {
          "timestamp": "\#(timestampToISO8601(event.timestamp))"
        }
        """#
        assertExactMatch(expected: getAnyCodable(expectedXDMJSON)!, actual: requestPayload?.events?[0]["xdm"])
    }

    private func buildIdentityMap() -> [String: Any]? {
        guard let identityMapData = """
        {
            "identityMap": {
              "ECID" : [
                {
                  "authenticationState" : "ambiguous",
                  "id" : "ecid",
                  "primary" : false
                }
              ]
            }
        }
        """.data(using: .utf8) else {
            XCTFail("Failed to convert json string to data")
            return nil
        }
        let identityMap = try? JSONSerialization.jsonObject(with: identityMapData, options: []) as? [String: Any]
        return identityMap
    }
}

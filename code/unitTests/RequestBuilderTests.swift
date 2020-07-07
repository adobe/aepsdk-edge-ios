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
@testable import AEPExperiencePlatform

class RequestBuilderTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }
    
    func testGetRequestPayload_allParameters_verifyMetadata() {
        let request = RequestBuilder()
        request.enableResponseStreaming(recordSeparator: "A", lineFeed: "B")
        request.experienceCloudId = "ecid"
        
        
        let event = try? ACPExtensionEvent(name: "Request Test",
                                           type: "type",
                                           source: "source",
                                           data: ["data":["key":"value"]])
        
        let requestPayload = request.getRequestPayload([event!])
        
        XCTAssertEqual("A" , requestPayload?.meta?.konductorConfig?.streaming?.recordSeparator)
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
        
        var events: [ACPExtensionEvent] = []
        
        events.append(try! ACPExtensionEvent(name: "Request Test 1",
                                             type: "type",
                                             source: "source",
                                             data: ["xdm":["application":["name":"myapp"]]]))
        
        events.append(try! ACPExtensionEvent(name: "Request Test 2",
                                             type: "type",
                                             source: "source",
                                             data: ["xdm":["environment":["type":"widget"]]]))
        
        let requestPayload = request.getRequestPayload(events)
        
        let flattenEvent0 = flattenDictionary(dict: requestPayload?.events?[0]["xdm"]?.dictionaryValue as! [String : Any])
        let flattenEvent1 = flattenDictionary(dict: requestPayload?.events?[1]["xdm"]?.dictionaryValue as! [String : Any])
        XCTAssertEqual("myapp", flattenEvent0["application.name"] as? String)
        XCTAssertEqual(events[0].eventUniqueIdentifier, flattenEvent0["_id"] as? String)
        XCTAssertEqual(timestampToISO8601(events[0].eventTimestamp), flattenEvent0["timestamp"] as? String)
        
        XCTAssertEqual("widget", flattenEvent1["environment.type"] as? String)
        XCTAssertEqual(events[1].eventUniqueIdentifier, flattenEvent1["_id"] as? String)
        XCTAssertEqual(timestampToISO8601(events[1].eventTimestamp), flattenEvent1["timestamp"] as? String)
    }
    
    func testGetRequestPayload_withStorePayload_responseContainsStateEntries() {
        let dataStore = MockKeyValueStore()
        let manager = StoreResponsePayloadManager(dataStore)
        manager.saveStorePayloads([StoreResponsePayload(payload: StorePayload(key: "key", value: "value", maxAge: 3600))])
        
        let request = RequestBuilder(dataStore: dataStore)
        request.enableResponseStreaming(recordSeparator: "A", lineFeed: "B")
        request.experienceCloudId = "ecid"
        
        let event = try? ACPExtensionEvent(name: "Request Test",
                                           type: "type",
                                           source: "source",
                                           data: ["data":["key":"value"]])
        
        let requestPayload = request.getRequestPayload([event!])
        
        XCTAssertEqual("key", requestPayload?.meta?.state?.entries?[0].key)
        XCTAssertEqual(3600.0, requestPayload?.meta?.state?.entries?[0].maxAge)
        XCTAssertEqual("value", requestPayload?.meta?.state?.entries?[0].value)
    }
    
    func testGetRequestPayload_withoutStorePayload_responseDoesNotContainsStateEntries() {
        let request = RequestBuilder(dataStore: MockKeyValueStore())
        request.enableResponseStreaming(recordSeparator: "A", lineFeed: "B")
        request.experienceCloudId = "ecid"
        
        guard let event = try? ACPExtensionEvent(name: "Request Test",
                                                 type: "type",
                                                 source: "source",
                                                 data: ["data":["key":"value"]]) else {
                                                    XCTFail("Failed to create event without store payload")
                                                    return
        }
        
        let requestPayload = request.getRequestPayload([event])
        
        XCTAssertNil(requestPayload?.meta?.state)
    }
    
    func testGetRequestPayload_withDatasetId_responseContainsCollectMeta() {
        let request = RequestBuilder(dataStore: MockKeyValueStore())
        
        guard let event = try? ACPExtensionEvent(name: "Request Test",
                                                 type: "type",
                                                 source: "source",
                                                 data: ["data":["key":"value"],
                                                        "xdm":["application":["name":"myapp"]],
                                                        "datasetId": "customDatasetId"]) else {
                                                            XCTFail("Failed to create event with dataset id")
                                                            return
        }
        
        let requestPayload = request.getRequestPayload([event])
        
        let flattenEventMeta = flattenDictionary(dict: requestPayload?.events?[0]["meta"]?.dictionaryValue as! [String : Any])
        XCTAssertEqual(1, flattenEventMeta.count)
        XCTAssertEqual("customDatasetId", flattenEventMeta["collect.datasetId"] as? String)
        XCTAssertNil(requestPayload?.events?[0]["datasetId"])
        XCTAssertNotNil(requestPayload?.events?[0]["xdm"])
        XCTAssertNotNil(requestPayload?.events?[0]["data"])
        
        XCTAssertNil(requestPayload?.meta?.state)
    }
    
    func testGetRequestPayload_withoutDatasetId_responseDoesNotContainCollectMeta() {
        let request = RequestBuilder(dataStore: MockKeyValueStore())
        
        guard let event = try? ACPExtensionEvent(name: "Request Test",
                                                 type: "type",
                                                 source: "source",
                                                 data: ["data":["key":"value"],
                                                        "xdm":["application":["name":"myapp"]]]) else {
                                                            XCTFail("Failed to create event without dataset id")
                                                            return
        }
        
        let requestPayload = request.getRequestPayload([event])
        
        XCTAssertNil(requestPayload?.events?[0]["meta"])
        XCTAssertNotNil(requestPayload?.events?[0]["xdm"])
        XCTAssertNotNil(requestPayload?.events?[0]["data"])
    }
    
    func testGetRequestPayload_withNilOrEmptyDatasetId_responseDoesNotContainCollectMeta() {
        let request = RequestBuilder(dataStore: MockKeyValueStore())
        
        guard let event1 = try? ACPExtensionEvent(name: "Request Test1",
                                                  type: "type",
                                                  source: "source",
                                                  data: ["xdm":["application":["name":"myapp"]],
                                                         "datasetId": ""]) else {
                                                            XCTFail("Failed to create event with empty dataset id")
                                                            return
        }
        
        guard let event2 = try? ACPExtensionEvent(name: "Request Test2",
                                                  type: "type",
                                                  source: "source",
                                                  data: ["data":["key":"value"],
                                                         "datasetId": "        "]) else {
                                                            XCTFail("Failed to create event with dataset id which whitespaces only")
                                                            return
        }
        
        var eventData : [AnyHashable: Any] = [:]
        eventData["data"] = ["key":"value"]
        eventData["xdm"] = ["application":["name":"myapp"]]
        eventData["datasetId"] = nil
        guard let event3 = try? ACPExtensionEvent(name: "Request Test3",
                                                  type: "type",
                                                  source: "source",
                                                  data: eventData) else {
                                                    XCTFail("Failed to create event with nil dataset id")
                                                    return
        }
        
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

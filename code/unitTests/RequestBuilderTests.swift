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
        
        
        let event = try? ACPExtensionEvent(name: "Request Test",
                                           type: "type",
                                           source: "source",
                                           data: ["data":["key":"value"]])
        
        let requestPayload = request.getRequestPayload([event!])
        
        XCTAssertNil(requestPayload?.meta?.state)
    }
}

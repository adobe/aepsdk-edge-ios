/*
Copyright 2020 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import XCTest
import ACPCore
@testable import ACPExperiencePlatform

class RequestBuilderTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGetPayload_allParameters_verifyMetadata() {
        let request = RequestBuilder()
        request.organizationId = "orgID"
        request.recordSeparator = "A"
        request.lineFeed = "B"
        request.experienceCloudId = "ecid"

        
        let event = try? ACPExtensionEvent(name: "Request Test",
                                           type: "type",
                                           source: "source",
                                           data: ["data":["key":"value"]])
        
        let data = request.getPayload([event!])
        
        XCTAssertNotNil(data)
        
        let json = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:Any]
        
        guard let dict = json else {
            XCTFail("Failed to parse request payload to dictionary.")
            return
        }
        
        let flattenDict = flattenDictionary(dict: dict)
        
        XCTAssertEqual("orgID", flattenDict[".meta.konductorConfig.imsOrgId"] as? String)
        XCTAssertEqual("A" , flattenDict[".meta.konductorConfig.streaming.recordSeparator"] as? String)
        XCTAssertEqual("B", flattenDict[".meta.konductorConfig.streaming.lineFeed"] as? String)
        XCTAssertTrue(flattenDict[".meta.konductorConfig.streaming.enabled"] as? Bool ?? false)
        XCTAssertEqual("ecid", flattenDict[".xdm.identityMap.ECID[0].id"] as? String)
        
    }
    
    func testGetPayload_withEventXdm_verifyEventId_verifyTimestamp() {
        let request = RequestBuilder()
        request.organizationId = "orgID"
        request.recordSeparator = "A"
        request.lineFeed = "B"
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
        
        let data = request.getPayload(events)
        
        XCTAssertNotNil(data)
        
        let json = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:Any]
        
        guard let dict = json else {
            XCTFail("Failed to parse request payload to dictionary.")
            return
        }
        
        let flattenDict = flattenDictionary(dict: dict)
        XCTAssertEqual("myapp", flattenDict[".events[0].xdm.application.name"] as? String)
        XCTAssertEqual(events[0].eventUniqueIdentifier, flattenDict[".events[0].xdm.eventId"] as? String)
        XCTAssertEqual(timestampToISO8601(events[0].eventTimestamp), flattenDict[".events[0].xdm.timestamp"] as? String)
        
        XCTAssertEqual("widget", flattenDict[".events[1].xdm.environment.type"] as? String)
        XCTAssertEqual(events[1].eventUniqueIdentifier, flattenDict[".events[1].xdm.eventId"] as? String)
        XCTAssertEqual(timestampToISO8601(events[1].eventTimestamp), flattenDict[".events[1].xdm.timestamp"] as? String)
    }
    
    func testGetPayload_withStorePayload_responseContainsStateEntries() {
        let dataStore = MockKeyValueStore()
        let manager = StoreResponsePayloadManager(dataStore)
        manager.saveStorePayloads([StoreResponsePayload(key: "key", value: "value", maxAgeSeconds: 3600)])
        
        let request = RequestBuilder(dataStore: dataStore)
        request.organizationId = "orgID"
        request.recordSeparator = "A"
        request.lineFeed = "B"
        request.experienceCloudId = "ecid"

        
        let event = try? ACPExtensionEvent(name: "Request Test",
                                           type: "type",
                                           source: "source",
                                           data: ["data":["key":"value"]])
        
        let data = request.getPayload([event!])
        
        XCTAssertNotNil(data)
        
        let json = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:Any]
        
        guard let dict = json else {
            XCTFail("Failed to parse request payload to dictionary.")
            return
        }
        
        let flattenDict = flattenDictionary(dict: dict)
        
        XCTAssertEqual("key", flattenDict[".meta.state.entries[0].key"] as? String)
        XCTAssertEqual("value" , flattenDict[".meta.state.entries[0].value"] as? String)
        XCTAssertEqual(3600, flattenDict[".meta.state.entries[0].maxAge"] as? Int)
        XCTAssertNil(flattenDict[".meta.state.entries[0].expiryDate"])
    }
    
    func testGetPayload_withoutStorePayload_responseDoesNotContainsStateEntries() {
        let request = RequestBuilder(dataStore: MockKeyValueStore())
        request.organizationId = "orgID"
        request.recordSeparator = "A"
        request.lineFeed = "B"
        request.experienceCloudId = "ecid"

        
        let event = try? ACPExtensionEvent(name: "Request Test",
                                           type: "type",
                                           source: "source",
                                           data: ["data":["key":"value"]])
        
        let data = request.getPayload([event!])
        
        XCTAssertNotNil(data)
        
        let json = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String:Any]
        
        guard let dict = json else {
            XCTFail("Failed to parse request payload to dictionary.")
            return
        }
        
        let flattenDict = flattenDictionary(dict: dict)
        
        XCTAssertFalse(flattenDict.isEmpty)
        XCTAssertNil(flattenDict[".meta.state"])
    }
}

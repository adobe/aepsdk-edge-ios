//
// ADOBE CONFIDENTIAL
//
// Copyright 2020 Adobe
// All Rights Reserved.
//
// NOTICE: All information contained herein is, and remains
// the property of Adobe and its suppliers, if any. The intellectual
// and technical concepts contained herein are proprietary to Adobe
// and its suppliers and are protected by all applicable intellectual
// property laws, including trade secret and copyright laws.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from Adobe.
//

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
    
}

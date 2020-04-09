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
        let identity = flattenDict[".xdm.identityMap.ECID"] as? [[String: Any]]
        XCTAssertNotNil(identity)
        XCTAssertEqual(1, identity!.count)
        XCTAssertEqual("ecid", identity![0]["id"] as? String)
        
    }
    
    func flattenDictionary(dict: [String : Any]) -> [String : Any] {
        var result: [String : Any] = [:]
        
        func recursive(dict: [String : Any], out: inout [String : Any], currentKey: String = "") {
            for (key, val) in dict {
                let resultKey = currentKey + "." + key
                if let val = val as? [String : Any] {
                    recursive(dict: val, out: &out, currentKey: resultKey)
                } else {
                    out[resultKey] = val
                }
            }
        }
        recursive(dict: dict, out: &result)
        return result
    }
}

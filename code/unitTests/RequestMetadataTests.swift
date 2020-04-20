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
@testable import ACPExperiencePlatform

class RequestMetadataTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: encoder tests
    
    func testEncode_noParameters() {
        let metadata = RequestMetadata(konductorConfig: nil, state: nil)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(metadata)
        
        XCTAssertNotNil(data)
        let expected = """
            {

            }
            """
        let jsonString = String(data: data!, encoding: .utf8)
        print(jsonString!)
        
        XCTAssertEqual(expected, jsonString)
    }
    
    func testEncode_paramKonductorConfig() {
        let metadata = RequestMetadata(konductorConfig: KonductorConfig(imsOrgId: nil, streaming: nil),
                                       state: nil)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(metadata)
        
        XCTAssertNotNil(data)
        let expected = """
            {
              "konductorConfig" : {

              }
            }
            """
        let jsonString = String(data: data!, encoding: .utf8)
        print(jsonString!)
        
        XCTAssertEqual(expected, jsonString)
    }
    
    func testEncode_paramStateMetadata() {
        let payload = StorePayload(key: "key", value: "value", maxAge: 3600)
        let metadata = RequestMetadata(konductorConfig: nil, state: StateMetadata(payload: [payload]))
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(metadata)
        
        XCTAssertNotNil(data)
        let expected = """
            {
              "state" : {
                "entries" : [
                  {
                    "key" : "key",
                    "maxAge" : 3600,
                    "value" : "value"
                  }
                ]
              }
            }
            """
        let jsonString = String(data: data!, encoding: .utf8)
        print(jsonString!)
        
        XCTAssertEqual(expected, jsonString)
    }
    
    func testEncode_paramKonductorConfig_paramStateMetadata() {
        let payload = StorePayload(key: "key", value: "value", maxAge: 3600)
        let metadata = RequestMetadata(konductorConfig: KonductorConfig(imsOrgId: nil, streaming: nil),
                                       state: StateMetadata(payload: [payload]))
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(metadata)
        
        XCTAssertNotNil(data)
        let expected = """
            {
              "konductorConfig" : {

              },
              "state" : {
                "entries" : [
                  {
                    "key" : "key",
                    "maxAge" : 3600,
                    "value" : "value"
                  }
                ]
              }
            }
            """
        let jsonString = String(data: data!, encoding: .utf8)
        print(jsonString!)
        
        XCTAssertEqual(expected, jsonString)
    }
    
}

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

class StateMetadataTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: Encoder tests
    
    func testInit_withEmptyMap_doesNotEncodeEntries() {
        let state = StateMetadata(payload: [])
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(state)
        
        XCTAssertNotNil(data)
        let expected = """
        {

        }
        """
        let jsonString = String(data: data!, encoding: .utf8)
        XCTAssertEqual(expected, jsonString)
    }
    
    func testEncode_singlePayload() {
        let payload = [StorePayload(key: "key", value: "value", maxAge: 3600)]
        let state = StateMetadata(payload: payload)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(state)
        
        XCTAssertNotNil(data)
        let expected = """
        {
          "entries" : [
            {
              "key" : "key",
              "maxAge" : 3600,
              "value" : "value"
            }
          ]
        }
        """
        let jsonString = String(data: data!, encoding: .utf8)
        XCTAssertEqual(expected, jsonString)
    }
    
    func testEncode_multiplePayloads() {
        let payload = [StorePayload(key: "key", value: "value", maxAge: 3600),
                       StorePayload(key: "key2", value: "value2", maxAge: 5)]
        let state = StateMetadata(payload: payload)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(state)
        
        XCTAssertNotNil(data)
        let expected = """
        {
          "entries" : [
            {
              "key" : "key",
              "value" : "value",
              "maxAge" : 3600
            },
            {
              "key" : "key2",
              "value" : "value2",
              "maxAge" : 5
            }
          ]
        }
        """
        let jsonString = String(data: data!, encoding: .utf8)
        XCTAssertEqual(expected, jsonString)
    }
    
}

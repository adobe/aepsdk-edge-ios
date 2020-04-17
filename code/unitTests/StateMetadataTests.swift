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
    
    // MARK: Decoder tests
    
    func testDecode_multiplePayloads() {
        let data = """
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
        """.data(using: .utf8)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let state = try? decoder.decode(StateMetadata.self, from: data!)
        
        XCTAssertNotNil(state)
        XCTAssertNotNil(state?.entries)
        XCTAssertEqual(2, state?.entries?.count)
        XCTAssertEqual("key", state?.entries?[0].key)
        XCTAssertEqual("value", state?.entries?[0].value)
        XCTAssertEqual(3600, state?.entries?[0].maxAge)
        XCTAssertEqual("key2", state?.entries?[1].key)
        XCTAssertEqual("value2", state?.entries?[1].value)
        XCTAssertEqual(5, state?.entries?[1].maxAge)
    }
    
    func testDecode_emptyEntry_decodesEmptyEntries() {
        let data = """
         {
           "entries" : [
           ]
         }
        """.data(using: .utf8)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let state = try? decoder.decode(StateMetadata.self, from: data!)
        
        XCTAssertNotNil(state)
        XCTAssertNotNil(state?.entries)
        XCTAssertTrue(state?.entries?.isEmpty ?? false)
    }
    
    func testDecode_noEntries_decodesNilEntries() {
        let data = """
         {
         }
        """.data(using: .utf8)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let state = try? decoder.decode(StateMetadata.self, from: data!)
        
        XCTAssertNotNil(state)
        XCTAssertNil(state?.entries)
    }
    
}

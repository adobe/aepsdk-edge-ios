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

class KonductorConfigTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: Streaming encoder tests
    
    func testStreamingEncodeFromInitAll() {
        let streaming = Streaming(recordSeparator: "A",
                                  lineFeed: "B")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let streamingData = try? encoder.encode(streaming)
        
        XCTAssertNotNil(streamingData)
        let expected = """
            {
              "enabled" : true,
              "lineFeed" : "B",
              "recordSeparator" : "A"
            }
            """
        let jsonString = String(data: streamingData!, encoding: .utf8)
        print(jsonString!)
        
        XCTAssertEqual(expected, jsonString)
        
    }
    
    func testStreamingEncodeFromParametersAll() {
        var streaming = Streaming(recordSeparator: "A", lineFeed: "B")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let streamingData = try? encoder.encode(streaming)
        
        XCTAssertNotNil(streamingData)
        let expected = """
            {
              "enabled" : true,
              "lineFeed" : "B",
              "recordSeparator" : "A"
            }
            """
        let jsonString = String(data: streamingData!, encoding: .utf8)
        print(jsonString!)
        
        XCTAssertEqual(expected, jsonString)
    }
    
    func testStreamingEncodeWithNilRecordSeparator() {
        var streaming = Streaming(recordSeparator: nil, lineFeed: "B")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let streamingData = try? encoder.encode(streaming)
        
        XCTAssertNotNil(streamingData)
        let expected = """
            {
              "enabled" : false,
              "lineFeed" : "B"
            }
            """
        let jsonString = String(data: streamingData!, encoding: .utf8)
        print(jsonString!)
        
        XCTAssertEqual(expected, jsonString)
    }
    
    func testStreamingEncodeWithNilLineFeed() {
        var streaming = Streaming(recordSeparator: "A", lineFeed: nil)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let streamingData = try? encoder.encode(streaming)
        
        XCTAssertNotNil(streamingData)
        let expected = """
            {
              "enabled" : false,
              "recordSeparator" : "A"
            }
            """
        let jsonString = String(data: streamingData!, encoding: .utf8)
        print(jsonString!)
        
        XCTAssertEqual(expected, jsonString)
    }
    
    func testStreamingEncodeWithNilLineFeedAndRecordSeparator() {
        let streaming = Streaming(recordSeparator: nil, lineFeed: nil)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let streamingData = try? encoder.encode(streaming)
        
        XCTAssertNotNil(streamingData)
        let expected = """
            {
              "enabled" : false
            }
            """
        let jsonString = String(data: streamingData!, encoding: .utf8)
        print(jsonString!)
        
        XCTAssertEqual(expected, jsonString)
    }
    
    // MARK: KonductorConfig encoder tests
    
    func testKonductorConfigEncodeFromInitAll() {
        let streaming = Streaming(recordSeparator: "A", lineFeed: "B")
        let config = KonductorConfig(imsOrgId: "id", streaming: streaming)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try? encoder.encode(config)
        
        XCTAssertNotNil(jsonData)
        let expected = """
            {
              "imsOrgId" : "id",
              "streaming" : {
                "enabled" : true,
                "lineFeed" : "B",
                "recordSeparator" : "A"
              }
            }
            """
        let jsonString = String(data: jsonData!, encoding: .utf8)
        print(jsonString!)
        
        XCTAssertEqual(expected, jsonString)
    }
    
    func testKonductorConfigEncodeFromInitWithoutStreaming() {
        let config = KonductorConfig(imsOrgId: "id", streaming: nil)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try? encoder.encode(config)
        
        XCTAssertNotNil(jsonData)
        let expected = """
            {
              "imsOrgId" : "id"
            }
            """
        let jsonString = String(data: jsonData!, encoding: .utf8)
        print(jsonString!)
        
        XCTAssertEqual(expected, jsonString)
    }
    
    func testKonductorConfigEncodeEmptyParameters() {
        let config = KonductorConfig(imsOrgId: nil, streaming: nil)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try? encoder.encode(config)
        
        XCTAssertNotNil(jsonData)
        let expected = """
            {

            }
            """
        let jsonString = String(data: jsonData!, encoding: .utf8)
        print(jsonString!)
        
        XCTAssertEqual(expected, jsonString)
    }
    
}

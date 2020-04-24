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
        let streaming = Streaming(recordSeparator: "A", lineFeed: "B")
        
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
        let streaming = Streaming(recordSeparator: nil, lineFeed: "B")
        
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
        let streaming = Streaming(recordSeparator: "A", lineFeed: nil)
        
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

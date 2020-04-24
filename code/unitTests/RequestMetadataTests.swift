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
        let metadata = RequestMetadata(konductorConfig: KonductorConfig(streaming: nil),
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
        let metadata = RequestMetadata(konductorConfig: KonductorConfig(streaming: nil),
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

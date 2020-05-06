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

class EdgeRequestTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    
    func testEncode_allProperties() {
        let konductorConfig = KonductorConfig(streaming: Streaming(recordSeparator: "A", lineFeed: "B"))
        let requestMetadata = RequestMetadata(konductorConfig: konductorConfig, state: nil)
        var identityMap = IdentityMap()
        identityMap.addItem(namespace: "email", id: "example@adobe.com")
        let requestContext = RequestContextData(identityMap: identityMap, environment: nil, device: nil)
        
        let events: [[String : AnyCodable]] = [
        [
            "data" : [
                "key" : "value"
            ],
            "xdm" : [
                "device" :[
                    "manufacturer" : "Atari",
                    "type" : "mobile"
                ]
            ]
        ]]
        let edgeRequest = EdgeRequest(meta: requestMetadata, xdm: requestContext, events: events)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(edgeRequest)
        
        XCTAssertNotNil(data)
        let expected = """
        {
          "events" : [
            {
              "data" : {
                "key" : "value"
              },
              "xdm" : {
                "device" : {
                  "manufacturer" : "Atari",
                  "type" : "mobile"
                }
              }
            }
          ],
          "meta" : {
            "konductorConfig" : {
              "streaming" : {
                "enabled" : true,
                "lineFeed" : "B",
                "recordSeparator" : "A"
              }
            }
          },
          "xdm" : {
            "identityMap" : {
              "email" : [
                {
                  "id" : "example@adobe.com"
                }
              ]
            }
          }
        }
        """
        let jsonString = String(data: data!, encoding: .utf8)
        print(jsonString!)
        XCTAssertEqual(expected, jsonString)
    }
    
    func testEncode_onlyRequestMetadata() {
        let konductorConfig = KonductorConfig(streaming: Streaming(recordSeparator: "A", lineFeed: "B"))
        let requestMetadata = RequestMetadata(konductorConfig: konductorConfig, state: nil)
        let edgeRequest = EdgeRequest(meta: requestMetadata,
                                      xdm: nil,
                                      events: nil)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(edgeRequest)
        
        XCTAssertNotNil(data)
        let expected = """
        {
          "meta" : {
            "konductorConfig" : {
              "streaming" : {
                "enabled" : true,
                "lineFeed" : "B",
                "recordSeparator" : "A"
              }
            }
          }
        }
        """
        let jsonString = String(data: data!, encoding: .utf8)
        print(jsonString!)
        XCTAssertEqual(expected, jsonString)
    }
    
    func testEncode_onlyRequestContext() {
        var identityMap = IdentityMap()
        identityMap.addItem(namespace: "email", id: "example@adobe.com")
        let requestContext = RequestContextData(identityMap: identityMap, environment: nil, device: nil)
        let edgeRequest = EdgeRequest(meta: nil,
                                      xdm: requestContext,
                                      events: nil)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(edgeRequest)
        
        XCTAssertNotNil(data)
        let expected = """
        {
          "xdm" : {
            "identityMap" : {
              "email" : [
                {
                  "id" : "example@adobe.com"
                }
              ]
            }
          }
        }
        """
        let jsonString = String(data: data!, encoding: .utf8)
        print(jsonString!)
        XCTAssertEqual(expected, jsonString)
    }
    
    func testEncode_onlyEvents() {
        let events: [[String : AnyCodable]] = [
        [
            "data" : [
                "key" : "value"
            ],
            "xdm" : [
                "device" :[
                    "manufacturer" : "Atari",
                    "type" : "mobile"
                ]
            ]
        ],
        [
            "xdm" : [
                "test" : [
                    "true" : true,
                    "false" : false,
                    "one" : 1,
                    "zero" : 0,
                ]
            ]
        ]]
        let edgeRequest = EdgeRequest(meta: nil,
                                      xdm: nil,
                                      events: events)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(edgeRequest)
        
        XCTAssertNotNil(data)
        let expected = """
        {
          "events" : [
            {
              "data" : {
                "key" : "value"
              },
              "xdm" : {
                "device" : {
                  "manufacturer" : "Atari",
                  "type" : "mobile"
                }
              }
            },
            {
              "xdm" : {
                "test" : {
                  "false" : false,
                  "one" : 1,
                  "true" : true,
                  "zero" : 0
                }
              }
            }
          ]
        }
        """
        let jsonString = String(data: data!, encoding: .utf8)
        print(jsonString!)
        XCTAssertEqual(expected, jsonString)
    }
    
    
}


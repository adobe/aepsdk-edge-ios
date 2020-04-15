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

class EdgeRequestTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    
    func testEncode_allProperties() {
        let konductorConfig = KonductorConfig(imsOrgId: "id")
        let requestMetadata = RequestMetadata(konductorConfig: konductorConfig)
        var identityMap = IdentityMap()
        identityMap.addItem(namespace: "email", id: "example@adobe.com")
        let requestContext = RequestContextData(identityMap: identityMap)
        
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
              "imsOrgId" : "id"
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
        let konductorConfig = KonductorConfig(imsOrgId: "id")
        let requestMetadata = RequestMetadata(konductorConfig: konductorConfig)
        var edgeRequest = EdgeRequest()
        edgeRequest.meta = requestMetadata
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(edgeRequest)
        
        XCTAssertNotNil(data)
        let expected = """
        {
          "meta" : {
            "konductorConfig" : {
              "imsOrgId" : "id"
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
        let requestContext = RequestContextData(identityMap: identityMap)
        var edgeRequest = EdgeRequest()
        edgeRequest.xdm = requestContext
        
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
        var edgeRequest = EdgeRequest()
        edgeRequest.events = events
        
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


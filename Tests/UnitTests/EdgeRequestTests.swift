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

@testable import AEPEdge
import AEPServices
import XCTest

class EdgeRequestTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }

    func testEncode_allProperties() {
        let konductorConfig = KonductorConfig(streaming: Streaming(recordSeparator: "A", lineFeed: "B"))
        let requestMetadata = RequestMetadata(konductorConfig: konductorConfig, sdkConfig: nil, configOverrides: nil, state: nil)
        guard let identityMapData = """
        {
          "identityMap" : {
            "email" : [
              {
                "id" : "example@adobe.com"
              }
            ]
          }
        }
        """.data(using: .utf8) else {
            XCTFail("Failed to convert json string to data")
            return
        }
        let identityMap = try? JSONSerialization.jsonObject(with: identityMapData, options: []) as? [String: Any]

        let events: [[String: AnyCodable]] = [
            [
                "data": [
                    "key": "value"
                ],
                "xdm": [
                    "device": [
                        "manufacturer": "Atari",
                        "type": "mobile"
                    ]
                ]
            ]]
        let edgeRequest = EdgeRequest(meta: requestMetadata, xdm: AnyCodable.from(dictionary: identityMap)!, events: events)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        let data = try? encoder.encode(edgeRequest)
        let actualResult = asFlattenDictionary(data: data)
        let expectedResult: [String: Any] =
            [ "events[0].data.key": "value",
              "events[0].xdm.device.manufacturer": "Atari",
              "events[0].xdm.device.type": "mobile",
              "meta.konductorConfig.streaming.enabled": true,
              "meta.konductorConfig.streaming.recordSeparator": "A",
              "meta.konductorConfig.streaming.lineFeed": "B",
              "xdm.identityMap.email[0].id": "example@adobe.com"]
        assertEqual(expectedResult, actualResult)
    }

    func testEncode_onlyRequestMetadata() {
        let konductorConfig = KonductorConfig(streaming: Streaming(recordSeparator: "A", lineFeed: "B"))
        let requestMetadata = RequestMetadata(konductorConfig: konductorConfig, sdkConfig: nil, configOverrides: nil, state: nil)
        let edgeRequest = EdgeRequest(meta: requestMetadata,
                                      xdm: nil,
                                      events: nil)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        let data = try? encoder.encode(edgeRequest)
        let actualResult = asFlattenDictionary(data: data)
        let expectedResult: [String: Any] =
            ["meta.konductorConfig.streaming.enabled": true,
             "meta.konductorConfig.streaming.recordSeparator": "A",
             "meta.konductorConfig.streaming.lineFeed": "B"]
        assertEqual(expectedResult, actualResult)
    }

    func testEncode_onlyRequestContext() {
        guard let identityMapData = """
        {
            "identityMap": {
                "email" : [
                  {
                    "id" : "example@adobe.com"
                  }
                ]
            }
        }
        """.data(using: .utf8) else {
            XCTFail("Failed to convert json string to data")
            return
        }
        let identityMap = try? JSONSerialization.jsonObject(with: identityMapData, options: []) as? [String: Any]
        let edgeRequest = EdgeRequest(meta: nil,
                                      xdm: AnyCodable.from(dictionary: identityMap)!,
                                      events: nil)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        let data = try? encoder.encode(edgeRequest)

        let actualResult = asFlattenDictionary(data: data)
        let expectedResult: [String: Any] = ["xdm.identityMap.email[0].id": "example@adobe.com"]
        assertEqual(expectedResult, actualResult)
    }

    func testEncode_onlyEvents() {
        let events: [[String: AnyCodable]] = [
            [
                "data": [
                    "key": "value"
                ],
                "xdm": [
                    "device": [
                        "manufacturer": "Atari",
                        "type": "mobile"
                    ]
                ]
            ],
            [
                "xdm": [
                    "test": [
                        "true": true,
                        "false": false,
                        "one": 1,
                        "zero": 0
                    ]
                ]
            ]]
        let edgeRequest = EdgeRequest(meta: nil,
                                      xdm: nil,
                                      events: events)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        let data = try? encoder.encode(edgeRequest)
        let actualResult = asFlattenDictionary(data: data)
        let expectedResult: [String: Any] =
            [ "events[0].data.key": "value",
              "events[0].xdm.device.manufacturer": "Atari",
              "events[0].xdm.device.type": "mobile",
              "events[1].xdm.test.false": false,
              "events[1].xdm.test.true": true,
              "events[1].xdm.test.one": 1,
              "events[1].xdm.test.zero": 0]
        assertEqual(expectedResult, actualResult)
    }
}

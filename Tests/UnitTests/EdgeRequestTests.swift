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
import AEPTestUtils
import XCTest

class EdgeRequestTests: XCTestCase, AnyCodableAsserts {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }

    func testEncode_allProperties() {
        let konductorConfig = KonductorConfig(streaming: Streaming(recordSeparator: "A", lineFeed: "B"))
        let requestMetadata = RequestMetadata(konductorConfig: konductorConfig, sdkConfig: nil, configOverrides: nil, state: nil)
        let identityMapJSON = #"""
        {
          "identityMap" : {
            "email" : [
              {
                "id" : "example@adobe.com"
              }
            ]
          }
        }
        """#

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

        let edgeRequest = EdgeRequest(
            meta: requestMetadata,
            xdm: getAsDictionaryAnyCodable(identityMapJSON)!,
            events: events)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(edgeRequest), let edgeRequestString = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode EdgeRequest: \(edgeRequest)")
            return
        }

        let expectedJSON = #"""
        {
          "events": [
            {
              "data": {
                "key": "value"
              },
              "xdm": {
                "device": {
                  "manufacturer": "Atari",
                  "type": "mobile"
                }
              }
            }
          ],
          "meta": {
            "konductorConfig": {
              "streaming": {
                "enabled": true,
                "lineFeed": "B",
                "recordSeparator": "A"
              }
            }
          },
          "xdm": {
            "identityMap": {
              "email": [
                {
                  "id": "example@adobe.com"
                }
              ]
            }
          }
        }
        """#
        assertEqual(expected: expectedJSON, actual: edgeRequestString)
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

        guard let data = try? encoder.encode(edgeRequest), let edgeRequestString = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode EdgeRequest: \(edgeRequest)")
            return
        }

        let expectedJSON = #"""
        {
          "meta": {
            "konductorConfig": {
              "streaming": {
                "enabled": true,
                "lineFeed": "B",
                "recordSeparator": "A"
              }
            }
          }
        }
        """#
        assertEqual(expected: expectedJSON, actual: edgeRequestString)
    }

    func testEncode_onlyRequestContext() {
        let identityMapJSON = #"""
        {
          "identityMap" : {
            "email" : [
              {
                "id" : "example@adobe.com"
              }
            ]
          }
        }
        """#

        let edgeRequest = EdgeRequest(meta: nil,
                                      xdm: getAsDictionaryAnyCodable(identityMapJSON)!,
                                      events: nil)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(edgeRequest), let edgeRequestString = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode EdgeRequest: \(edgeRequest)")
            return
        }

        let expectedJSON = #"""
        {
          "xdm": {
            "identityMap": {
              "email": [
                {
                  "id": "example@adobe.com"
                }
              ]
            }
          }
        }
        """#
        assertEqual(expected: expectedJSON, actual: edgeRequestString)
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

        guard let data = try? encoder.encode(edgeRequest), let edgeRequestString = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode EdgeRequest: \(edgeRequest)")
            return
        }

        let expectedJSON = #"""
        {
          "events": [
            {
              "data": {
                "key": "value"
              },
              "xdm": {
                "device": {
                  "manufacturer": "Atari",
                  "type": "mobile"
                }
              }
            },
            {
              "xdm": {
                "test": {
                  "false": false,
                  "one": 1,
                  "true": true,
                  "zero": 0
                }
              }
            }
          ]
        }
        """#
        assertEqual(expected: expectedJSON, actual: edgeRequestString)
    }

    private func getAsDictionaryAnyCodable(_ jsonString: String, file: StaticString = #file, line: UInt = #line) -> [String: AnyCodable]? {
        guard let anyCodable = jsonString.toAnyCodable() else {
            XCTFail("Unable to get valid AnyCodable from provided JSON string: \(jsonString)", file: file, line: line)
            return nil
        }
        return AnyCodable.from(dictionary: anyCodable.dictionaryValue)
    }
}

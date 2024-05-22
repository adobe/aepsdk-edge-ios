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

class RequestMetadataTests: XCTestCase, AnyCodableAsserts {
    private let encoder = JSONEncoder()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: encoder tests

    func testEncode_noParameters() {
        let metadata = RequestMetadata(konductorConfig: nil, sdkConfig: nil, configOverrides: nil, state: nil)

        guard let data = try? encoder.encode(metadata), let metadataString = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode RequestMetadata: \(metadata)")
            return
        }

        let expectedJSON = "{}"
        assertEqual(expected: expectedJSON, actual: metadataString)
    }

    func testEncode_paramKonductorConfig() {
        let metadata = RequestMetadata(konductorConfig: KonductorConfig(streaming: nil), sdkConfig: nil, configOverrides: nil, state: nil)

        guard let data = try? encoder.encode(metadata), let metadataString = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode RequestMetadata: \(metadata)")
            return
        }

        let expectedJSON = #"""
        {
          "konductorConfig": {}
        }
        """#
        assertEqual(expected: expectedJSON, actual: metadataString)
    }

    func testEncode_paramStateMetadata() {
        let payload = StorePayload(key: "key", value: "value", maxAge: 3600)
        let metadata = RequestMetadata(konductorConfig: nil, sdkConfig: nil, configOverrides: nil, state: StateMetadata(payload: [payload]))

        guard let data = try? encoder.encode(metadata), let metadataString = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode RequestMetadata: \(metadata)")
            return
        }

        let expectedJSON = #"""
        {
          "state": {
            "entries": [
              {
                "key": "key",
                "maxAge": 3600,
                "value": "value"
              }
            ]
          }
        }
        """#
        assertEqual(expected: expectedJSON, actual: metadataString)
    }

    func testEncode_paramKonductorConfig_paramStateMetadata() {
        let payload = StorePayload(key: "key", value: "value", maxAge: 3600)
        let metadata = RequestMetadata(konductorConfig: KonductorConfig(streaming: nil), sdkConfig: nil, configOverrides: nil,
                                       state: StateMetadata(payload: [payload]))

        guard let data = try? encoder.encode(metadata), let metadataString = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode RequestMetadata: \(metadata)")
            return
        }

        let expectedJSON = #"""
        {
          "konductorConfig": {},
          "state": {
            "entries": [
              {
                "key": "key",
                "maxAge": 3600,
                "value": "value"
              }
            ]
          }
        }
        """#
        assertEqual(expected: expectedJSON, actual: metadataString)
    }

    func testEncode_paramSDKConfig_originalDatastreamIdMetadata() {

        let metadata = RequestMetadata(konductorConfig: KonductorConfig(streaming: nil), sdkConfig: SDKConfig(datastream: Datastream(original: "OriginalDatastreamID")), configOverrides: nil, state: nil)

        guard let data = try? encoder.encode(metadata), let metadataString = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode RequestMetadata: \(metadata)")
            return
        }

        let expectedJSON = #"""
        {
          "konductorConfig": {},
          "sdkConfig": {
            "datastream": {
              "original": "OriginalDatastreamID"
            }
          }
        }
        """#
        assertEqual(expected: expectedJSON, actual: metadataString)
    }

    func testEncode_paramConfigOverrides_originalDatastreamConfigOverrideMetadata() {
        let configOverrides: [String: Any] = [
            "com_adobe_experience_platform": [
              "datasets": [
                "event": [
                  "datasetId": "testEventDatasetIdOverride"
                ],
                "profile": [
                  "datasetId": "testProfileDatasetIdOverride"
                ]
              ]
            ],
            "com_adobe_analytics": [
              "reportSuites": [
                "rsid1",
                "rsid2",
                "rsid3"
                ]
            ],
            "com_adobe_identity": [
              "idSyncContainerId": "1234567"
            ],
            "com_adobe_target": [
              "propertyToken": "testPropertyToken"
            ]
        ]

        let metadata = RequestMetadata(konductorConfig: KonductorConfig(streaming: nil),
                                       sdkConfig: nil, configOverrides: AnyCodable.from(dictionary: configOverrides), state: nil)

        guard let data = try? encoder.encode(metadata), let metadataString = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode RequestMetadata: \(metadata)")
            return
        }

        let expectedJSON = #"""
        {
          "configOverrides": {
            "com_adobe_analytics": {
              "reportSuites": [
                "rsid1",
                "rsid2",
                "rsid3"
              ]
            },
            "com_adobe_experience_platform": {
              "datasets": {
                "event": {
                  "datasetId": "testEventDatasetIdOverride"
                },
                "profile": {
                  "datasetId": "testProfileDatasetIdOverride"
                }
              }
            },
            "com_adobe_identity": {
              "idSyncContainerId": "1234567"
            },
            "com_adobe_target": {
              "propertyToken": "testPropertyToken"
            }
          },
          "konductorConfig": {}
        }
        """#
        assertEqual(expected: expectedJSON, actual: metadataString)
    }
}

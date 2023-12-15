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
import AEPTestUtils
import XCTest

class StateMetadataTests: XCTestCase, AnyCodableAsserts {
    private let encoder = JSONEncoder()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: Encoder tests

    func testInit_withEmptyMap_doesNotEncodeEntries() {
        let state = StateMetadata(payload: [])

        guard let data = try? encoder.encode(state), let stateString = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode StateMetadata: \(state)")
            return
        }

        let expectedJSON = "{}"
        assertEqual(expected: expectedJSON, actual: stateString)
    }

    func testEncode_singlePayload() {
        let payload = [StorePayload(key: "key", value: "value", maxAge: 3600)]
        let state = StateMetadata(payload: payload)

        guard let data = try? encoder.encode(state), let stateString = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode StateMetadata: \(state)")
            return
        }

        let expectedJSON = #"""
        {
          "entries": [
            {
              "key": "key",
              "maxAge": 3600,
              "value": "value"
            }
          ]
        }
        """#
        assertEqual(expected: expectedJSON, actual: stateString)
    }

    func testEncode_multiplePayloads() {
        let payload = [StorePayload(key: "key", value: "value", maxAge: 3600),
                       StorePayload(key: "key2", value: "value2", maxAge: 5)]
        let state = StateMetadata(payload: payload)

        guard let data = try? encoder.encode(state), let stateString = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode StateMetadata: \(state)")
            return
        }

        let expectedJSON = #"""
        {
          "entries": [
            {
              "key": "key",
              "maxAge": 3600,
              "value": "value"
            },
            {
              "key": "key2",
              "maxAge": 5,
              "value": "value2"
            }
          ]
        }
        """#
        assertEqual(expected: expectedJSON, actual: stateString)
    }
}

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
import XCTest

class StateMetadataTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }

    // MARK: Encoder tests

    func testInit_withEmptyMap_doesNotEncodeEntries() {
        let state = StateMetadata(payload: [])

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        let data = try? encoder.encode(state)
        let actualResult = asFlattenDictionary(data: data)
        let expectedResult: [String: Any] = [:]
        assertEqual(expectedResult, actualResult)
    }

    func testEncode_singlePayload() {
        let payload = [StorePayload(key: "key", value: "value", maxAge: 3600)]
        let state = StateMetadata(payload: payload)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        let data = try? encoder.encode(state)
        let actualResult = asFlattenDictionary(data: data)
        let expectedResult: [String: Any] =
            ["entries[0].key": "key",
             "entries[0].maxAge": 3600,
             "entries[0].value": "value"]
        assertEqual(expectedResult, actualResult)
    }

    func testEncode_multiplePayloads() {
        let payload = [StorePayload(key: "key", value: "value", maxAge: 3600),
                       StorePayload(key: "key2", value: "value2", maxAge: 5)]
        let state = StateMetadata(payload: payload)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        let data = try? encoder.encode(state)
        let actualResult = asFlattenDictionary(data: data)
        let expectedResult: [String: Any] =
            ["entries[0].key": "key",
             "entries[0].maxAge": 3600,
             "entries[0].value": "value",
             "entries[1].key": "key2",
             "entries[1].maxAge": 5,
             "entries[1].value": "value2"]
        assertEqual(expectedResult, actualResult)
    }
}

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

class StoreResponsePayloadTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }

    // MARK: encoder tests

    func testEncode() {
        let payload = StoreResponsePayload(payload: StorePayload(key: "key", value: "value", maxAge: 3600))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        let data = try? encoder.encode(payload)
        let actualResult = asFlattenDictionary(data: data)
        let expectedResult: [String: Any] =
            [ "expiryDate": "\(ISO8601DateFormatter().string(from: payload.expiryDate))",
              "payload.key": "key",
              "payload.maxAge": 3600,
              "payload.value": "value"]
        assertEqual(expectedResult, actualResult)
    }

    // MARK: decoder tests

    func testDecode() {
        guard let data = """
            {
              "expiryDate" : "2020-04-10T20:34:12Z",
              "payload" : {
                "key" : "key",
                "maxAge" : 3600,
                "value" : "value"
              }
            }
        """.data(using: .utf8) else {
            XCTFail("Failed to convert json string to data")
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let storeResponse = try? decoder.decode(StoreResponsePayload.self, from: data)
        XCTAssertNotNil(storeResponse)
        XCTAssertEqual("key", storeResponse?.payload.key)
        XCTAssertEqual("value", storeResponse?.payload.value)
        XCTAssertEqual(3600, storeResponse?.payload.maxAge)

        let dateFormatter = ISO8601DateFormatter()
        let expectedDate = dateFormatter.date(from: "2020-04-10T20:34:12Z")
        XCTAssertEqual(expectedDate, storeResponse?.expiryDate)
    }

    // MARK: is expired tests

    func testIsExpired_expiryDateSetFromMaxAge_oneHourAhead() {
        let date = Date(timeIntervalSinceNow: 36000)
        guard let data = """
            {
            "expiryDate" : "\(ISO8601DateFormatter().string(from: date))",
            "payload" : {
            "key" : "key",
            "maxAge" : 3600,
            "value" : "value"
            }
            }
            """.data(using: .utf8) else {
            XCTFail("Failed to convert json to data")
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let payload = try? decoder.decode(StoreResponsePayload.self, from: data) else {
            XCTFail("Failed to decode StoreResponsePayload.")
            return
        }

        XCTAssertFalse(payload.isExpired)
    }

    func testIsExpired_expiryDate_inPast() {
        guard let data = """
            {
              "expiryDate" : "1955-11-05T06:00:00Z",
              "payload" : {
                "key" : "key",
                "maxAge" : 3600,
                "value" : "value"
              }
            }
        """.data(using: .utf8) else {
            XCTFail("Failed to convert json to data")
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let payload = try? decoder.decode(StoreResponsePayload.self, from: data) else {
            XCTFail("Failed to decode StoreResponsePayload.")
            return
        }

        XCTAssertTrue(payload.isExpired)
    }
}

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

class KonductorConfigTests: XCTestCase, AnyCodableAsserts {
    let encoder = JSONEncoder()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
        encoder.outputFormatting = [.prettyPrinted]
    }

    // MARK: Streaming encoder tests

    func testStreamingEncodeFromInitAll() {
        let streaming = Streaming(recordSeparator: "A", lineFeed: "B")

        guard let data = try? encoder.encode(streaming), let actualResult = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode Streaming: \(streaming)")
            return
        }

        let expectedJSON = #"""
        {
          "enabled": true,
          "lineFeed": "B",
          "recordSeparator": "A"
        }
        """#
        assertEqual(expected: expectedJSON, actual: actualResult)
    }

    func testStreamingEncodeWithNilRecordSeparator() {
        let streaming = Streaming(recordSeparator: nil, lineFeed: "B")

        guard let data = try? encoder.encode(streaming), let actualResult = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode Streaming: \(streaming)")
            return
        }

        let expectedJSON = #"""
        {
          "enabled": false,
          "lineFeed": "B"
        }
        """#
        assertEqual(expected: expectedJSON, actual: actualResult)
    }

    func testStreamingEncodeWithNilLineFeed() {
        let streaming = Streaming(recordSeparator: "A", lineFeed: nil)

        guard let data = try? encoder.encode(streaming), let actualResult = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode Streaming: \(streaming)")
            return
        }

        let expectedJSON = #"""
        {
          "enabled": false,
          "recordSeparator": "A"
        }
        """#
        assertEqual(expected: expectedJSON, actual: actualResult)
    }

    func testStreamingEncodeWithNilLineFeedAndRecordSeparator() {
        let streaming = Streaming(recordSeparator: nil, lineFeed: nil)

        guard let data = try? encoder.encode(streaming), let actualResult = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode Streaming: \(streaming)")
            return
        }

        let expectedJSON = #"""
        {
          "enabled": false
        }
        """#
        assertEqual(expected: expectedJSON, actual: actualResult)
    }

    // MARK: KonductorConfig encoder tests

    func testKonductorConfigEncodeFromInitAll() {
        let streaming = Streaming(recordSeparator: "A", lineFeed: "B")
        let config = KonductorConfig(streaming: streaming)

        guard let data = try? encoder.encode(config), let actualResult = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode KonductorConfig: \(config)")
            return
        }

        let expectedJSON = #"""
        {
          "streaming": {
            "enabled": true,
            "lineFeed": "B",
            "recordSeparator": "A"
          }
        }
        """#
        assertEqual(expected: expectedJSON, actual: actualResult)
    }

    func testKonductorConfigEncodeEmptyParameters() {
        let config = KonductorConfig(streaming: nil)

        guard let data = try? encoder.encode(config), let actualResult = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to encode/decode KonductorConfig: \(config)")
            return
        }

        let expectedJSON = "{}"

        assertEqual(expected: expectedJSON, actual: actualResult)
    }
}

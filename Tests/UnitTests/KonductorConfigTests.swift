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

class KonductorConfigTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }

    // MARK: Streaming encoder tests

    func testStreamingEncodeFromInitAll() {
        let streaming = Streaming(recordSeparator: "A", lineFeed: "B")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        let data = try? encoder.encode(streaming)
        let actualResult = asFlattenDictionary(data: data)
        let expectedResult: [String: Any] =
            [ "enabled": true,
              "lineFeed": "B",
              "recordSeparator": "A"]
        assertEqual(expectedResult, actualResult)
    }

    func testStreamingEncodeWithNilRecordSeparator() {
        let streaming = Streaming(recordSeparator: nil, lineFeed: "B")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        let data = try? encoder.encode(streaming)
        let actualResult = asFlattenDictionary(data: data)
        let expectedResult: [String: Any] =
            [ "enabled": false,
              "lineFeed": "B"]
        assertEqual(expectedResult, actualResult)
    }

    func testStreamingEncodeWithNilLineFeed() {
        let streaming = Streaming(recordSeparator: "A", lineFeed: nil)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        let data = try? encoder.encode(streaming)
        let actualResult = asFlattenDictionary(data: data)
        let expectedResult: [String: Any] =
            [ "enabled": false,
              "recordSeparator": "A"]
        assertEqual(expectedResult, actualResult)
    }

    func testStreamingEncodeWithNilLineFeedAndRecordSeparator() {
        let streaming = Streaming(recordSeparator: nil, lineFeed: nil)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        let data = try? encoder.encode(streaming)
        let actualResult = asFlattenDictionary(data: data)
        let expectedResult: [String: Any] =
            [ "enabled": false]
        assertEqual(expectedResult, actualResult)
    }

    // MARK: KonductorConfig encoder tests

    func testKonductorConfigEncodeFromInitAll() {
        let streaming = Streaming(recordSeparator: "A", lineFeed: "B")
        let config = KonductorConfig(streaming: streaming)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        let data = try? encoder.encode(config)
        let actualResult = asFlattenDictionary(data: data)
        let expectedResult: [String: Any] =
            [ "streaming.enabled": true,
              "streaming.lineFeed": "B",
              "streaming.recordSeparator": "A"]
        assertEqual(expectedResult, actualResult)
    }

    func testKonductorConfigEncodeEmptyParameters() {
        let config = KonductorConfig(streaming: nil)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        let data = try? encoder.encode(config)
        let actualResult = asFlattenDictionary(data: data)
        let expectedResult: [String: Any] = [:]
        assertEqual(expectedResult, actualResult)
    }

}

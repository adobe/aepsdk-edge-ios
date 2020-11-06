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

class RequestContextDataTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }

    // MARK: Codable tests

    func testEncodeAndDecode_noParameters() {
        let context = RequestContextData(identityMap: nil)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(context) else {
            XCTFail("Failed to convert request context data to data")
            return
        }
        XCTAssertNotNil(data)
        let decodedContext = try? JSONDecoder().decode(RequestContextData.self, from: data)

        let expected = """
            {}
            """
        let jsonData = (try? JSONEncoder().encode(decodedContext)) ?? Data()
        let jsonString = String(data: jsonData, encoding: .utf8)

        XCTAssertEqual(expected, jsonString)
    }

    func testEncodeAndDecode_paramIdentityMap() {
        let context = RequestContextData(identityMap: IdentityMap())

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(context)  else {
            XCTFail("Failed to convert RequestContentData to data")
            return
        }

        XCTAssertNotNil(data)
        let decodedContext = try? JSONDecoder().decode(RequestContextData.self, from: data)
        let expected = """
            {"identityMap":{}}
            """
        let jsonData = (try? JSONEncoder().encode(decodedContext)) ?? Data()
        let jsonString = String(data: jsonData, encoding: .utf8)
        XCTAssertEqual(expected, jsonString)
    }

}

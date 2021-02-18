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
@testable import AEPServices
import XCTest

class RequestContextDataTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: encoder tests

    func testEncode_noParameters() {
        let context = RequestContextData()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(context) else {
            XCTFail("Failed to convert request context data to data")
            return
        }

        XCTAssertNotNil(data)
        let expected = """
            {

            }
            """
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertEqual(expected, jsonString)
    }

    func testEncode_paramIdentityMap() {
        let identityMapStr = """
        {
          "identityMap" : {
            "email" : [
              {
                "id" : "example@adobe.com",
                "primary" : false,
                "authenticationState" : "ambiguous",
              }
            ]
          }
        }
        """
        guard let identityMapData = identityMapStr.data(using: .utf8) else {
            XCTFail("Failed to convert json string to data")
            return
        }
        let identityMap = try? JSONSerialization.jsonObject(with: identityMapData, options: []) as? [String: Any]
        var context = RequestContextData()
        context.xdmPayloads += [AnyCodable.from(dictionary: identityMap) ?? [:]]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(context)  else {
            XCTFail("Failed to convert RequestContentData to data")
            return
        }

        XCTAssertNotNil(data)

        let actualDict = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        let expectedDict = try! JSONSerialization.jsonObject(with: identityMapData, options: []) as! [String: Any]
        assertEqual(actualDict, expectedDict)
    }

}

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

class EdgeEventErrorTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }

    func testCanDecode_eventError_allParams() {
        // setup
        let jsonData = """
                        {
                          "eventIndex": 1,
                          "type": "https://ns.adobe.com/aep/errors/EXEG-0201-503",
                          "status": 503,
                          "title": "test title"
                        }
                      """.data(using: .utf8)

        // test
        let error = try? JSONDecoder().decode(EdgeEventError.self, from: jsonData ?? Data())

        // verify
        XCTAssertEqual(1, error?.eventIndex)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0201-503", error?.type)
        XCTAssertEqual(503, error?.status)
        XCTAssertEqual("test title", error?.title)
    }

    func testCanDecode_eventWarning_allParams_multipleWarnings() {
        // setup
        let jsonData = """
                        [
                            {
                              "eventIndex": 1,
                              "type": "https://ns.adobe.com/aep/errors/EXEG-0201-503",
                              "status": 503,
                              "title": "test title"
                            },
                            {
                              "eventIndex": 2,
                              "type": "https://ns.adobe.com/aep/errors/EXEG-0201-504",
                              "status": 504,
                              "title": "test title 2"
                            }
                        ]
                      """.data(using: .utf8)

        // test
        let errors = try? JSONDecoder().decode([EdgeEventError].self, from: jsonData ?? Data())

        // verify
        XCTAssertEqual(1, errors?.first?.eventIndex)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0201-503", errors?.first?.type)
        XCTAssertEqual(503, errors?.first?.status)
        XCTAssertEqual("test title", errors?.first?.title)

        XCTAssertEqual(2, errors?.last?.eventIndex)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0201-504", errors?.last?.type)
        XCTAssertEqual(504, errors?.last?.status)
        XCTAssertEqual("test title 2", errors?.last?.title)
    }

}

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

class EdgeEventWarningTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }

    func testCanDecode_eventWarning_allParams() {
        // setup
        let jsonData = """
                        {
                          "eventIndex": 1,
                          "type": "https://ns.adobe.com/aep/errors/EXEG-0204-200",
                          "status": 200,
                          "title": "test title",
                          "report": {
                            "cause": {
                              "message": "Cannot read related customer for device id: ...",
                              "code": 202
                            }
                          }
                        }
                      """.data(using: .utf8)

        // test
        let warning = try? JSONDecoder().decode(EdgeEventWarning.self, from: jsonData ?? Data())

        // verify
        XCTAssertEqual(1, warning?.eventIndex)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0204-200", warning?.type)
        XCTAssertEqual(200, warning?.status)
        XCTAssertEqual("test title", warning?.title)
        XCTAssertEqual("Cannot read related customer for device id: ...", warning?.report?.cause?.message)
        XCTAssertEqual(202, warning?.report?.cause?.code)
    }

    func testCanDecode_eventWarning_allParams_multipleWarnings() {
        // setup
        let jsonData = """
                        [
                            {
                              "eventIndex": 1,
                              "type": "https://ns.adobe.com/aep/errors/EXEG-0204-200",
                              "status": 200,
                              "title": "test title",
                              "report": {
                                "cause": {
                                  "message": "Cannot read related customer for device id: ...",
                                  "code": 202
                                }
                              }
                            },
                            {
                              "eventIndex": 2,
                              "type": "https://ns.adobe.com/aep/errors/EXEG-0204-202",
                              "status": 202,
                              "title": "test title 2",
                              "report": {
                                "cause": {
                                  "message": "Cannot read related customer for device id: ...",
                                  "code": 202
                                }
                              }
                            }
                        ]
                      """.data(using: .utf8)

        // test
        let warnings = try? JSONDecoder().decode([EdgeEventWarning].self, from: jsonData ?? Data())

        // verify
        XCTAssertEqual(1, warnings?.first?.eventIndex)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0204-200", warnings?.first?.type)
        XCTAssertEqual(200, warnings?.first?.status)
        XCTAssertEqual("test title", warnings?.first?.title)
        XCTAssertEqual("Cannot read related customer for device id: ...", warnings?.first?.report?.cause?.message)
        XCTAssertEqual(202, warnings?.first?.report?.cause?.code)

        XCTAssertEqual(2, warnings?.last?.eventIndex)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0204-202", warnings?.last?.type)
        XCTAssertEqual(202, warnings?.last?.status)
        XCTAssertEqual("test title 2", warnings?.last?.title)
        XCTAssertEqual("Cannot read related customer for device id: ...", warnings?.last?.report?.cause?.message)
        XCTAssertEqual(202, warnings?.last?.report?.cause?.code)
    }

    func testCanDecode_eventWarning_missingParams() {
        // setup
        let jsonData = """
                        {
                          "eventIndex": 1,
                          "type": "https://ns.adobe.com/aep/errors/EXEG-0204-200",
                          "status": 200,
                          "title": "test title"
                        }
                      """.data(using: .utf8)

        // test
        let warning = try? JSONDecoder().decode(EdgeEventWarning.self, from: jsonData ?? Data())

        // verify
        XCTAssertEqual(1, warning?.eventIndex)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0204-200", warning?.type)
        XCTAssertEqual(200, warning?.status)
        XCTAssertEqual("test title", warning?.title)
        XCTAssertNil(warning?.report)
    }

    func testCanDecode_eventWarning_missingParams_multipleWarnings() {
        // setup
        let jsonData = """
                        [
                            {
                              "eventIndex": 1,
                              "type": "https://ns.adobe.com/aep/errors/EXEG-0204-200",
                              "status": 200,
                              "title": "test title"
                            },
                            {
                              "eventIndex": 2,
                              "type": "https://ns.adobe.com/aep/errors/EXEG-0204-202",
                              "status": 202,
                              "title": "test title 2"
                            }
                        ]
                      """.data(using: .utf8)

        // test
        let warnings = try? JSONDecoder().decode([EdgeEventWarning].self, from: jsonData ?? Data())

        // verify
        XCTAssertEqual(1, warnings?.first?.eventIndex)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0204-200", warnings?.first?.type)
        XCTAssertEqual(200, warnings?.first?.status)
        XCTAssertEqual("test title", warnings?.first?.title)
        XCTAssertNil(warnings?.first?.report)

        XCTAssertEqual(2, warnings?.last?.eventIndex)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0204-202", warnings?.last?.type)
        XCTAssertEqual(202, warnings?.last?.status)
        XCTAssertEqual("test title 2", warnings?.last?.title)
        XCTAssertNil(warnings?.last?.report)
    }

}

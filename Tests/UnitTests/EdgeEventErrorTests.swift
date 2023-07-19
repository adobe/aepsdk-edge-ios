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
                          "type": "https://ns.adobe.com/aep/errors/EXEG-0201-503",
                          "status": 503,
                          "title": "test title",
                          "report": {
                            "eventIndex": 1
                          }
                        }
                      """.data(using: .utf8)

        // test
        let error = try? JSONDecoder().decode(EdgeEventError.self, from: jsonData ?? Data())

        // verify
        XCTAssertEqual(1, error?.report?.eventIndex)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0201-503", error?.type)
        XCTAssertEqual(503, error?.status)
        XCTAssertEqual("test title", error?.title)
    }

    func testCanDecode_eventWarning_allParams_multipleWarnings() {
        // setup
        let jsonData = """
                        [
                            {
                              "type": "https://ns.adobe.com/aep/errors/EXEG-0201-503",
                              "status": 503,
                              "title": "test title",
                              "report": {
                                "eventIndex": 1
                              }
                            },
                            {
                              "type": "https://ns.adobe.com/aep/errors/EXEG-0201-504",
                              "status": 504,
                              "title": "test title 2",
                              "report": {
                                "eventIndex": 2
                              }
                            }
                        ]
                      """.data(using: .utf8)

        // test
        let errors = try? JSONDecoder().decode([EdgeEventError].self, from: jsonData ?? Data())

        // verify
        XCTAssertEqual(1, errors?.first?.report?.eventIndex)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0201-503", errors?.first?.type)
        XCTAssertEqual(503, errors?.first?.status)
        XCTAssertEqual("test title", errors?.first?.title)

        XCTAssertEqual(2, errors?.last?.report?.eventIndex)
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0201-504", errors?.last?.type)
        XCTAssertEqual(504, errors?.last?.status)
        XCTAssertEqual("test title 2", errors?.last?.title)
    }

    func testCanDecode_genericError_allParams() {
        // setup
        let jsonData = """
                        {
                          "type" : "https://ns.adobe.com/aep/errors/EXEG-0104-422",
                          "status": 422,
                          "title" : "Unprocessable Entity",
                          "detail": "Invalid request (report attached). Please check your input and try again.",
                          "report": {
                            "errors": [
                              "Allowed Adobe version is 1.0 for standard 'Adobe' at index 0",
                              "Allowed IAB version is 2.0 for standard 'IAB TCF' at index 1",
                              "IAB consent string value must not be empty for standard 'IAB TCF' at index 1"
                            ],
                            "requestId": "0f8821e5-ed1a-4301-b445-5f336fb50ee8",
                            "orgId": "test@AdobeOrg"
                          }
                        }
                      """.data(using: .utf8)

        // test
        let error = try? JSONDecoder().decode(EdgeEventError.self, from: jsonData ?? Data())

        // verify
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0104-422", error?.type)
        XCTAssertEqual(422, error?.status)
        XCTAssertEqual("Unprocessable Entity", error?.title)
        XCTAssertEqual("Invalid request (report attached). Please check your input and try again.", error?.detail)
        XCTAssertEqual("Allowed Adobe version is 1.0 for standard 'Adobe' at index 0", error?.report?.errors?.first)
        XCTAssertEqual("Allowed IAB version is 2.0 for standard 'IAB TCF' at index 1", error?.report?.errors?[1])
        XCTAssertEqual("IAB consent string value must not be empty for standard 'IAB TCF' at index 1", error?.report?.errors?.last)
        XCTAssertEqual("0f8821e5-ed1a-4301-b445-5f336fb50ee8", error?.report?.requestId)
        XCTAssertEqual("test@AdobeOrg", error?.report?.orgId)
    }

    func testCanDecode_genericError_missingReport() {
        // setup
        let jsonData = """
                        {
                          "type" : "https://ns.adobe.com/aep/errors/EXEG-0104-422",
                          "status": 422,
                          "title" : "Unprocessable Entity",
                          "detail": "Invalid request (report attached). Please check your input and try again."
                        }
                      """.data(using: .utf8)

        // test
        let error = try? JSONDecoder().decode(EdgeEventError.self, from: jsonData ?? Data())

        // verify
        XCTAssertEqual("https://ns.adobe.com/aep/errors/EXEG-0104-422", error?.type)
        XCTAssertEqual(422, error?.status)
        XCTAssertEqual("Unprocessable Entity", error?.title)
        XCTAssertEqual("Invalid request (report attached). Please check your input and try again.", error?.detail)
    }

    func testCanEncode_eventError_allParams() {
        let report = EdgeErrorReport(eventIndex: 1, errors: ["error1", "error2"], requestId: "1234", orgId: "abcd")
        let error = EdgeEventError(title: "Test Error", detail: "details", status: 200, type: "error", report: report)

        let encoded = error.asDictionary()

        XCTAssertNotNil(encoded)
        XCTAssertEqual(5, encoded?.count)
        XCTAssertEqual("Test Error", encoded?["title"] as? String)
        XCTAssertEqual("details", encoded?["detail"] as? String)
        XCTAssertEqual(200, encoded?["status"] as? Int)
        XCTAssertEqual("error", encoded?["type"] as? String)

        let encodedReport = encoded?["report"] as? [String: Any]
        XCTAssertNotNil(encodedReport)
        XCTAssertEqual(3, encodedReport?.count) // eventIndex is no encoded
        XCTAssertEqual(["error1", "error2"], encodedReport?["errors"] as? [String])
        XCTAssertEqual("1234", encodedReport?["requestId"] as? String)
        XCTAssertEqual("abcd", encodedReport?["orgId"] as? String)
    }

    func testCanEncode_eventError_emptyReportNotEncoded() {
        let report = EdgeErrorReport(eventIndex: 1, errors: nil, requestId: nil, orgId: nil)
        let error = EdgeEventError(title: "Test Error", detail: "details", status: 200, type: "error", report: report)

        XCTAssertFalse(report.shouldEncode()) // EdgeErrorReport is not encoded if it only contains eventIndex

        let encoded = error.asDictionary()

        XCTAssertNotNil(encoded)
        XCTAssertEqual(4, encoded?.count)
        XCTAssertEqual("Test Error", encoded?["title"] as? String)
        XCTAssertEqual("details", encoded?["detail"] as? String)
        XCTAssertEqual(200, encoded?["status"] as? Int)
        XCTAssertEqual("error", encoded?["type"] as? String)
        XCTAssertNil(encoded?["report"])
    }

}

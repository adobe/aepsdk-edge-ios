//
// Copyright 2021 Adobe. All rights reserved.
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

class ImplementationDetailsTests: XCTestCase {
    private let BASE_NAMESPACE = "https://ns.adobe.com/experience/mobilesdk/ios"
    private let WRAPPER_REACT_NATIVE = "reactnative"

    override func setUp() {
        continueAfterFailure = false // fail so nil checks stop execution
    }

    // MARK: from tests

    func testFrom_withVersion_withWrapperReact() {
        let hubSharedState: [String: Any] = [
            "version": "3.3.1",
            "wrapper": ["type": "R"]
        ]

        guard let details = ImplementationDetails.from(hubSharedState) else {
            XCTFail("ImplementationDetails returned nil when not expected.")
            return
        }

        let actualResult = flattenDictionary(dict: details)

        let expectedResult: [String: Any] = [
            "name": "\(BASE_NAMESPACE)/\(WRAPPER_REACT_NATIVE)",
            "environment": "app",
            "version": "3.3.1+\(EdgeConstants.EXTENSION_VERSION)"
        ]
        assertEqual(expectedResult, actualResult)
    }

    func testFrom_withVersion_withWrapperNone() {
        let hubSharedState: [String: Any] = [
            "version": "3.3.1",
            "wrapper": ["type": "N"]
        ]

        guard let details = ImplementationDetails.from(hubSharedState) else {
            XCTFail("ImplementationDetails returned nil when not expected.")
            return
        }

        let actualResult = flattenDictionary(dict: details)

        let expectedResult: [String: Any] = [
            "name": "\(BASE_NAMESPACE)",
            "environment": "app",
            "version": "3.3.1+\(EdgeConstants.EXTENSION_VERSION)"
        ]
        assertEqual(expectedResult, actualResult)
    }

    func testFrom_withVersion_withWrapperFlutter() {
        let hubSharedState: [String: Any] = [
            "version": "3.3.1",
            "wrapper": ["type": "F"] // Flutter not supported yet, expect None type
        ]

        guard let details = ImplementationDetails.from(hubSharedState) else {
            XCTFail("ImplementationDetails returned nil when not expected.")
            return
        }

        let actualResult = flattenDictionary(dict: details)

        let expectedResult: [String: Any] = [
            "name": "\(BASE_NAMESPACE)",
            "environment": "app",
            "version": "3.3.1+\(EdgeConstants.EXTENSION_VERSION)"
        ]
        assertEqual(expectedResult, actualResult)
    }

    func testFrom_withVersion_withNoWrapperType() {
        let hubSharedState: [String: Any] = [
            "version": "3.3.1",
            "wrapper": ["invalid": "R"]
        ]

        guard let details = ImplementationDetails.from(hubSharedState) else {
            XCTFail("ImplementationDetails returned nil when not expected.")
            return
        }

        let actualResult = flattenDictionary(dict: details)

        let expectedResult: [String: Any] = [
            "name": "\(BASE_NAMESPACE)/unknown",
            "environment": "app",
            "version": "3.3.1+\(EdgeConstants.EXTENSION_VERSION)"
        ]
        assertEqual(expectedResult, actualResult)
    }

    func testFrom_withVersion_withWrongWrapperType() {
        let hubSharedState: [String: Any] = [
            "version": "3.3.1",
            "wrapper": "not map type" // wrong type, expected [String: Any]
        ]

        guard let details = ImplementationDetails.from(hubSharedState) else {
            XCTFail("ImplementationDetails returned nil when not expected.")
            return
        }

        let actualResult = flattenDictionary(dict: details)

        let expectedResult: [String: Any] = [
            "name": "\(BASE_NAMESPACE)/unknown",
            "environment": "app",
            "version": "3.3.1+\(EdgeConstants.EXTENSION_VERSION)"
        ]
        assertEqual(expectedResult, actualResult)
    }

    func testFrom_withVersion_withNoWrapper() {
        let hubSharedState: [String: Any] = [
            "version": "3.3.1"
        ]

        guard let details = ImplementationDetails.from(hubSharedState) else {
            XCTFail("ImplementationDetails returned nil when not expected.")
            return
        }

        let actualResult = flattenDictionary(dict: details)

        let expectedResult: [String: Any] = [
            "name": "\(BASE_NAMESPACE)",
            "environment": "app",
            "version": "3.3.1+\(EdgeConstants.EXTENSION_VERSION)"
        ]
        assertEqual(expectedResult, actualResult)
    }

    func testFrom_withWrongVersionType_withNoWrapper() {
        let hubSharedState: [String: Any] = [
            "version": ["not string type": "3.3.1"] // wrong type, expected String
        ]

        guard let details = ImplementationDetails.from(hubSharedState) else {
            XCTFail("ImplementationDetails returned nil when not expected.")
            return
        }

        let actualResult = flattenDictionary(dict: details)

        let expectedResult: [String: Any] = [
            "name": "\(BASE_NAMESPACE)",
            "environment": "app",
            "version": "unknown+\(EdgeConstants.EXTENSION_VERSION)"
        ]
        assertEqual(expectedResult, actualResult)
    }

    func testFrom_withNoVersion_withWrapperReact() {
        let hubSharedState: [String: Any] = [
            "wrapper": ["type": "R"]
        ]

        guard let details = ImplementationDetails.from(hubSharedState) else {
            XCTFail("ImplementationDetails returned nil when not expected.")
            return
        }

        let actualResult = flattenDictionary(dict: details)

        let expectedResult: [String: Any] = [
            "name": "\(BASE_NAMESPACE)/\(WRAPPER_REACT_NATIVE)",
            "environment": "app",
            "version": "unknown+\(EdgeConstants.EXTENSION_VERSION)"
        ]
        assertEqual(expectedResult, actualResult)
    }

    func testFrom_withEmptyHubState() {
        let hubSharedState: [String: Any] = [:]

        XCTAssertNil(ImplementationDetails.from(hubSharedState))
    }

    func testFrom_withNilHubState() {
        XCTAssertNil(ImplementationDetails.from(nil))
    }
}

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
    private let WRAPPER_REACT_NATIVE = "reactnative"
    private let WRAPPER_CORDOVA = "cordova"
    private let WRAPPER_FLUTTER = "flutter"
    private let WRAPPER_UNITY = "unity"
    private let WRAPPER_XAMARIN = "xamarin"

    #if os(iOS)
    private let BASE_NAMESPACE = "https://ns.adobe.com/experience/mobilesdk/ios"
    #elseif os(tvOS)
    private let BASE_NAMESPACE = "https://ns.adobe.com/experience/mobilesdk/tvos"
    #endif

    override func setUp() {
        continueAfterFailure = false // fail so nil checks stop execution
    }

    // MARK: from tests

    func testFrom_withVersion_withWrapperNone() {
        assertWrapper(inputType: "N", outputNamespace: BASE_NAMESPACE)
    }

    func testFrom_withVersion_withWrapperReact() {
        assertWrapper(inputType: "R", outputNamespace: "\(BASE_NAMESPACE)/\(WRAPPER_REACT_NATIVE)")
    }

    func testFrom_withVersion_withWrapperFlutter() {
        assertWrapper(inputType: "F", outputNamespace: "\(BASE_NAMESPACE)/\(WRAPPER_FLUTTER)")
    }

    func testFrom_withVersion_withWrapperCordova() {
        assertWrapper(inputType: "C", outputNamespace: "\(BASE_NAMESPACE)/\(WRAPPER_CORDOVA)")
    }

    func testFrom_withVersion_withWrapperUnity() {
        assertWrapper(inputType: "U", outputNamespace: "\(BASE_NAMESPACE)/\(WRAPPER_UNITY)")
    }

    func testFrom_withVersion_withWrapperXamarin() {
        assertWrapper(inputType: "X", outputNamespace: "\(BASE_NAMESPACE)/\(WRAPPER_XAMARIN)")
    }

    func testFrom_withVersion_withWrapperUnknown() {
        // An unknown type defaults to None
        assertWrapper(inputType: "A", outputNamespace: BASE_NAMESPACE)
    }

    func testFrom_withVersion_withNoWrapperType() {
        let hubSharedState: [String: Any] = [
            "version": "3.3.1",
            "wrapper": ["invalid": "R"] // no "type" element
        ]

        assertImplementationDetails(inputState: hubSharedState,
                                    outputNamespace: "\(BASE_NAMESPACE)/unknown",
                                    outputVersion: "3.3.1+\(EdgeConstants.EXTENSION_VERSION)")
    }

    func testFrom_withVersion_withWrongWrapperType() {
        let hubSharedState: [String: Any] = [
            "version": "3.3.1",
            "wrapper": "not map type" // wrong type, expected [String: Any]
        ]

        assertImplementationDetails(inputState: hubSharedState,
                                    outputNamespace: "\(BASE_NAMESPACE)/unknown",
                                    outputVersion: "3.3.1+\(EdgeConstants.EXTENSION_VERSION)")
    }

    func testFrom_withVersion_withNoWrapper() {
        let hubSharedState: [String: Any] = [
            "version": "3.3.1"
        ]

        assertImplementationDetails(inputState: hubSharedState,
                                    outputNamespace: "\(BASE_NAMESPACE)",
                                    outputVersion: "3.3.1+\(EdgeConstants.EXTENSION_VERSION)")
    }

    func testFrom_withWrongVersionType_withNoWrapper() {
        let hubSharedState: [String: Any] = [
            "version": ["not string type": "3.3.1"] // wrong type, expected String
        ]

        assertImplementationDetails(inputState: hubSharedState,
                                    outputNamespace: "\(BASE_NAMESPACE)",
                                    outputVersion: "unknown+\(EdgeConstants.EXTENSION_VERSION)")
    }

    func testFrom_withNoVersion_withWrapperReact() {
        let hubSharedState: [String: Any] = [
            "wrapper": ["type": "R"]
        ]

        assertImplementationDetails(inputState: hubSharedState,
                                    outputNamespace: "\(BASE_NAMESPACE)/\(WRAPPER_REACT_NATIVE)",
                                    outputVersion: "unknown+\(EdgeConstants.EXTENSION_VERSION)")
    }

    func testFrom_withEmptyHubState() {
        let hubSharedState: [String: Any] = [:]

        XCTAssertNil(ImplementationDetails.from(hubSharedState))
    }

    func testFrom_withNilHubState() {
        XCTAssertNil(ImplementationDetails.from(nil))
    }

    /// Assert given wrapper type produces the expected Implementation Details namespace.
    /// - Parameters:
    ///   - inputType: the wrapper type tag
    ///   - outputNamespace: the expected Implementation Details namespace URI
    ///   - file: the file which called this method
    ///   - line: the line in `file` which calls this method
    private func assertWrapper(inputType: String, outputNamespace: String, file: StaticString = #file, line: UInt = #line) {
        let hubSharedState: [String: Any] = [
            "version": "3.3.1",
            "wrapper": ["type": inputType]
        ]

        assertImplementationDetails(inputState: hubSharedState,
                                    outputNamespace: outputNamespace,
                                    outputVersion: "3.3.1+\(EdgeConstants.EXTENSION_VERSION)",
                                    file: (file),
                                    line: line)
    }

    /// Assert given shared state data produces the expected Implementation Details namespace and version.
    /// - Parameters:
    ///   - inputState: the input shared state
    ///   - outputNamespace: the expected Implementation Details namespace URI
    ///   - outputVersion: the expected Implementation Details version
    ///   - file: the file which called this method
    ///   - line: the line in `file` which calls this method
    private func assertImplementationDetails(inputState: [String: Any], outputNamespace: String, outputVersion: String, file: StaticString = #file, line: UInt = #line) {

        guard let details = ImplementationDetails.from(inputState) else {
            XCTFail("ImplementationDetails returned nil when not expected for test.", file: (file), line: line)
            return
        }

        let actualResult = flattenDictionary(dict: details)

        let expectedResult: [String: Any] = [
            "name": "\(outputNamespace)",
            "environment": "app",
            "version": "\(outputVersion)"
        ]
        assertEqual(expectedResult, actualResult, file: (file), line: line)
    }
}

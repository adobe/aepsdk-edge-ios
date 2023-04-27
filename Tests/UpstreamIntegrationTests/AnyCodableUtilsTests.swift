//
// Copyright 2023 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPServices
import Foundation
import XCTest

class AnyCodableUtilsTests: XCTestCase {

    // MARK: - Regex parsing
    func testEscapedKeyPaths() {
        let expectedJSON = #"""
        {
          "key1.key2": {
            "key3": "value3"
          }
        }
        """#

        let actualJSON = #"""
        {
          "key1.key2": {
            "key3": "value1"
          }
        }
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertContains(expected: expected, actual: actual, mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: [#"key1\.key2"#])
        XCTExpectFailure("The following should fail") {
            assertContains(expected: expected, actual: actual, alternateModePaths: [#"key1\.key2"#], mode: .typeMatch)
            assertContains(expected: expected, actual: actual)
            assertEqual(expected: expected, actual: actual)
        }
    }

    // MARK: - Empty collection tests
    func testDictionary_whenEmpty_isEqual() {
        let expectedJSON = #"""
        {}
        """#

        let actualJSON = #"""
        {}
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertContains(expected: expected, actual: actual, mode: .typeMatch)
        assertContains(expected: expected, actual: actual)
        assertEqual(expected: expected, actual: actual)
    }

    func testDictionary_whenNested_isEqual() {
        let expectedJSON = #"""
        {
          "key0": {
            "key1": {}
          }
        }
        """#

        let actualJSON = #"""
        {
          "key0": {
            "key1": {}
          }
        }
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertContains(expected: expected, actual: actual, mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["key0"], mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["key0.key1"], mode: .typeMatch)
        assertContains(expected: expected, actual: actual)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["key0"])
        assertContains(expected: expected, actual: actual, alternateModePaths: ["key0.key1"])
        assertEqual(expected: expected, actual: actual)
    }

    func testArray_whenEmpty_isEqual() {
        let expectedJSON = #"""
        []
        """#

        let actualJSON = #"""
        []
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertContains(expected: expected, actual: actual, mode: .typeMatch)
        assertContains(expected: expected, actual: actual)
        assertEqual(expected: expected, actual: actual)
    }

    func testArray_whenEmptyNested_isEqual() {
        let expectedJSON = #"""
        [[]]
        """#

        let actualJSON = #"""
        [[]]
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertContains(expected: expected, actual: actual, mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*]"], mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]"], mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]"], mode: .typeMatch)
        assertContains(expected: expected, actual: actual)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*]"])
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]"])
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]"])
        assertEqual(expected: expected, actual: actual)
    }

    func testArray_whenNestedDictionary_isEqual() {
        let expectedJSON = #"""
        [{}]
        """#

        let actualJSON = #"""
        [{}]
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertContains(expected: expected, actual: actual, mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*]"], mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]"], mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]"], mode: .typeMatch)
        assertContains(expected: expected, actual: actual)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*]"])
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]"])
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]"])
        assertEqual(expected: expected, actual: actual)
    }

    func testDictionary_whenNestedArray_isEqual() {
        let expectedJSON = #"""
        {
          "key0": []
        }
        """#

        let actualJSON = #"""
        {
          "key0": []
        }
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertContains(expected: expected, actual: actual, mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["key0"], mode: .typeMatch)
        assertContains(expected: expected, actual: actual)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["key0"])
        assertEqual(expected: expected, actual: actual)
    }

    func testSingleKeyEquality() {
        let expectedJSON = #"""
        {
            "key1": "value1"
        }
        """#

        let actualJSON = #"""
        {
            "key1": "value1"
        }
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertContains(expected: expected, actual: actual, mode: .typeMatch)
        assertContains(expected: expected, actual: actual)
        assertEqual(expected: expected, actual: actual)
    }

    func testSingleKey_flexibleEquality() {
        let expectedJSON = #"""
        {
            "key1": ""
        }
        """#

        let actualJSON = #"""
        {
            "key1": "value1"
        }
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertContains(expected: expected, actual: actual, mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["key1"])
        XCTExpectFailure("The following should fail") {
            assertContains(expected: expected, actual: actual)
            assertEqual(expected: expected, actual: actual)
        }
    }

    func testArray_whenExpectedHasFewerElements_isEqual() {
        let expectedJSON = #"""
        [1,2,3]
        """#

        let actualJSON = #"""
        [1,2,3,4,5,6]
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertContains(expected: expected, actual: actual, mode: .typeMatch)
        assertContains(expected: expected, actual: actual)
        XCTExpectFailure("The following should fail") {
            assertContains(expected: expected, actual: actual)
            assertEqual(expected: expected, actual: actual)
        }
    }

    func testArray_whenExpectedHasMoreElements() {
        let expectedJSON = #"""
        [1,2,3,4,5,6]
        """#

        let actualJSON = #"""
        [1,2,3]
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        XCTExpectFailure("The following should fail") {
            assertContains(expected: expected, actual: actual, mode: .typeMatch)
            assertContains(expected: expected, actual: actual)
            assertEqual(expected: expected, actual: actual)
        }
    }

    func testArray_whenExpectedHasFewerElements_sameType() {
        let expectedJSON = #"""
        [0,1,2,4]
        """#

        let actualJSON = #"""
        [9,9,9,4,9,9]
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertContains(expected: expected, actual: actual, mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]", "[1]", "[2]"])
        XCTExpectFailure("The following should fail") {
            // Type match
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]", "[1]", "[2]"], mode: .typeMatch)
            // Exact match
            assertContains(expected: expected, actual: actual)
            assertEqual(expected: expected, actual: actual)
        }
    }

    func testArray_whenGeneralWildcard() {
        let expectedJSON = #"""
        [0,1,2]
        """#

        let actualJSON = #"""
        [9,9,9,0,1,2]
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }
//        assertContains(expected: expected, actual: actual)

        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*]"], mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]", "[*1]", "[*2]"], mode: .typeMatch)

        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*]"])
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]", "[*1]", "[*2]"])
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]", "[1]", "[2]"])
        XCTExpectFailure("The following should fail") {
            // Type match
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]", "[1]", "[2]"], mode: .typeMatch)
            // Exact match
            assertContains(expected: expected, actual: actual)
                // Partials
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]", "[*2]"])
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]", "[1]"])
            assertEqual(expected: expected, actual: actual)
        }
    }

    func testArray_whenMixedWildcardPaths() {
        let expectedJSON = #"""
        [0,1,2]
        """#

        let actualJSON = #"""
        ["a","b",2,0,1,9]
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*]", "[*1]", "[2]"], mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[2]", "[*1]", "[*]"], mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]", "[*1]", "[*2]"], mode: .typeMatch)

        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*]"], mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]", "[*1]", "[*2]"], mode: .typeMatch)

        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*]", "[*1]", "[2]"])
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[2]", "[*1]", "[*]"])

        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*]"])
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]", "[*1]", "[*2]"])

        XCTExpectFailure("The following should fail") {
            // Type match
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]", "[1]", "[2]"], mode: .typeMatch)
            // Exact match
            assertContains(expected: expected, actual: actual)
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]", "[1]", "[2]"])
                // Partials
            // Note the precedence of evaluation affecting the test passing
            // In this case, [*<INT>] is evaluated before non path keys (that is index 2)
            // so [*0] -> 0 takes index 2 -> 2
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]", "[*1]"])
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]", "[*2]"])
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]", "[1]"])
            assertEqual(expected: expected, actual: actual)
        }
    }

    func testArray_whenGeneralWildcard_typeMismatch_mustFail() {
        let expectedJSON = #"""
        [0,1,2]
        """#

        let actualJSON = #"""
        ["a","b","c","d","e",2]
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        XCTExpectFailure("The following should fail") {
            // Type match
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[*]"], mode: .typeMatch)
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]", "[*1]", "[*2]"], mode: .typeMatch)
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]", "[1]", "[2]"], mode: .typeMatch)
            // Exact match
            assertContains(expected: expected, actual: actual)
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[*]"])
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]", "[*1]", "[*2]"])
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]", "[1]", "[2]"])
                // Partials
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]", "[*2]"])
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]", "[1]"])
            assertEqual(expected: expected, actual: actual)
        }
    }

    func testArray_whenGeneralWildcard_typeMismatch() {
        let expectedJSON = #"""
        [0,1,2]
        """#

        let actualJSON = #"""
        ["a","b","c",0,1,2]
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*]"], mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]", "[*1]", "[*2]"], mode: .typeMatch)

        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*]"])
        assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]", "[*1]", "[*2]"])
        XCTExpectFailure("The following should fail") {
            // Type match
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]", "[1]", "[2]"], mode: .typeMatch)
            // Exact match
            assertContains(expected: expected, actual: actual)
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]", "[1]", "[2]"])
                // Partials
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[*0]", "[*2]"])
            assertContains(expected: expected, actual: actual, alternateModePaths: ["[0]", "[1]"])
            assertEqual(expected: expected, actual: actual)
        }
    }

    func testDictionary_whenExpectedHasMoreElements() {
        let expectedJSON = #"""
        {
          "key0": 9,
          "key1": 9,
          "key2": 2,
          "key3": 3,
          "key4": 4,
          "key5": 5
        }
        """#

        let actualJSON = #"""
        {
          "key0": 0,
          "key1": 1,
          "key2": 2
        }
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        XCTExpectFailure("The following should fail") {
            // Type match
            assertContains(expected: expected, actual: actual, mode: .typeMatch)
            assertContains(expected: expected, actual: actual, alternateModePaths: ["key0", "key1"], mode: .typeMatch)
            // Exact match
            assertContains(expected: expected, actual: actual)
            assertContains(expected: expected, actual: actual, alternateModePaths: ["key0", "key1"])
            assertEqual(expected: expected, actual: actual)
        }
    }

    func testDictionary_whenExpectedHasFewerElements_sameType() {
        let expectedJSON = #"""
        {
          "key0": 0,
          "key1": 1,
          "key2": 2
        }
        """#

        let actualJSON = #"""
        {
          "key0": 9,
          "key1": 9,
          "key2": 2,
          "key3": 3,
          "key4": 4,
          "key5": 5
        }
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertContains(expected: expected, actual: actual, mode: .typeMatch)
        assertContains(expected: expected, actual: actual, alternateModePaths: ["key0", "key1"])
        XCTExpectFailure("The following should fail") {
            // Type match
            // 2 Failures
            assertContains(expected: expected, actual: actual, alternateModePaths: ["key0", "key1"], mode: .typeMatch)
            // Exact match
            // 2 Failures
            assertContains(expected: expected, actual: actual)
            // 1 Failures - fail count check
            assertEqual(expected: expected, actual: actual)
        }
    }

    func testLocationHint_onlyExpectedKeys() {
        let expectedJSON = #"""
        {
          "payload": [
            {
              "scope" : "EdgeNetwork"
            },
            {
              "scope" : "Target"
            }
          ]
        }
        """#

        let actualJSON = #"""
           {
             "payload": [
               {
                 "ttlSeconds" : 1800,
                 "scope" : "Target",
                 "hint" : "35"
               },
               {
                 "ttlSeconds" : 1800,
                 "scope" : "AAM",
                 "hint" : "9"
               },
               {
                 "ttlSeconds" : 1800,
                 "scope" : "EdgeNetwork",
                 "hint" : "or2"
               }
             ]
           }
        """#

        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }
        assertContains(expected: expected, actual: actual, alternateModePaths: ["payload[*].scope"], mode: .typeMatch)
    }

    // MARK: - Test helpers

    func getAnyCodable(_ jsonString: String) -> AnyCodable? {
        return try? JSONDecoder().decode(AnyCodable.self, from: jsonString.data(using: .utf8)!)
    }
}

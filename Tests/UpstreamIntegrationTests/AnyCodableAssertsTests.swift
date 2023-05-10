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

class AnyCodableAssertsTests: XCTestCase {
    func testPathExtraction() {
        let expectedJSON = #"""
        {
          "": {
            "": "value3"
          }
        }
        """#
        
        let actualJSON = #"""
        {
          "": {
            "": "value2"
          }
        }
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }
        
        // Matches top level empty string key: ""
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [""])
        // Matches nested empty string key: "" -> ""
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [#"."#])
        
        XCTExpectFailure("The following should fail") {
            assertExactMatch(expected: expected, actual: actual)
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [#"\\\\"#]) // double backslash
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [#"\."#]) // escaped .
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [#"\.."#]) // escaped . + ""
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [#".\.."#]) // "" + escaped / + ""
            assertEqual(expected: expected, actual: actual)
        }
    }
    
    func testPathExtraction_specialCharacters() {
        let expectedJSON = #"""
        {
          "\\": {
            "": "value3"
          }
        }
        """#
        
        let actualJSON = #"""
        {
          "\\": {
            "": "value2"
          }
        }
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }
        
        // Matches backslash literal key: "\"
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["\\"])
        
        XCTExpectFailure("The following should fail") {
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [#""#])
            assertExactMatch(expected: expected, actual: actual)
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [#"\\\\"#]) // double backslash
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [#"\."#]) // escaped .
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [#"\.."#]) // escaped . + ""
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [#".\.."#]) // "" + escaped / + ""
            assertEqual(expected: expected, actual: actual)
        }
    }

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

        assertTypeMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [#"key1\.key2"#])
        XCTExpectFailure("The following should fail") {
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: [#"key1\.key2"#])
            assertExactMatch(expected: expected, actual: actual)
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
        assertTypeMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual)
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

        assertTypeMatch(expected: expected, actual: actual)
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["key0"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["key0.key1"])
        assertExactMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["key0"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["key0.key1"])
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

        assertTypeMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual)
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

        assertTypeMatch(expected: expected, actual: actual)
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]"])

        assertExactMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]"])

        assertEqual(expected: expected, actual: actual)
    }
    
    func testArray_whenNestedRequiresSpecificIndex_isEqual() {
        let expectedJSON = #"""
        [
          1,
          [
            2,3
          ]
        ]
        """#

        let actualJSON = #"""
        [
          1,
          [
            4,5
          ]
        ]
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertTypeMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[1][0]", "[1][1]"])
        XCTExpectFailure("The following should fail") {
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[1][0]", "[1][1]"])
            assertEqual(expected: expected, actual: actual)
        }
    }

    func testArray_whenDeeplyNested_isEqual() {
        let expectedJSON = #"""
        [[[[[[[[]]]]]]]]
        """#

        let actualJSON = #"""
        [[[[[[[[]]]]]]]]
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertTypeMatch(expected: expected, actual: actual)
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]"])

        assertExactMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]"])

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

        assertTypeMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual)
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]"])
        assertEqual(expected: expected, actual: actual)
    }

    func testArray_whenMultiType_isEqual() {
        let expectedJSON = #"""
        [
          {
            "key1": "value1"
          },
          123,
          "string",
          false,
          null
        ]
        """#

        let actualJSON = #"""
        [
          {
            "key1": "value1"
          },
          123,
          "string",
          false,
          null
        ]
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertTypeMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual)
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]"])
        assertEqual(expected: expected, actual: actual)
    }

    func testDictionary_whenNestedArray_withMultiType_isEqual() {
        let expectedJSON = #"""
        {
          "key0": [
            {
              "key1": "value1"
            },
            123,
            "string",
            false,
            null
          ]
        }
        """#

        let actualJSON = #"""
        {
          "key0": [
            {
              "key1": "value1"
            },
            123,
            "string",
            false,
            null
          ]
        }
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        assertTypeMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual)
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["key0"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["key0"])
        assertEqual(expected: expected, actual: actual)
    }

    func testDictionary_whenMultiType_isEqual() {
        let expectedJSON = #"""
        {
          "integerCompare": 456,
          "decimalCompare": 123.123,
          "stringCompare": "abc",
          "boolCompare": true,
          "nullCompare": null,
          "arraySizeCompare": [1,2,3],
          "arrayValueCompare": [1],
          "arrayOfObjectsPass": [
            {
              "object1": "value1"
            },
            {
              "object2": "value2"
            }
          ],
          "arrayOfObjectsFail": [
            {
              "object1": "value1"
            },
            {
              "object2": "value2"
            }
          ],
          "dictionaryCompare": {
            "nested1": "value1"
          },
          "dictionaryNestedCompare": {
            "nested1": {
              "nested2": {
                "nested3": {
                  "nested4": {
                    "nested1": "value1"
                  }
                }
              }
            }
          },
          "trulyNested": [
            {
              "nest1": [
                {
                  "nest2": {
                    "nest3": [
                      {
                        "nest4": "value1"
                      }
                    ]
                  }
                }
              ]
            }
          ]
        }

        """#

        let actualJSON = #"""
        {
          "integerCompare": 0,
          "decimalCompare": 4.123,
          "stringCompare": "def",
          "boolCompare": false,
          "nullCompare": "not null",
          "arraySizeCompare": [1,2],
          "arrayValueCompare": [0],
          "arrayOfObjectsPass": [
            {
              "object1": "value1"
            },
            {
              "object2": "value2"
            }
          ],
          "arrayOfObjectsFail": [
            {
              "object1": "value1"
            },
            {
              "object2": "value3"
            }
          ],
          "dictionaryCompare": {
            "nested1different": "value1"
          },
          "dictionaryNestedCompare": {
            "nested1": {
              "nested2": {
                "nested3": {
                  "nested4": {
                    "nested1": "value2"
                  }
                }
              }
            }
          },
          "trulyNested": [
            {
              "nest1": [
                {
                  "nest2": {
                    "nest3": [
                      [
                        "nest4"
                      ]
                    ]
                  }
                }
              ]
            }
          ]
        }
        """#
        guard let expected = getAnyCodable(expectedJSON), let actual = getAnyCodable(actualJSON) else {
            XCTFail("Unable to decode JSON string. Test case unable to proceed.")
            return
        }

        // Match with exact same should pass
        assertTypeMatch(expected: expected, actual: expected)
        assertExactMatch(expected: expected, actual: expected)
        assertEqual(expected: expected, actual: expected)

        XCTExpectFailure("The following should fail") {
            assertTypeMatch(expected: expected, actual: actual)
            assertExactMatch(expected: expected, actual: actual)
            assertEqual(expected: expected, actual: actual)
        }
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

        assertTypeMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual)
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["key0"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["key0"])
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

        assertTypeMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual)
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

        assertTypeMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["key1"])
        XCTExpectFailure("The following should fail") {
            assertExactMatch(expected: expected, actual: actual)
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

        assertTypeMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual)
        XCTExpectFailure("The following should fail") {
            assertExactMatch(expected: expected, actual: actual)
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
            assertTypeMatch(expected: expected, actual: actual)
            assertExactMatch(expected: expected, actual: actual)
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

        assertTypeMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]", "[1]", "[2]"])
        XCTExpectFailure("The following should fail") {
            // Type match
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]", "[1]", "[2]"])
            // Exact match
            assertExactMatch(expected: expected, actual: actual)
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

        assertTypeMatch(expected: expected, actual: actual)
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]", "[*1]", "[*2]"])

        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]", "[*1]", "[*2]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]", "[1]", "[2]"])

        XCTExpectFailure("The following should fail") {
            // Type match
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]", "[1]", "[2]"])
            // Exact match
            assertExactMatch(expected: expected, actual: actual)
                // Partials
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]", "[*2]"])
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]", "[1]"])
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

        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]", "[*1]", "[2]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[2]", "[*1]", "[*]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]", "[*1]", "[*2]"])

        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*]", "[*1]", "[2]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[2]", "[*1]", "[*]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]", "[*1]", "[*2]"])

        XCTExpectFailure("The following should fail") {
            // Type match
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]", "[1]", "[2]"])
            // Exact match
            assertExactMatch(expected: expected, actual: actual)
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]", "[1]", "[2]"])
                // Partials
            // Note the precedence of evaluation affecting the test passing
            // In this case, [*<INT>] is evaluated before non path keys (that is index 2)
            // so [*0] -> 0 takes index 2 -> 2
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]", "[*1]"])
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]", "[*2]"])
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]", "[1]"])
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
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]", "[*1]", "[*2]"])
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]", "[1]", "[2]"])
            // Exact match
            assertExactMatch(expected: expected, actual: actual)
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*]"])
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]", "[*1]", "[*2]"])
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]", "[1]", "[2]"])
                // Partials
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]", "[*2]"])
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]", "[1]"])
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

        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]", "[*1]", "[*2]"])

        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]", "[*1]", "[*2]"])
        XCTExpectFailure("The following should fail") {
            // Type match
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]", "[1]", "[2]"])
            // Exact match
            assertExactMatch(expected: expected, actual: actual)
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]", "[1]", "[2]"])
                // Partials
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]", "[*2]"])
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]", "[1]"])
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
            assertTypeMatch(expected: expected, actual: actual)
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["key0", "key1"])
            // Exact match
            assertExactMatch(expected: expected, actual: actual)
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["key0", "key1"])
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

        assertTypeMatch(expected: expected, actual: actual)
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["key0", "key1"])
        XCTExpectFailure("The following should fail") {
            // Type match
            // 2 Failures
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["key0", "key1"])
            // Exact match
            // 2 Failures
            assertExactMatch(expected: expected, actual: actual)
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
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["payload[*].scope"])
    }
}

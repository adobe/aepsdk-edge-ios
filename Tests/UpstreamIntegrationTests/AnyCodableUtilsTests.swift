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
    override func setUp() {

    }
    
    public override func tearDown() {
        super.tearDown()
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
        
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
        
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["key0"])
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["key0.key1"])
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["key0"])
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["key0.key1"])
        AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
        
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
        
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]"])
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]"])
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*]"])
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*0]"])
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[0]"])
        AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
        
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]"])
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]"])
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*]"])
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*0]"])
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[0]"])
        AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
        
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["key0"])
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["key0"])
        AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
        
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
        
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["key1"])
        XCTExpectFailure("The following should fail") {
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
            AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
        
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
        XCTExpectFailure("The following should fail") {
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
            AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
            AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual)
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
            AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
        
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[0]","[1]","[2]"])
        XCTExpectFailure("The following should fail") {
            // Type match
            AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]","[1]","[2]"])
            // Exact match
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
            AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
//        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
        
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]","[*1]","[*2]"])
        
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*]"])
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*0]","[*1]","[*2]"])
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[0]","[1]","[2]"])
        XCTExpectFailure("The following should fail") {
            // Type match
            AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]","[1]","[2]"])
            // Exact match
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
                // Partials
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*0]","[*2]"])
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[0]","[1]"])
            AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]", "[*1]", "[2]"])
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[2]", "[*1]", "[*]"])
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]", "[*1]", "[*2]"])
        
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]","[*1]","[*2]"])
        
        
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*]","[*1]","[2]"])
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[2]","[*1]","[*]"])
        
        
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*]"])
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*0]","[*1]","[*2]"])
        
        XCTExpectFailure("The following should fail") {
            // Type match
            AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]","[1]","[2]"])
            // Exact match
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[0]","[1]","[2]"])
                // Partials
            // Note the precedence of evaluation affecting the test passing
            // In this case, [*<INT>] is evaluated before non path keys (that is index 2)
            // so [*0] -> 0 takes index 2 -> 2
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*0]","[*1]"])
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*0]","[*2]"])
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[0]","[1]"])
            AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
            AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
            AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]","[*1]","[*2]"])
            AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]","[1]","[2]"])
            // Exact match
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*]"])
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*0]","[*1]","[*2]"])
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[0]","[1]","[2]"])
                // Partials
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*0]","[*2]"])
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[0]","[1]"])
            AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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

        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]","[*1]","[*2]"])
        
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*]"])
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*0]","[*1]","[*2]"])
        XCTExpectFailure("The following should fail") {
            // Type match
            AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]","[1]","[2]"])
            // Exact match
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[0]","[1]","[2]"])
                // Partials
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[*0]","[*2]"])
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["[0]","[1]"])
            AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
            AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual)
            AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["key0","key1"])
            // Exact match
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["key0","key1"])
            AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
        
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual)
        AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual, flexibleMatchPaths: ["key0","key1"])
        XCTExpectFailure("The following should fail") {
            // Type match
            // 2 Failures
            AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["key0","key1"])
            // Exact match
            // 2 Failures
            AnyCodableUtils.assertContainsDefaultExactMatch(expected: expected, actual: actual)
            // 1 Failures - fail count check
            AnyCodableUtils.assertEqual(expected: expected, actual: actual)
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
        
        AnyCodableUtils.assertContainsDefaultTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["payload[*].scope"])
    }
    
    // MARK: - Test helpers
    
    func getAnyCodable(_ jsonString: String) -> AnyCodable? {
        return try? JSONDecoder().decode(AnyCodable.self, from: jsonString.data(using: .utf8)!)
    }
}

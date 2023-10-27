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
    /// Validates `null` equated to itself is true
    func testShouldMatchWhenBothValuesAreNil() {
        let expected: AnyCodable? = nil
        let actual: AnyCodable? = nil
        assertEqual(expected: expected, actual: actual)
    }

    // MARK: - Alternate path tests - assertEqual does not handle alternate paths and is not tested here

    /// Validates alternate path wildcards function independently of order.
    ///
    /// - Note: Tests can rely on unique sets of wildcard index values without the need to test
    /// every variation.
    func testShouldValidateAlternatePathWildcardOrderIndependence() {
        let expectedJSONString = """
        [1, 2]
        """

        let actualJSONString = """
        ["a", "b", 1, 2]
        """
        let expected = getAnyCodable(expectedJSONString)!
        let actual = getAnyCodable(actualJSONString)!

        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]", "[*1]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*1]", "[*0]"])

        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]", "[*1]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*1]", "[*0]"])
    }

    /// Validates that the wildcard character `*` can only be placed to the left of the index value.
    func testShouldValidateWildcardIndexFormats() {
        let expectedJSONString = """
        [1]
        """

        let actualJSONString = """
        ["a", 1]
        """
        let expected = getAnyCodable(expectedJSONString)!
        let actual = getAnyCodable(actualJSONString)!

        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]"])
        XCTExpectFailure("Validation should fail when using an invalid wildcard format") {
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[**0]"])
        }
        XCTExpectFailure("Validation should fail when using an invalid wildcard format") {
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0*]"])
        }
        XCTExpectFailure("Validation should fail when using an invalid wildcard format") {
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0*0]"])
        }

        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]"])
        XCTExpectFailure("Validation should fail when using an invalid wildcard format") {
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[**0]"])
        }
        XCTExpectFailure("Validation should fail when using an invalid wildcard format") {
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0*]"])
        }
        XCTExpectFailure("Validation should fail when using an invalid wildcard format") {
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0*0]"])
        }
    }

    /// Validates:
    /// 1. Specific index alternate path checks only against its paired index, as expected.
    /// 2. Wildcard index allows for matching other positions.
    func testShouldMatchSpecificIndexToPairedIndexAndWildcardToAnyPosition() {
        let expectedJSONString = """
        [1]
        """

        let actualJSONString = """
        ["a", 1]
        """
        let expected = getAnyCodable(expectedJSONString)!
        let actual = getAnyCodable(actualJSONString)!

        XCTExpectFailure("Validation should fail when matching using a specific index path without a match") {
            assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]"])
        }
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*]"])

        XCTExpectFailure("Validation should fail when matching using a specific index path without a match") {
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]"])
        }
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
    }

    /// Validates standard index matches take precedence over wildcard matches.
    ///
    /// - Note: Specifically, this checks the value at `actual[1]` is not first matched to the wildcard and
    /// fails to satisfy the unspecified index `expected[1]`.
    func testShouldPrioritizeStandardIndexMatchesOverWildcardMatches() {
        let expectedJSONString = """
        [1, 1]
        """

        let actualJSONString = """
        ["a", 1, 1]
        """
        let expected = getAnyCodable(expectedJSONString)!
        let actual = getAnyCodable(actualJSONString)!

        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*0]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*0]"])
    }

    /// Validates:
    /// 1. Specific index alternate paths should correctly match their corresponding indexes.
    /// 2. Wildcard matching should correctly match with any appropriate index.
    func testShouldMatchSpecificIndexesAndAlignWildcardsWithAppropriateIndexes() {
        let expectedJSONString = """
        [1, 2]
        """

        let actualJSONString = """
        [4, 3, 2, 1]
        """
        let expected = getAnyCodable(expectedJSONString)!
        let actual = getAnyCodable(actualJSONString)!

        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0]", "[1]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*]"])

        XCTExpectFailure("Validation should fail when matching using multiple specific index paths without a match") {
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0]", "[1]"])
        }
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*]"])
    }

    /// Validates that specific index wildcards only apply to the index specified.
    func testShouldMatchSpecificIndexWildcardToItsDesignatedIndexOnly() {
        let expectedJSONString = """
        [1, 2]
        """

        let actualJSONString = """
        [1, 3, 2, 1]
        """
        let expected = getAnyCodable(expectedJSONString)!
        let actual = getAnyCodable(actualJSONString)!

        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*1]"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*1]"])
    }

    /// Validates that array-style access chained with key-value style access functions correctly.
    /// This covers both specific index and wildcard index styles.
    func testShouldCorrectlyChainArrayStyleWithKeyValueAccess() {
        let expectedJSONString = """
        [
            {
                "key1": 1,
                "key2": 2,
                "key3": 3
            }
        ]
        """

        let actualJSONString = """
        [
            {
                "key1": 1,
                "key2": 2,
                "key3": 3
            }
        ]
        """

        let expected = getAnyCodable(expectedJSONString)!
        let actual = getAnyCodable(actualJSONString)!

        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0].key1"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[*].key1"])

        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0].key1"])
        assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[*].key1"])
    }

    /// Validates that chained array-style access functions correctly.
    func testShouldCorrectlyChainArrayStyleAccess2x() {
        let expectedJSONString = """
        [
            [1]
        ]
        """

        let actualJSONString = """
        [
            [2]
        ]
        """

        let expected = getAnyCodable(expectedJSONString)!
        let actual = getAnyCodable(actualJSONString)!

        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0][0]"])

        XCTExpectFailure("Validation should fail when using a chained specific index path without a match") {
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0][0]"])
        }
    }

    /// Validates that longer chained array-style access functions correctly.
    func testShouldCorrectlyChainArrayStyleAccess4x() {
        let expectedJSONString = """
        [[[[1]]]]
        """

        let actualJSONString = """
        [[[[2]]]]
        """

        let expected = getAnyCodable(expectedJSONString)!
        let actual = getAnyCodable(actualJSONString)!

        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["[0][0][0][0]"])

        XCTExpectFailure("Validation should fail when using a chained specific index path without a match") {
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["[0][0][0][0]"])
        }
    }

    /// Validates that key-value style access chained with array-style access functions correctly.
    /// This covers both specific index and wildcard index styles.
    func testShouldCorrectlyChainKeyValueWithArrayStyleAccess() {
        let expectedJSONString = """
        {
            "key1": [1]
        }
        """

        let actualJSONString = """
        {
            "key1": [2]
        }
        """

        let expected = getAnyCodable(expectedJSONString)!
        let actual = getAnyCodable(actualJSONString)!

        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["key1[0]"])
        assertExactMatch(expected: expected, actual: actual, typeMatchPaths: ["key1[*]"])

        XCTExpectFailure("Validation should fail when using a specific index path without a match") {
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["key1[0]"])
        }
        XCTExpectFailure("Validation should fail when using a wildcard path without a match") {
            assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: ["key1[*]"])
        }
    }

}

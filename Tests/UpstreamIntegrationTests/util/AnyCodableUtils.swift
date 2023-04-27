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

enum AssertMode {
    case exactMatch
    case typeMatch
}

protocol AnyCodableTestAssertions {
    func assertEqual(expected: AnyCodable?, actual: AnyCodable?, keyPath: [Any], file: StaticString, line: UInt, shouldAssert: Bool) -> Bool
    func assertEqual(expected: [AnyCodable]?, actual: [AnyCodable]?, keyPath: [Any], file: StaticString, line: UInt, shouldAssert: Bool) -> Bool
    func assertEqual(expected: [String: AnyCodable]?, actual: [String: AnyCodable]?, keyPath: [Any], file: StaticString, line: UInt, shouldAssert: Bool) -> Bool

    func assertContains(defaultMode: AssertMode, expected: AnyCodable?, actual: AnyCodable?, alternateModePaths: [String], file: StaticString, line: UInt)
    func keyPathAsString(keyPath: [Any]) -> String
}

extension AnyCodableTestAssertions {
    // MARK: - AnyCodable exact equivalence test assertion methods

    /// Performs testing assertions between two `AnyCodable` instances, using a similar logic path as the `AnyCodable ==` implementation.
    /// Traces the key path (both dictionary keys and array indices) and provides the trace on assertion failure, for easier debugging.
    /// Automatically performs any required conversions of underlying `Any?` types into `AnyCodable` format.
    ///
    /// Main entrypoint for `AnyCodable` testing assertions.
    @discardableResult
    func assertEqual(expected: AnyCodable?, actual: AnyCodable?, keyPath: [Any] = [], file: StaticString = #file, line: UInt = #line, shouldAssert: Bool = true) -> Bool {
        if expected?.value == nil, actual?.value == nil {
            return true
        }
        guard let expected = expected, let actual = actual else {
            if shouldAssert {
                XCTFail(#"""
                    \#(expected == nil ? "Expected is nil" : "Actual is nil") and \#(expected == nil ? "Actual" : "Expected") is non-nil.

                    Expected: \#(String(describing: expected))

                    Actual: \#(String(describing: actual))

                    Key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }

        switch (expected.value, actual.value) {
        case let (expected as String, actual as String):
            if shouldAssert {
                XCTAssertEqual(expected, actual, "Key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
            }
            return expected == actual
        case let (expected as Bool, actual as Bool):
            if shouldAssert {
                XCTAssertEqual(expected, actual, "Key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
            }
            return expected == actual
        case let (expected as Int, actual as Int):
            if shouldAssert {
                XCTAssertEqual(expected, actual, "Key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
            }
            return expected == actual
        case let (expected as Double, actual as Double):
            if shouldAssert {
                XCTAssertEqual(expected, actual, "Key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
            }
            return expected == actual
        case let (expected as [String: AnyCodable], actual as [String: AnyCodable]):
            return assertEqual(expected: expected, actual: actual, keyPath: keyPath, file: file, line: line, shouldAssert: shouldAssert)
        case let (expected as [AnyCodable], actual as [AnyCodable]):
            return assertEqual(expected: expected, actual: actual, keyPath: keyPath, file: file, line: line, shouldAssert: shouldAssert)
        case let (expected as [Any?], actual as [Any?]):
            return assertEqual(expected: AnyCodable.from(array: expected), actual: AnyCodable.from(array: actual), keyPath: keyPath, file: file, line: line, shouldAssert: shouldAssert)
        case let (expected as [String: Any?], actual as [String: Any?]):
            return assertEqual(expected: AnyCodable.from(dictionary: expected), actual: AnyCodable.from(dictionary: actual), keyPath: keyPath, file: file, line: line, shouldAssert: shouldAssert)
        default:
            if shouldAssert {
                XCTFail(#"""
                    Expected and Actual types do not match.

                    Expected: \#(expected)

                    Actual: \#(actual)

                    Key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
    }

    /// Performs testing assertions between two `[AnyCodable]` instances.
    @discardableResult
    func assertEqual(expected: [AnyCodable]?, actual: [AnyCodable]?, keyPath: [Any], file: StaticString = #file, line: UInt = #line, shouldAssert: Bool = true) -> Bool {
        if expected == nil, actual == nil {
            return true
        }
        guard let expected = expected, let actual = actual else {
            if shouldAssert {
                XCTFail(#"""
                    \#(expected == nil ? "Expected is nil" : "Actual is nil") and \#(expected == nil ? "Actual" : "Expected") is non-nil.

                    Expected: \#(String(describing: expected))

                    Actual: \#(String(describing: actual))

                    Key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        if expected.count != actual.count {
            if shouldAssert {
                XCTFail(#"""
                    Expected and Actual counts do not match (exact equality).

                    Expected count: \#(expected.count)
                    Actual count: \#(actual.count)

                    Expected: \#(expected)

                    Actual: \#(actual)

                    Key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        var finalResult = true
        for (index, valueTuple) in zip(expected, actual).enumerated() {
            var keyPath = keyPath
            keyPath.append(index)
            finalResult = assertEqual(
                expected: valueTuple.0,
                actual: valueTuple.1,
                keyPath: keyPath,
                file: file, line: line, shouldAssert: shouldAssert) && finalResult
        }
        return finalResult
    }

    /// Performs testing assertions between two `[AnyCodable]` instances.
    @discardableResult
    func assertEqual(expected: [String: AnyCodable]?, actual: [String: AnyCodable]?, keyPath: [Any], file: StaticString = #file, line: UInt = #line, shouldAssert: Bool = true) -> Bool {
        if expected == nil, actual == nil {
            return true
        }
        guard let expected = expected, let actual = actual else {
            if shouldAssert {
                XCTFail(#"""
                    \#(expected == nil ? "Expected is nil" : "Actual is nil") and \#(expected == nil ? "Actual" : "Expected") is non-nil.

                    Expected: \#(String(describing: expected))

                    Actual: \#(String(describing: actual))

                    Key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        if expected.count != actual.count {
            if shouldAssert {
                XCTFail(#"""
                    Expected and Actual counts do not match (exact equality).

                    Expected count: \#(expected.count)
                    Actual count: \#(actual.count)

                    Expected: \#(expected)

                    Actual: \#(actual)

                    Key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        var finalResult = true
        for (key, value) in expected {
            var keyPath = keyPath
            keyPath.append(key)
            finalResult = assertEqual(
                expected: value,
                actual: actual[key],
                keyPath: keyPath,
                file: file, line: line, shouldAssert: shouldAssert) && finalResult
        }
        return finalResult
    }

    // MARK: - AnyCodable flexible validation test assertion methods

    /// Performs a flexible comparison where only the key value pairs on the expected side are required. There are two default equality modes which affect the type of validation performed.
    ///
    /// Given an expected JSON like the following:
    /// {
    /// "key1": "value1",
    /// "key2": [{ "nest1": 1}, {"nest2": 2}]
    /// }
    ///
    /// An example alternate mode path for the example JSON could be: "key2[1].nest2"
    ///
    /// Alternate mode paths must start from the top level of the expected JSON. Whatever key is specified by the path, from that value onward, the alternate match mode is used.
    ///
    /// There are 3 different ways to specify alternate mode paths for arrays:
    /// 1. The specific index: [\<INT\>] (ex: `[0]`, `[28]`, etc.) - The element at the specified index will use the alternate mode
    /// 2. The wildcard index: [*\<INT\>] (ex: `[*1]`, `[*12]`, etc) - The element at the specified index will use the alternate mode and apply wildcard matching logic
    /// 3. The general wildcard: [*] (must be in exactly this format) - Every element not explicitly specified by 1 or 2 will use the alternate mode and apply wildcard matching logic. This option is mututally exclusive with default behavior.
    /// - The default behavior is that elements from the expected JSON side are compared in order, up to the last element of the expected array
    ///
    /// - Parameters:
    ///    - defaultExactEqualityMode: The default mode to use for the validation process. `true` uses exact match, and values require
    ///    the same type and literal value. `false` uses type match, and values require only the same type (and non-nil, given the expected value is not `nil` itself)
    ///    - expected: The expected JSON in AnyCodable format used to perform the assertions
    ///    - actual: The actual JSON in AnyCodable format that is validated against `expected`
    ///    - alternateModePaths: the key paths in the expected JSON that should use the alternate matching mode (that is, the opposite of the one selected via `defaultExactEqualityMode`)
    ///    - file: the file to show test assertion failures in
    ///    - line: the line to show test assertion failures on
    func assertContains(defaultMode: AssertMode = .exactMatch, expected: AnyCodable?, actual: AnyCodable?, alternateModePaths: [String] = [], file: StaticString = #file, line: UInt = #line) {
        let pathTree = generatePathTree(paths: alternateModePaths)
        assertFlexibleEqual(expected: expected, actual: actual, pathTree: pathTree, defaultExactEqualityMode: defaultMode == .exactMatch, file: file, line: line)
    }

    /// Performs testing assertions between two `AnyCodable` instances, using a similar logic path as the `AnyCodable ==` implementation.
    /// Traces the key path (both dictionary keys and array indices) and provides the trace on assertion failure, for easier debugging.
    /// Automatically performs any required conversions of underlying `Any?` types into `AnyCodable` format.
    ///
    /// Use `assertContains` to perform the flexible JSON validation.
    @discardableResult
    private func assertFlexibleEqual(expected: AnyCodable?, actual: AnyCodable?, keyPath: [Any] = [], pathTree: [String: Any]?, defaultExactEqualityMode: Bool, file: StaticString = #file, line: UInt = #line, shouldAssert: Bool = true) -> Bool {
        if expected?.value == nil {
            return true
        }
        guard let expected = expected, let actual = actual else {
            if shouldAssert {
                XCTFail(#"""
                    Expected JSON is non-nil but Actual JSON is nil.

                    Expected: \#(String(describing: expected))

                    Actual: \#(String(describing: actual))

                    Key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }

        switch (expected, actual) {
        case let (expected, actual) where (expected.value is String && actual.value is String):
            fallthrough
        case let (expected, actual) where (expected.value is Bool && actual.value is Bool):
            fallthrough
        case let (expected, actual) where (expected.value is Int && actual.value is Int):
            fallthrough
        case let (expected, actual) where (expected.value is Double && actual.value is Double):
            // Default: exact value matching
            if defaultExactEqualityMode {
                if shouldAssert {
                    XCTAssertEqual(expected, actual, "Key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
                }
                return expected == actual
            }
            // Default: value type validation
            else {
                // Value type matching already passed by virtue of passing the where condition in the switch case
                return true
            }
        case let (expected, actual) where (expected.value is [String: AnyCodable] && actual.value is [String: AnyCodable]):
            return assertFlexibleEqual(
                expected: expected.value as? [String: AnyCodable],
                actual: actual.value as? [String: AnyCodable],
                keyPath: keyPath,
                pathTree: pathTree,
                defaultExactEqualityMode: defaultExactEqualityMode,
                file: file, line: line, shouldAssert: shouldAssert)
        case let (expected, actual) where (expected.value is [AnyCodable] && actual.value is [AnyCodable]):
            return assertFlexibleEqual(
                expected: expected.value as? [AnyCodable],
                actual: actual.value as? [AnyCodable],
                keyPath: keyPath,
                pathTree: pathTree,
                defaultExactEqualityMode: defaultExactEqualityMode,
                file: file, line: line, shouldAssert: shouldAssert)
        case let (expected, actual) where (expected.value is [Any?] && actual.value is [Any?]):
            return assertFlexibleEqual(
                expected: AnyCodable.from(array: expected.value as? [Any?]),
                actual: AnyCodable.from(array: actual.value as? [Any?]),
                keyPath: keyPath,
                pathTree: pathTree,
                defaultExactEqualityMode: defaultExactEqualityMode,
                file: file, line: line, shouldAssert: shouldAssert)
        case let (expected, actual) where (expected.value is [String: Any?] && actual.value is [String: Any?]):
            return assertFlexibleEqual(
                expected: AnyCodable.from(dictionary: expected.value as? [String: Any?]),
                actual: AnyCodable.from(dictionary: actual.value as? [String: Any?]),
                keyPath: keyPath,
                pathTree: pathTree,
                defaultExactEqualityMode: defaultExactEqualityMode,
                file: file, line: line, shouldAssert: shouldAssert)
        default:
            if shouldAssert {
                XCTFail(#"""
                    Expected and Actual types do not match.

                    Expected: \#(expected)

                    Actual: \#(actual)

                    Key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
    }

    /// Performs flexible comparison testing assertions between two `[AnyCodable]` instances.
    private func assertFlexibleEqual(expected: [AnyCodable]?, actual: [AnyCodable]?, keyPath: [Any], pathTree: [String: Any]?, defaultExactEqualityMode: Bool, file: StaticString = #file, line: UInt = #line, shouldAssert: Bool = true) -> Bool {
        if expected == nil {
            return true
        }
        guard let expected = expected, let actual = actual else {
            if shouldAssert {
                XCTFail(#"""
                    Expected JSON is non-nil but Actual JSON is nil.

                    Expected: \#(String(describing: expected))

                    Actual: \#(String(describing: actual))

                    Key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        if expected.count > actual.count {
            if shouldAssert {
                XCTFail(#"""
                    Expected JSON has more elements than Actual JSON. Impossible for Actual to fulfill Expected requirements.

                    Expected count: \#(expected.count)
                    Actual count: \#(actual.count)

                    Expected: \#(expected)

                    Actual: \#(actual)

                    Key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }

        // For explanation on the intended behavior of each alternate mode array path type, see docs for `assertContains`

        // Matches array subscripts and all the inner content (ex: "[*123]". However, only captures the inner content: ex: "123", "*123"
        let arrayIndexValueRegex = #"\[(.*?)\]"#
        let indexValues = pathTree?.keys
            .flatMap { key in
                getCapturedRegexGroups(text: key, regexPattern: arrayIndexValueRegex)
            }
            .compactMap {$0} ?? []
        let hasWildcardAny: Bool = indexValues.contains("*")
        let wildcardIndices: [Int] = indexValues
            .filter { $0.contains("*") }
            .compactMap {
                var string = $0
                string.removeFirst()
                return Int(string)
            }
        let exactIndices: [Int] = indexValues
            .filter { !$0.contains("*") }
            .compactMap { Int($0) }

        var seenIndices: Set<Int> = []
        var finalExactIndices: [Int] = []
        for index in exactIndices {
            if expected.indices.contains(index) {
                let result = seenIndices.insert(index)
                if result.inserted {
                    finalExactIndices.append(index)
                } else {
                    print("WARNING: index already seen: \(index)")
                }
            }
        }

        var finalWildcardIndices: [Int] = []
        for index in wildcardIndices {
            if expected.indices.contains(index) {
                let result = seenIndices.insert(index)
                if result.inserted {
                    finalWildcardIndices.append(index)
                } else {
                    print("WARNING: wildcard index already seen: \(index)")
                }
            }
        }
        var unmatchedLHSIndices: Set<Int> = Set(expected.indices).subtracting(finalExactIndices)
        var unmatchedRHSIndices: Set<Int> = Set(actual.indices).subtracting(finalExactIndices)
        var finalResult = true
        // Alternate match paths with format: [0]
        for index in finalExactIndices.sorted() {
            var keyPath = keyPath
            keyPath.append(index)
            let matchTreeValue = pathTree?["[\(index)]"]
            if matchTreeValue is String {
                finalResult = assertFlexibleEqual(
                    expected: expected[index],
                    actual: actual[index],
                    keyPath: keyPath,
                    pathTree: nil, // Path terminus
                    defaultExactEqualityMode: !defaultExactEqualityMode, // Invert default mode
                    file: file, line: line, shouldAssert: shouldAssert) && finalResult
            } else {
                finalResult = assertFlexibleEqual(
                    expected: expected[index],
                    actual: actual[index],
                    keyPath: keyPath,
                    pathTree: matchTreeValue as? [String: Any],
                    defaultExactEqualityMode: defaultExactEqualityMode,
                    file: file, line: line, shouldAssert: shouldAssert) && finalResult
            }
        }
        // Alternate match paths with format: [*0]
        var unmatchedRHSElements = unmatchedRHSIndices
                                    .sorted(by: { $0 < $1 })
                                    .map { (originalIndex: $0, element: actual[$0]) }
        for index in finalWildcardIndices.sorted() {
            unmatchedLHSIndices.remove(index)
            var keyPath = keyPath
            keyPath.append(index)
            let matchTreeValue = pathTree?["[*\(index)]"]
            if matchTreeValue is String {
                if let result = unmatchedRHSElements.firstIndex(where: {
                    assertFlexibleEqual(
                        expected: expected[index],
                        actual: $0.element,
                        keyPath: keyPath,
                        pathTree: nil, // Path terminus
                        defaultExactEqualityMode: !defaultExactEqualityMode, // Invert default mode
                        file: file, line: line, shouldAssert: false)
                }) {
                    unmatchedRHSIndices.remove(unmatchedRHSElements[result].originalIndex)
                    unmatchedRHSElements.remove(at: result)

                    finalResult = finalResult && true
                } else {
                    XCTFail(#"""
                    Wildcard \#(!defaultExactEqualityMode ? "exact" : "type" ) match found no matches satisfying requirement on Actual side.

                    Requirement: \#(String(describing: matchTreeValue))

                    Expected: \#(expected[index])

                    Actual (remaining unmatched elements): \#(unmatchedRHSElements.map { $0.element })

                    Key path: \#(keyPathAsString(keyPath: keyPath))
                    """#, file: file, line: line)
                    finalResult = false
                }
            } else {
                if let result = unmatchedRHSElements.firstIndex(where: {
                    assertFlexibleEqual(
                        expected: expected[index],
                        actual: $0.element,
                        keyPath: keyPath,
                        pathTree: matchTreeValue as? [String: Any],
                        defaultExactEqualityMode: defaultExactEqualityMode,
                        file: file, line: line, shouldAssert: false)
                }) {

                    unmatchedRHSIndices.remove(unmatchedRHSElements[result].originalIndex)
                    unmatchedRHSElements.remove(at: result)

                    finalResult = finalResult && true
                } else {
                    XCTFail(#"""
                    Wildcard \#(defaultExactEqualityMode ? "exact" : "type" ) match found no matches satisfying requirement on Actual side.

                    Requirement: \#(String(describing: matchTreeValue))

                    Expected: \#(expected[index])

                    Actual (remaining unmatched elements): \#(unmatchedRHSElements.map { $0.element })

                    Key path: \#(keyPathAsString(keyPath: keyPath))
                    """#, file: file, line: line)
                    finalResult = false
                }
            }
        }
        // Alternate match paths with format: [*]
        if hasWildcardAny {
            for index in unmatchedLHSIndices.sorted(by: { $0 < $1 }) {
                unmatchedLHSIndices.remove(index)
                var keyPath = keyPath
                keyPath.append(index)
                let matchTreeValue = pathTree?["[*]"]
                if matchTreeValue is String {
                    if let result = unmatchedRHSElements.firstIndex(where: {
                        assertFlexibleEqual(
                            expected: expected[index],
                            actual: $0.element,
                            keyPath: keyPath,
                            pathTree: nil, // Path terminus
                            defaultExactEqualityMode: !defaultExactEqualityMode, // Invert default mode
                            file: file, line: line, shouldAssert: false)
                    }) {
                        unmatchedRHSIndices.remove(unmatchedRHSElements[result].originalIndex)
                        unmatchedRHSElements.remove(at: result)

                        finalResult = finalResult && true
                    } else {
                        XCTFail(#"""
                        Wildcard \#(!defaultExactEqualityMode ? "exact" : "type" ) match found no matches satisfying requirement on Actual side.

                        Requirement: \#(String(describing: matchTreeValue))

                        Expected: \#(expected[index])

                        Actual (remaining unmatched elements): \#(unmatchedRHSElements.map { $0.element })

                        Key path: \#(keyPathAsString(keyPath: keyPath))
                        """#, file: file, line: line)
                        finalResult = false
                    }
                } else {
                    if let result = unmatchedRHSElements.firstIndex(where: {
                        assertFlexibleEqual(
                            expected: expected[index],
                            actual: $0.element,
                            keyPath: keyPath,
                            pathTree: matchTreeValue as? [String: Any],
                            defaultExactEqualityMode: defaultExactEqualityMode,
                            file: file, line: line, shouldAssert: false)
                    }) {
                        unmatchedRHSIndices.remove(unmatchedRHSElements[result].originalIndex)
                        unmatchedRHSElements.remove(at: result)

                        finalResult = finalResult && true
                    } else {
                        XCTFail(#"""
                        Wildcard \#(defaultExactEqualityMode ? "exact" : "type" ) match found no matches satisfying requirement on Actual side.

                        Requirement: \#(String(describing: matchTreeValue))

                        Expected: \#(expected[index])

                        Actual (remaining unmatched elements): \#(unmatchedRHSElements.map { $0.element })

                        Key path: \#(keyPathAsString(keyPath: keyPath))
                        """#, file: file, line: line)

                        finalResult = false
                    }
                }
            }
        }

        for index in unmatchedLHSIndices.sorted(by: { $0 < $1 }) {
            var keyPath = keyPath
            keyPath.append(index)

            guard unmatchedRHSIndices.contains(index) else {
                XCTFail(#"""
                Actual side's index \#(index) has already been taken by a wildcard match. Verify the test setup for correctness.

                Expected: \#(expected[index])

                Actual (remaining unmatched elements): \#(unmatchedRHSElements.map { $0.element })

                Key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
                finalResult = false
                continue
            }

            finalResult = assertFlexibleEqual(
                expected: expected[index],
                actual: actual[index],
                keyPath: keyPath,
                pathTree: nil, // There should be no array based key paths at this point
                defaultExactEqualityMode: defaultExactEqualityMode,
                file: file, line: line, shouldAssert: shouldAssert) && finalResult
        }

        return finalResult
    }

    /// Performs flexible comparison testing assertions between two `[String: AnyCodable]` instances.
    private func assertFlexibleEqual(expected: [String: AnyCodable]?, actual: [String: AnyCodable]?, keyPath: [Any], pathTree: [String: Any]?, defaultExactEqualityMode: Bool, file: StaticString = #file, line: UInt = #line, shouldAssert: Bool = true) -> Bool {
        if expected == nil {
            return true
        }
        guard let expected = expected, let actual = actual else {
            if shouldAssert {
                XCTFail(#"""
                    Expected JSON is non-nil but Actual JSON is nil.

                    Expected: \#(String(describing: expected))

                    Actual: \#(String(describing: actual))

                    Key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        if expected.count > actual.count {
            if shouldAssert {
                XCTFail(#"""
                    Expected JSON has more elements than Actual JSON.

                    Expected count: \#(expected.count)
                    Actual count: \#(actual.count)

                    Expected: \#(expected)

                    Actual: \#(actual)

                    Key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        var finalResult = true
        for (key, value) in expected {
            var keyPath = keyPath
            keyPath.append(key)
            let pathTreeValue = pathTree?[key]
            if pathTreeValue is String {
                finalResult = assertFlexibleEqual(
                    expected: value,
                    actual: actual[key],
                    keyPath: keyPath,
                    pathTree: nil, // is String means path terminates here
                    defaultExactEqualityMode: !defaultExactEqualityMode, // Invert default mode
                    file: file, line: line, shouldAssert: shouldAssert) && finalResult
            } else {
                finalResult = assertFlexibleEqual(
                    expected: value,
                    actual: actual[key],
                    keyPath: keyPath,
                    pathTree: pathTreeValue as? [String: Any],
                    defaultExactEqualityMode: defaultExactEqualityMode,
                    file: file, line: line, shouldAssert: shouldAssert) && finalResult
            }
        }
        return finalResult
    }

    // MARK: - Test setup and output helpers
    /// Applies the provided regex pattern to the text and returns all the capture groups from the regex pattern
    func getCapturedRegexGroups(text: String, regexPattern: String) -> [String?] {
        do {
            let regex = try NSRegularExpression(pattern: regexPattern)
            let matches = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return matches.map { match in
                return (0..<match.numberOfRanges).map {
                    let rangeBounds = match.range(at: $0)
                    guard let range = Range(rangeBounds, in: text) else {
                        return ""
                    }
                    return String(text[range])
                }
            }.map {
                $0.last
            }
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    /// Merges two constructed key path dictionaries, replacing `current` values with `new` ones, with the exception
    /// of existing values that are String types, which mean that it is a final key path from a different path string
    /// Merge order doesn't matter, the final result should always be the same
    func merge(current: [String: Any], new: [String: Any]) -> [String: Any] {
        var current = current
        for (key, newValue) in new {
            let currentValue = current[key]
            switch (currentValue, newValue) {
            case let (currentValue as [String: Any], newValue as [String: Any]):
                current[key] = merge(current: currentValue, new: newValue)
            default:
                if current[key] is String {
                    continue
                }
                current[key] = newValue
            }
        }
        return current
    }

    /// Constructs a key path dictionary from a given key path component array, and the final value is
    /// assigned the original path string used to construct the path
    func construct(path: [String], pathString: String) -> [String: Any] {
        var path = path
        let first = path.removeFirst()
        let result: [String: Any]
        if path.isEmpty {
            result = [first: pathString]
            return result
        } else {
            return [first: construct(path: path, pathString: pathString)]
        }
    }

    func generatePathTree(paths: [String]) -> [String: Any]? {
        // Matches array subscripts and all the inner content. Captures the surrounding brackets and inner content: ex: "[123]", "[*123]"
        let arrayIndexRegex = #"(\[.*?\])"#
        // Matches key path access in the style of: "key0\.key1.key2[1][2].key3". Captures each of the groups separated by `.` character and ignores `\.` as nesting.
        // the path example would result in: ["key0\.key1", "key2[1][2]", "key3"]
        let jsonNestingRegex = #"(.+?)(?<!\\)(?:\.|$)"#
        var tree: [String: Any] = [:]

        for exactValuePath in paths {
            var allPathComponents: [String] = []
            var pathExtractionSuccessful: Bool = true

            // Break the path string into its component parts
            let splitByNesting = getCapturedRegexGroups(text: exactValuePath, regexPattern: jsonNestingRegex)
            for pathComponent in splitByNesting {
                guard let validComponent = pathComponent else {
                    XCTFail(#"""
                        TEST ERROR: unable to extract valid key path component from path: \#(exactValuePath)
                        Skipping this path in validation process.
                    """#)
                    pathExtractionSuccessful = false
                    break
                }
                let pathComponent = validComponent.replacingOccurrences(of: "\\", with: "")

                // Get all array access levels for the given pathComponent, if any
                // KNOWN LIMITATION: this regex only extracts all open+close square brackets and inner content ("[___]") regardless
                // of their relative position within the path component, ex: "key0[2]key1[3]" will be interpreted as: "key0" with array component "[2][3]"
                let arrayComponents = getCapturedRegexGroups(text: pathComponent, regexPattern: arrayIndexRegex)

                // If array components are detected, extract just the path component before array components if it exists
                if !arrayComponents.isEmpty {
                    guard let bracketIndex = pathComponent.firstIndex(of: "[") else {
                        XCTFail("TEST ERROR: unable to get bracket position from path: \(pathComponent). Skipping exact path: \(exactValuePath)")
                        pathExtractionSuccessful = false
                        break
                    }
                    let extractedPathComponent = String(pathComponent[..<bracketIndex])
                    // It is possible the path itself is an array index; in that case do not insert an empty string
                    if !extractedPathComponent.isEmpty {
                        allPathComponents.append(extractedPathComponent)
                    }
                }
                // Otherwise just add the path
                else {
                    allPathComponents.append(pathComponent)
                }

                for arrayComponent in arrayComponents {
                    guard let arrayComponent = arrayComponent else {
                        XCTFail(#"""
                            TEST ERROR: unable to extract valid array key path component from path: \#(exactValuePath)
                            Skipping this path in validation process.
                        """#)
                        pathExtractionSuccessful = false
                        break
                    }
                    allPathComponents.append(arrayComponent)
                }
            }

            guard pathExtractionSuccessful else {
                XCTFail("TEST ERROR: some exact paths were not able to be extracted. Test will have unexpected results.")
                continue
            }
            let constructedTree = construct(path: allPathComponents, pathString: exactValuePath)
            tree = merge(current: tree, new: constructedTree)

        }
        return tree.isEmpty ? nil : tree
    }

    /// Convenience function that outputs a given key path as a pretty string
    func keyPathAsString(keyPath: [Any]) -> String {
        var result = ""
        for item in keyPath {
            switch item {
            case let item as String:
                if !result.isEmpty {
                    result += "."
                }
                if item.contains(".") {
                    result += item.replacingOccurrences(of: ".", with: "\\.")
                } else {
                    result += item
                }
            case let item as Int:
                result += "[" + String(item) + "]"
            default:
                break
            }
        }
        return result
    }
}

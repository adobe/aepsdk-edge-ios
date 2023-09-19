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

import AEPCore
import AEPServices
import Foundation
import XCTest

extension XCTestCase {
    // MARK: - AnyCodable helpers

    /// Gets the `AnyCodable` representation of a JSON string
    func getAnyCodable(_ jsonString: String) -> AnyCodable? {
        return try? JSONDecoder().decode(AnyCodable.self, from: jsonString.data(using: .utf8)!)
    }

    /// Gets an event's data payload converted into `AnyCodable` format
    func getAnyCodable(_ event: Event) -> AnyCodable? {
        return AnyCodable(AnyCodable.from(dictionary: event.data))
    }

    // MARK: - AnyCodable exact equivalence test assertion methods

    /// Asserts exact equality between two `AnyCodable` instances.
    ///
    /// In the event of an assertion failure, this function provides a trace of the key path, which includes dictionary keys and array indexes,
    /// to aid debugging.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodable` to compare.
    ///   - actual: The actual `AnyCodable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertEqual(expected: AnyCodable?, actual: AnyCodable?, file: StaticString = #file, line: UInt = #line) {
        assertEqual(expected: expected, actual: actual, keyPath: [], file: file, line: line)
    }

    // MARK: - AnyCodable flexible validation test assertion methods
    /// Performs a flexible JSON comparison where only the key-value pairs from the expected JSON are required.
    /// By default, the function validates that both values are of the same type.
    ///
    /// Alternate mode paths enable switching from the default type matching mode to exact value matching
    /// mode for specified paths onward.
    ///
    /// For example, given an expected JSON like:
    /// ```
    /// {
    ///   "key1": "value1",
    ///   "key2": [{ "nest1": 1}, {"nest2": 2}],
    ///   "key3": { "key4": 1 },
    ///   "key.name": 1,
    ///   "key[123]": 1
    /// }
    /// ```
    /// An example `exactMatchPaths` path for this JSON would be: `"key2[1].nest2"`.
    ///
    /// Alternate mode paths must begin from the top level of the expected JSON.
    /// Multiple paths can be defined. If two paths collide, the shorter one takes priority.
    ///
    /// Formats for keys:
    /// - Nested keys: Use dot notation, e.g., "key3.key4".
    /// - Keys with dots: Escape the dot, e.g., "key\.name".
    ///
    /// Formats for arrays:
    /// - Index specification: `[<INT>]` (e.g., `[0]`, `[28]`).
    /// - Keys with array brackets: Escape the brackets, e.g., `key\[123\]`.
    ///
    /// For wildcard array matching, where position doesn't matter:
    /// 1. Specific index with wildcard: `[*<INT>]` or `[<INT>*]` (ex: `[*1]`, `[28*]`). The element
    /// at the given index in `expected` will use wildcard matching in `actual`.
    /// 2. Universal wildcard: `[*]`. All elements in `expected` will use wildcard matching in `actual`.
    ///
    /// In array comparisons, elements are compared in order, up to the last element of the expected array.
    /// When combining wildcard and standard indexes, regular indexes are validated first.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodable` to compare.
    ///   - actual: The actual `AnyCodable` to compare.
    ///   - exactMatchPaths: The key paths in the expected JSON that should use exact matching mode, where values require both the same type and literal value.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertTypeMatch(expected: AnyCodable, actual: AnyCodable?, exactMatchPaths: [String] = [], file: StaticString = #file, line: UInt = #line) {
        let pathTree = generatePathTree(paths: exactMatchPaths, file: file, line: line)
        assertFlexibleEqual(expected: expected, actual: actual, pathTree: pathTree, exactMatchMode: false, file: file, line: line)
    }

    /// Performs a flexible JSON comparison where only the key-value pairs from the expected JSON are required.
    /// By default, the function uses exact match mode, validating that both values are of the same type
    /// and have the same literal value.
    ///
    /// Alternate mode paths enable switching from the default exact matching mode to type matching
    /// mode for specified paths onward.
    ///
    /// For example, given an expected JSON like:
    /// ```
    /// {
    ///   "key1": "value1",
    ///   "key2": [{ "nest1": 1}, {"nest2": 2}],
    ///   "key3": { "key4": 1 },
    ///   "key.name": 1,
    ///   "key[123]": 1
    /// }
    /// ```
    /// An example `typeMatchPaths` path for this JSON would be: `"key2[1].nest2"`.
    ///
    /// Alternate mode paths must begin from the top level of the expected JSON.
    /// Multiple paths can be defined. If two paths collide, the shorter one takes priority.
    ///
    /// Formats for keys:
    /// - Nested keys: Use dot notation, e.g., "key3.key4".
    /// - Keys with dots: Escape the dot, e.g., "key\.name".
    ///
    /// Formats for arrays:
    /// - Index specification: `[<INT>]` (e.g., `[0]`, `[28]`).
    /// - Keys with array brackets: Escape the brackets, e.g., `key\[123\]`.
    ///
    /// For wildcard array matching, where position doesn't matter:
    /// 1. Specific index with wildcard: `[*<INT>]` or `[<INT>*]` (ex: `[*1]`, `[28*]`). The element
    /// at the given index in `expected` will use wildcard matching in `actual`.
    /// 2. Universal wildcard: `[*]`. All elements in `expected` will use wildcard matching in `actual`.
    ///
    /// In array comparisons, elements are compared in order, up to the last element of the expected array.
    /// When combining wildcard and standard indexes, regular indexes are validated first.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodable` to compare.
    ///   - actual: The actual `AnyCodable` to compare.
    ///   - typeMatchPaths: The key paths in the expected JSON that should use type matching mode, where values require only the same type (and are non-nil if the expected value is not nil).
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertExactMatch(expected: AnyCodable, actual: AnyCodable?, typeMatchPaths: [String] = [], file: StaticString = #file, line: UInt = #line) {
        let pathTree = generatePathTree(paths: typeMatchPaths, file: file, line: line)
        assertFlexibleEqual(expected: expected, actual: actual, pathTree: pathTree, exactMatchMode: true, file: file, line: line)
    }

    // MARK: - AnyCodable exact equivalence helpers
    /// Compares the given `expected` and `actual` values for exact equality. If they are not equal and an assertion fails,
    /// a test failure occurs.
    ///
    /// - Parameters:
    ///   - expected: The expected value to compare.
    ///   - actual: The actual value to compare.
    ///   - keyPath: A list of keys indicating the path to the current value being compared. Defaults to an empty list.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    private func assertEqual(expected: AnyCodable?, actual: AnyCodable?, keyPath: [Any] = [], file: StaticString = #file, line: UInt = #line) {
        if expected?.value == nil, actual?.value == nil {
            return
        }
        guard let expected = expected, let actual = actual else {
            XCTFail(#"""
                \#(expected == nil ? "Expected is nil" : "Actual is nil") and \#(expected == nil ? "Actual" : "Expected") is non-nil.

                Expected: \#(String(describing: expected))

                Actual: \#(String(describing: actual))

                Key path: \#(keyPathAsString(keyPath))
            """#, file: file, line: line)
            return
        }

        switch (expected.value, actual.value) {
        case let (expected as String, actual as String):
            XCTAssertEqual(expected, actual, "Key path: \(keyPathAsString(keyPath))", file: file, line: line)
        case let (expected as Bool, actual as Bool):
            XCTAssertEqual(expected, actual, "Key path: \(keyPathAsString(keyPath))", file: file, line: line)
        case let (expected as Int, actual as Int):
            XCTAssertEqual(expected, actual, "Key path: \(keyPathAsString(keyPath))", file: file, line: line)
        case let (expected as Double, actual as Double):
            XCTAssertEqual(expected, actual, "Key path: \(keyPathAsString(keyPath))", file: file, line: line)
        case let (expected as [String: AnyCodable], actual as [String: AnyCodable]):
            assertEqual(expected: expected, actual: actual, keyPath: keyPath, file: file, line: line)
        case let (expected as [AnyCodable], actual as [AnyCodable]):
            assertEqual(expected: expected, actual: actual, keyPath: keyPath, file: file, line: line)
        case let (expected as [Any?], actual as [Any?]):
            assertEqual(expected: AnyCodable.from(array: expected), actual: AnyCodable.from(array: actual), keyPath: keyPath, file: file, line: line)
        case let (expected as [String: Any?], actual as [String: Any?]):
            assertEqual(expected: AnyCodable.from(dictionary: expected), actual: AnyCodable.from(dictionary: actual), keyPath: keyPath, file: file, line: line)
        default:
            XCTFail(#"""
                Expected and Actual types do not match.

                Expected: \#(expected)

                Actual: \#(actual)

                Key path: \#(keyPathAsString(keyPath))
            """#, file: file, line: line)
        }
    }

    /// Compares two `AnyCodable` arrays for exact equality. If they are not equal, a test failure occurs.
    ///
    /// - Parameters:
    ///   - expected: The expected array of `AnyCodable` to compare.
    ///   - actual: The actual array of `AnyCodable` to compare.
    ///   - keyPath: A list of keys or array indexes representing the path to the current value being compared.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    private func assertEqual(expected: [AnyCodable]?, actual: [AnyCodable]?, keyPath: [Any], file: StaticString = #file, line: UInt = #line) {
        if expected == nil, actual == nil {
            return
        }
        guard let expected = expected, let actual = actual else {
            XCTFail(#"""
                \#(expected == nil ? "Expected is nil" : "Actual is nil") and \#(expected == nil ? "Actual" : "Expected") is non-nil.

                Expected: \#(String(describing: expected))

                Actual: \#(String(describing: actual))

                Key path: \#(keyPathAsString(keyPath))
            """#, file: file, line: line)
            return
        }
        if expected.count != actual.count {
            XCTFail(#"""
                Expected and Actual counts do not match (exact equality).

                Expected count: \#(expected.count)
                Actual count: \#(actual.count)

                Expected: \#(expected)

                Actual: \#(actual)

                Key path: \#(keyPathAsString(keyPath))
            """#, file: file, line: line)
            return
        }
        for (index, valueTuple) in zip(expected, actual).enumerated() {
            assertEqual(
                expected: valueTuple.0,
                actual: valueTuple.1,
                keyPath: keyPath + [index],
                file: file, line: line)
        }
    }

    /// Compares two dictionaries (`[String: AnyCodable]`) for exact equality. If they are not equal, a test failure occurs.
    ///
    /// - Parameters:
    ///   - expected: The expected dictionary of `AnyCodable` to compare.
    ///   - actual: The actual dictionary of `AnyCodable` to compare.
    ///   - keyPath: A list of keys or array indexes representing the path to the current value being compared.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    private func assertEqual(expected: [String: AnyCodable]?, actual: [String: AnyCodable]?, keyPath: [Any], file: StaticString = #file, line: UInt = #line) {
        if expected == nil, actual == nil {
            return
        }
        guard let expected = expected, let actual = actual else {
            XCTFail(#"""
                \#(expected == nil ? "Expected is nil" : "Actual is nil") and \#(expected == nil ? "Actual" : "Expected") is non-nil.

                Expected: \#(String(describing: expected))

                Actual: \#(String(describing: actual))

                Key path: \#(keyPathAsString(keyPath))
            """#, file: file, line: line)
            return
        }
        if expected.count != actual.count {
            XCTFail(#"""
                Expected and Actual counts do not match (exact equality).

                Expected count: \#(expected.count)
                Actual count: \#(actual.count)

                Expected: \#(expected)

                Actual: \#(actual)

                Key path: \#(keyPathAsString(keyPath))
            """#, file: file, line: line)
            return
        }
        for (key, value) in expected {
            assertEqual(
                expected: value,
                actual: actual[key],
                keyPath: keyPath + [key],
                file: file, line: line)
        }
    }

    // MARK: - AnyCodable flexible validation helpers
    /// Performs a flexible comparison between the given `expected` and `actual` values, optionally using exact match
    /// or value type match modes. In case of a mismatch and if `shouldAssert` is `true`, a test failure occurs.
    ///
    /// It allows for customized matching behavior through the `pathTree` and `exactMatchMode` parameters.
    ///
    /// - Parameters:
    ///   - expected: The expected value to compare.
    ///   - actual: The actual value to compare.
    ///   - keyPath: A list of keys or array indexes representing the path to the current value being compared. Defaults to an empty list.
    ///   - pathTree: A map representing specific paths within the JSON structure that should be compared using the alternate mode.
    ///   - exactMatchMode: If `true`, performs an exact match comparison; otherwise, uses value type matching.
    ///   - shouldAssert: Indicates if an assertion error should be thrown if `expected` and `actual` are not equal. Defaults to `true`.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    ///
    /// - Returns: `true` if `expected` and `actual` are equal based on the matching mode and the `pathTree`, otherwise returns `false`.
    @discardableResult
    private func assertFlexibleEqual(
        expected: AnyCodable?,
        actual: AnyCodable?,
        keyPath: [Any] = [],
        pathTree: [String: Any]?,
        exactMatchMode: Bool,
        shouldAssert: Bool = true,
        file: StaticString = #file,
        line: UInt = #line) -> Bool {
            if expected?.value == nil {
                return true
            }
            guard let expected = expected, let actual = actual else {
                if shouldAssert {
                    XCTFail(#"""
                    Expected JSON is non-nil but Actual JSON is nil.

                    Expected: \#(String(describing: expected))

                    Actual: \#(String(describing: actual))

                    Key path: \#(keyPathAsString(keyPath))
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
                if exactMatchMode {
                    if shouldAssert {
                        XCTAssertEqual(expected, actual, "Key path: \(keyPathAsString(keyPath))", file: file, line: line)
                    }
                    return expected == actual
                } else {
                    // Value type matching already passed by virtue of passing the where condition in the switch case
                    return true
                }
            case let (expected, actual) where (expected.value is [String: AnyCodable] && actual.value is [String: AnyCodable]):
                return assertFlexibleEqual(
                    expected: expected.value as? [String: AnyCodable],
                    actual: actual.value as? [String: AnyCodable],
                    keyPath: keyPath,
                    pathTree: pathTree,
                    exactMatchMode: exactMatchMode,
                    shouldAssert: shouldAssert,
                    file: file,
                    line: line)
            case let (expected, actual) where (expected.value is [AnyCodable] && actual.value is [AnyCodable]):
                return assertFlexibleEqual(
                    expected: expected.value as? [AnyCodable],
                    actual: actual.value as? [AnyCodable],
                    keyPath: keyPath,
                    pathTree: pathTree,
                    exactMatchMode: exactMatchMode,
                    shouldAssert: shouldAssert,
                    file: file,
                    line: line)
            case let (expected, actual) where (expected.value is [Any?] && actual.value is [Any?]):
                return assertFlexibleEqual(
                    expected: AnyCodable.from(array: expected.value as? [Any?]),
                    actual: AnyCodable.from(array: actual.value as? [Any?]),
                    keyPath: keyPath,
                    pathTree: pathTree,
                    exactMatchMode: exactMatchMode,
                    shouldAssert: shouldAssert,
                    file: file,
                    line: line)
            case let (expected, actual) where (expected.value is [String: Any?] && actual.value is [String: Any?]):
                return assertFlexibleEqual(
                    expected: AnyCodable.from(dictionary: expected.value as? [String: Any?]),
                    actual: AnyCodable.from(dictionary: actual.value as? [String: Any?]),
                    keyPath: keyPath,
                    pathTree: pathTree,
                    exactMatchMode: exactMatchMode,
                    shouldAssert: shouldAssert,
                    file: file,
                    line: line)
            default:
                if shouldAssert {
                    XCTFail(#"""
                    Expected and Actual types do not match.

                    Expected: \#(expected)

                    Actual: \#(actual)

                    Key path: \#(keyPathAsString(keyPath))
                """#, file: file, line: line)
                }
                return false
            }
        }

    /// Performs a flexible comparison between the given `expected` and `actual` arrays of `AnyCodable`, optionally using exact match
    /// or value type match modes. In case of a mismatch and if `shouldAssert` is `true`, a test failure occurs.
    ///
    /// It allows for customized matching behavior through the `pathTree` and `exactMatchMode` parameters.
    ///
    /// - Parameters:
    ///   - expected: The expected array of `AnyCodable` to compare.
    ///   - actual: The actual array of `AnyCodable` to compare.
    ///   - keyPath: A list of keys or array indexes representing the path to the current value being compared.
    ///   - pathTree: A map representing specific paths within the JSON structure that should be compared using the alternate mode.
    ///   - exactMatchMode: If `true`, performs an exact match comparison; otherwise, uses value type matching.
    ///   - shouldAssert: Indicates if an assertion error should be thrown if `expected` and `actual` are not equal.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    ///
    /// - Returns: `true` if `expected` and `actual` are equal based on the matching mode and the `pathTree`, otherwise returns `false`.
    private func assertFlexibleEqual(
        expected: [AnyCodable]?,
        actual: [AnyCodable]?,
        keyPath: [Any],
        pathTree: [String: Any]?,
        exactMatchMode: Bool,
        shouldAssert: Bool = true,
        file: StaticString = #file,
        line: UInt = #line) -> Bool {
            if expected == nil {
                return true
            }
            guard let expected = expected, let actual = actual else {
                if shouldAssert {
                    XCTFail(#"""
                    Expected JSON is non-nil but Actual JSON is nil.

                    Expected: \#(String(describing: expected))

                    Actual: \#(String(describing: actual))

                    Key path: \#(keyPathAsString(keyPath))
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

                    Key path: \#(keyPathAsString(keyPath))
                """#, file: file, line: line)
                }
                return false
            }
            var actualIndexes = Set(0..<actual.count)
            var expectedIndexes = Set(0..<expected.count)
            var wildcardIndexes: Set<Int>

            // Collect all the keys from `pathTree` that either:
            // 1. Mark the path end (where the value is a `String`), or
            // 2. Contain the asterisk (*) character.
            let pathEndKeys = pathTree?.filter { key, value in
                value is String || key.contains("*")
            }.keys.map({$0}) ?? []

            // If general wildcard is present, it supersedes other paths
            if pathEndKeys.contains("[*]") {
                wildcardIndexes = Set(0..<expected.count)
                expectedIndexes.removeAll()
            } else {
                // TODO: update this to be flat? since there's only 1 operation now instead of 3
                // Strongly validates index notation: "[123]"
                let arrayIndexValueRegex = #"^\[(.*?)\]$"#
                let indexValues = Set(pathEndKeys
                    .flatMap { getCapturedRegexGroups(text: $0, regexPattern: arrayIndexValueRegex) })

                func filterConvertAndIntersect(condition: (String) -> Bool, replacement: @escaping (String) -> String = { $0 }) -> Set<Int> {
                    var result = Set(indexValues.filter(condition).compactMap { Int(replacement($0)) })
                    let intersection = expectedIndexes.intersection(result)
                    result = intersection
                    expectedIndexes.subtract(intersection)
                    return result
                }

                wildcardIndexes = filterConvertAndIntersect(condition: { $0.contains("*") }, replacement: { $0.replacingOccurrences(of: "*", with: "") })
            }

            var finalResult = true

            for index in expectedIndexes {
                let pathTreeValue = pathTree?["[\(index)]"]
                let isPathEnd = pathTreeValue is String

                finalResult = assertFlexibleEqual(
                    expected: expected[index],
                    actual: actual[index],
                    keyPath: keyPath + [index],
                    pathTree: pathTreeValue as? [String: Any],
                    exactMatchMode: isPathEnd != exactMatchMode,
                    shouldAssert: shouldAssert,
                    file: file, line: line) && finalResult
                actualIndexes.remove(index)
            }

            for index in wildcardIndexes {
                let pathTreeValue = pathTree?["[*]"]
                ?? pathTree?["[*\(index)]"]
                ?? pathTree?["[\(index)*]"]

                let isPathEnd = pathTreeValue is String

                guard let actualIndex = actualIndexes.first(where: {
                    assertFlexibleEqual(
                        expected: expected[index],
                        actual: actual[$0],
                        keyPath: keyPath + [index],
                        pathTree: pathTreeValue as? [String: Any],
                        exactMatchMode: isPathEnd != exactMatchMode,
                        shouldAssert: false)
                }) else {
                    if shouldAssert {
                        XCTFail(#"""
                        Wildcard \#((isPathEnd ? !exactMatchMode : exactMatchMode) ? "exact" : "type") match found no matches on Actual side satisfying the Expected requirement.

                        Requirement: \#(String(describing: pathTreeValue))

                        Expected: \#(expected[index])

                        Actual (remaining unmatched elements): \#(actualIndexes.map({ actual[$0] }))

                        Key path: \#(keyPathAsString(keyPath))
                        """#, file: file, line: line)
                    }
                    finalResult = false
                    break
                }
                actualIndexes.remove(actualIndex)
            }
            return finalResult
        }

    /// Performs a flexible comparison between the given `expected` and `actual` dictionaries, optionally using exact match
    /// or value type match modes. In case of a mismatch and if `shouldAssert` is `true`, a test failure occurs.
    ///
    /// It allows for customized matching behavior through the `pathTree` and `exactMatchMode` parameters.
    ///
    /// - Parameters:
    ///   - expected: The expected dictionary of `AnyCodable` to compare.
    ///   - actual: The actual dictionary of `AnyCodable` to compare.
    ///   - keyPath: A list of keys or array indexes representing the path to the current value being compared.
    ///   - pathTree: A map representing specific paths within the JSON structure that should be compared using the alternate mode.
    ///   - exactMatchMode: If `true`, performs an exact match comparison; otherwise, uses value type matching.
    ///   - shouldAssert: Indicates if an assertion error should be thrown if `expected` and `actual` are not equal.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    ///
    /// - Returns: `true` if `expected` and `actual` are equal based on the matching mode and the `pathTree`, otherwise returns `false`.
    private func assertFlexibleEqual(
        expected: [String: AnyCodable]?,
        actual: [String: AnyCodable]?,
        keyPath: [Any],
        pathTree: [String: Any]?,
        exactMatchMode: Bool,
        shouldAssert: Bool = true,
        file: StaticString = #file,
        line: UInt = #line) -> Bool {
            if expected == nil {
                return true
            }
            guard let expected = expected, let actual = actual else {
                if shouldAssert {
                    XCTFail(#"""
                    Expected JSON is non-nil but Actual JSON is nil.

                    Expected: \#(String(describing: expected))

                    Actual: \#(String(describing: actual))

                    Key path: \#(keyPathAsString(keyPath))
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

                    Key path: \#(keyPathAsString(keyPath))
                """#, file: file, line: line)
                }
                return false
            }
            var finalResult = true
            for (key, value) in expected {
                let pathTreeValue = pathTree?[key]
                let isPathEnd = pathTreeValue is String

                finalResult = assertFlexibleEqual(
                    expected: value,
                    actual: actual[key],
                    keyPath: keyPath + [key],
                    pathTree: pathTreeValue as? [String: Any],
                    exactMatchMode: isPathEnd != exactMatchMode,
                    shouldAssert: shouldAssert,
                    file: file,
                    line: line)
                && finalResult
            }
            return finalResult
        }

    // MARK: - Test setup and output helpers
    /// Performs regex match on the provided String, returning the original match and non-nil capture group results
    private func extractRegexCaptureGroups(text: String, regexPattern: String, file: StaticString = #file, line: UInt = #line) -> [(matchString: String, captureGroups: [String])]? {
        do {
            let regex = try NSRegularExpression(pattern: regexPattern)
            let matches = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            var matchResult: [(matchString: String, captureGroups: [String])] = []
            for match in matches {
                var rangeStrings: [String] = []
                // [(matched string), (capture group 0), (capture group 1), etc.]
                for rangeIndex in 0 ..< match.numberOfRanges {
                    let rangeBounds = match.range(at: rangeIndex)
                    guard let range = Range(rangeBounds, in: text) else {
                        continue
                    }
                    rangeStrings.append(String(text[range]))
                }
                guard !rangeStrings.isEmpty else {
                    continue
                }
                let matchString = rangeStrings.removeFirst()
                matchResult.append((matchString: matchString, captureGroups: rangeStrings))
            }
            return matchResult
        } catch let error {
            XCTFail("TEST ERROR: Invalid regex: \(error.localizedDescription)", file: file, line: line)
            return nil
        }
    }

    /// Applies the provided regex pattern to the text and returns all the capture groups from the regex pattern
    private func getCapturedRegexGroups(text: String, regexPattern: String, file: StaticString = #file, line: UInt = #line) -> [String] {

        guard let captureGroups = extractRegexCaptureGroups(text: text, regexPattern: regexPattern, file: file, line: line)?.flatMap({ $0.captureGroups }) else {
            return []
        }

        return captureGroups
    }

    /// Extracts all key path components from a given key path string
    func getKeyPathComponents(text: String) -> [String] {
        // Handle edge case where input is empty
        if text.isEmpty { return [""] }

        var segments: [String] = []
        var startIndex = text.startIndex
        var inEscapeSequence = false

        // Iterate over each character in the input string with its index
        for (index, char) in text.enumerated() {
            let currentIndex = text.index(text.startIndex, offsetBy: index)

            // If current character is a backslash and we're not already in an escape sequence
            if char == "\\" {
                inEscapeSequence = true
            }
            // If current character is a dot and we're not in an escape sequence
            else if char == "." && !inEscapeSequence {
                // Add the segment from the start index to current index (excluding the dot)
                segments.append(String(text[startIndex..<currentIndex]))

                // Update the start index for the next segment
                startIndex = text.index(after: currentIndex)
            }
            // Any other character or if we're ending an escape sequence
            else {
                inEscapeSequence = false
            }
        }

        // Add the remaining segment after the last dot (if any)
        segments.append(String(text[startIndex...]))

        // Handle edge case where input ends with a dot (but not an escaped dot)
        if text.hasSuffix(".") && !text.hasSuffix("\\.") && segments.last != "" {
            segments.append("")
        }

        return segments
    }

    /// Merges two constructed key path dictionaries, replacing `current` values with `new` ones, with the exception
    /// of existing values that are String types, which mean that it is a final key path from a different path string
    /// Merge order doesn't matter, the final result should always be the same
    private func merge(current: [String: Any], new: [String: Any]) -> [String: Any] {
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
    private func construct(path: [String], pathString: String) -> [String: Any] {
        guard !path.isEmpty else {
            return [:]
        }
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

    func extractArrayStyleComponents(str: String) -> [String] {
        // Handle edge case where input is empty
        if str.isEmpty { return [""] }

        var components: [String] = []
        var bracketCount = 0
        var componentBuilder = ""
        var nextCharIsBackslash = false
        var lastArrayAccessEnd = str.endIndex // to track the end of the last valid array-style access

        func isNextCharBackslash(i: String.Index) -> Bool {
            if i == str.startIndex {
                // There is no character before the startIndex.
                return false
            }

            // Since we're iterating in reverse, the "next" character is before i
            let previousIndex = str.index(before: i)
            return str[previousIndex] == "\\"
        }

    outerLoop: for i in str.indices.reversed() {
        switch str[i] {
        case "]" where !isNextCharBackslash(i: i):
            bracketCount += 1
            componentBuilder.append("]")
        case "[" where !isNextCharBackslash(i: i):
            bracketCount -= 1
            componentBuilder.append("[")
            if bracketCount == 0 {
                components.insert(String(componentBuilder.reversed()), at: 0)
                componentBuilder = ""
                lastArrayAccessEnd = i
            }
        case "\\":
            if nextCharIsBackslash {
                nextCharIsBackslash = false
                continue outerLoop
            } else {
                componentBuilder.append("\\")
            }
        default:
            if bracketCount == 0 && i < lastArrayAccessEnd {
                components.insert(String(str[str.startIndex...i]), at: 0)
                break outerLoop
            }
            componentBuilder.append(str[i])
        }
    }

        // Add any remaining component that's not yet added
        if !componentBuilder.isEmpty {
            components.insert(String(componentBuilder.reversed()), at: 0)
        }
        if !components.isEmpty {
            components[0] = components[0].replacingOccurrences(of: "\\[", with: "[").replacingOccurrences(of: "\\]", with: "]")
        }
        return components
    }

    private func generatePathTree(paths: [String], file: StaticString = #file, line: UInt = #line) -> [String: Any]? {
        var tree: [String: Any] = [:]

        for path in paths {
            var allPathComponents: [String] = []

            // Break the path string into its component parts
            let keyPathComponents = getKeyPathComponents(text: path)
            for pathComponent in keyPathComponents {
                let pathComponent = pathComponent.replacingOccurrences(of: "\\.", with: ".")

                let components = extractArrayStyleComponents(str: pathComponent)
                allPathComponents.append(contentsOf: components)
            }

            let constructedTree = construct(path: allPathComponents, pathString: path)
            tree = merge(current: tree, new: constructedTree)

        }
        return tree.isEmpty ? nil : tree
    }

    /// Convenience function that outputs a given key path as a pretty string
    private func keyPathAsString(_ keyPath: [Any]) -> String {
        var result = ""
        for item in keyPath {
            switch item {
            case let item as String:
                if !result.isEmpty {
                    result += "."
                }
                if item.contains(".") {
                    result += item.replacingOccurrences(of: ".", with: "\\.")
                } else if item.isEmpty {
                    result += "\"\""
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

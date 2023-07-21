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

enum AssertMode {
    case exactMatch
    case typeMatch
}

enum PayloadType: String {
    case xdm
    case data
}

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
    
    func getAnyCodableAndPayload(_ jsonString: String, type: PayloadType) -> (anyCodable: AnyCodable, payload: [String: Any])? {
        guard let anyCodable = getAnyCodable(jsonString) else {
            return nil
        }
        guard let payload = anyCodable.dictionaryValue?[type.rawValue] as? [String: Any] else {
            return nil
        }
        return (anyCodable: anyCodable, payload: payload)
    }
    
    func getAnyCodableFromEventPayload(event: Event) -> AnyCodable? {
        return AnyCodable(AnyCodable.from(dictionary: event.data))
    }
    
    // MARK: - AnyCodable exact equivalence test assertion methods

    /// Performs exact equality testing assertions between two `AnyCodable` instances, using a similar logic path as the `AnyCodable ==` implementation.
    /// Traces the key path (both dictionary keys and array indices) and provides the trace on assertion failure, for easier debugging.
    /// Automatically performs any required conversions of underlying `Any?` types into `AnyCodable` format.
    ///
    /// Main entrypoint for exact equality `AnyCodable` testing assertions.
    func assertEqual(expected: AnyCodable?, actual: AnyCodable?, file: StaticString = #file, line: UInt = #line) {
        assertEqual(expected: expected, actual: actual, keyPath: [], file: file, line: line)
    }

    // MARK: - AnyCodable flexible validation test assertion methods
    /// Performs a flexible comparison where only the key value pairs on the expected side are required. Uses type match as the default validation mode, where values require
    /// only the same type (and non-nil, given the expected value is not `nil` itself).
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
    /// 1. The specific index: [\<INT\>] (ex: `[0]`, `[28]`, etc.) - The element at the specified index will use the alternate mode.
    /// 2. The wildcard index: [*\<INT\>] (ex: `[*1]`, `[*12]`, etc) - The element at the specified index will use the alternate mode and apply wildcard matching logic.
    /// 3. The general wildcard: [*] (must be in exactly this format) - Every element not explicitly specified by 1 or 2 will use the alternate mode and apply wildcard matching logic. This option is mututally exclusive with default behavior.
    /// - The default behavior is that elements from the expected JSON side are compared in order, up to the last element of the expected array.
    ///
    /// - Parameters:
    ///    - expected: The expected JSON in AnyCodable format used to perform the assertions
    ///    - actual: The actual JSON in AnyCodable format that is validated against `expected`
    ///    - exactMatchPaths: the key paths in the expected JSON that should use exact matching mode, where values require the same type and literal value.
    ///    - file: the file to show test assertion failures in
    ///    - line: the line to show test assertion failures on
    func assertTypeMatch(expected: AnyCodable, actual: AnyCodable?, exactMatchPaths: [String] = [], file: StaticString = #file, line: UInt = #line) {
        let pathTree = generatePathTree(paths: exactMatchPaths, file: file, line: line)
        assertFlexibleEqual(expected: expected, actual: actual, pathTree: pathTree, exactMatchMode: false, file: file, line: line)
    }

    /// Performs a flexible comparison where only the key value pairs on the expected side are required. Uses exact match as the default validation mode, where values
    /// require the same type and literal value.
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
    /// 1. The specific index: [\<INT\>] (ex: `[0]`, `[28]`, etc.) - The element at the specified index will use the alternate mode.
    /// 2. The wildcard index: [*\<INT\>] (ex: `[*1]`, `[*12]`, etc) - The element at the specified index will use the alternate mode and apply wildcard matching logic.
    /// 3. The general wildcard: [*] (must be in exactly this format) - Every element not explicitly specified by 1 or 2 will use the alternate mode and apply wildcard matching logic. This option is mututally exclusive with default behavior.
    /// - The default behavior is that elements from the expected JSON side are compared in order, up to the last element of the expected array.
    ///
    /// - Parameters:
    ///    - expected: The expected JSON in AnyCodable format used to perform the assertions
    ///    - actual: The actual JSON in AnyCodable format that is validated against `expected`
    ///    - typeMatchPaths: Optionally, the key paths in the expected JSON that should use type matching mode, where values require only the same type (and non-nil, given the expected value is not `nil` itself)
    ///    - file: the file to show test assertion failures in
    ///    - line: the line to show test assertion failures on
    func assertExactMatch(expected: AnyCodable, actual: AnyCodable?, typeMatchPaths: [String] = [], file: StaticString = #file, line: UInt = #line) {
        let pathTree = generatePathTree(paths: typeMatchPaths, file: file, line: line)
        assertFlexibleEqual(expected: expected, actual: actual, pathTree: pathTree, exactMatchMode: true, file: file, line: line)
    }
    
    // MARK: - AnyCodable exact equivalence helpers
    /// Performs equality testing assertions between two `AnyCodable` instances.
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

    /// Performs equality testing assertions between two `[AnyCodable]` instances.
    private func assertEqual(expected: [AnyCodable]?, actual: [AnyCodable]?, keyPath: [Any], file: StaticString = #file, line: UInt = #line, shouldAssert: Bool = true) {
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
            var keyPath = keyPath
            keyPath.append(index)
            assertEqual(
                expected: valueTuple.0,
                actual: valueTuple.1,
                keyPath: keyPath,
                file: file, line: line)
        }
    }

    /// Performs equality testing assertions between two `[String: AnyCodable]` instances.
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
            var keyPath = keyPath
            keyPath.append(key)
            assertEqual(
                expected: value,
                actual: actual[key],
                keyPath: keyPath,
                file: file, line: line)
        }
    }

    // MARK: - AnyCodable flexible validation helpers
    /// Performs flexible comparison testing assertions between two `AnyCodable` instances.
    @discardableResult
    private func assertFlexibleEqual(
        expected: AnyCodable?,
        actual: AnyCodable?,
        keyPath: [Any] = [],
        pathTree: [String: Any]?,
        exactMatchMode: Bool,
        file: StaticString = #file,
        line: UInt = #line,
        shouldAssert: Bool = true) -> Bool {
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
            // Default: exact value matching
            if exactMatchMode {
                if shouldAssert {
                    XCTAssertEqual(expected, actual, "Key path: \(keyPathAsString(keyPath))", file: file, line: line)
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
                exactMatchMode: exactMatchMode,
                file: file, line: line, shouldAssert: shouldAssert)
        case let (expected, actual) where (expected.value is [AnyCodable] && actual.value is [AnyCodable]):
            return assertFlexibleEqual(
                expected: expected.value as? [AnyCodable],
                actual: actual.value as? [AnyCodable],
                keyPath: keyPath,
                pathTree: pathTree,
                exactMatchMode: exactMatchMode,
                file: file, line: line, shouldAssert: shouldAssert)
        case let (expected, actual) where (expected.value is [Any?] && actual.value is [Any?]):
            return assertFlexibleEqual(
                expected: AnyCodable.from(array: expected.value as? [Any?]),
                actual: AnyCodable.from(array: actual.value as? [Any?]),
                keyPath: keyPath,
                pathTree: pathTree,
                exactMatchMode: exactMatchMode,
                file: file, line: line, shouldAssert: shouldAssert)
        case let (expected, actual) where (expected.value is [String: Any?] && actual.value is [String: Any?]):
            return assertFlexibleEqual(
                expected: AnyCodable.from(dictionary: expected.value as? [String: Any?]),
                actual: AnyCodable.from(dictionary: actual.value as? [String: Any?]),
                keyPath: keyPath,
                pathTree: pathTree,
                exactMatchMode: exactMatchMode,
                file: file, line: line, shouldAssert: shouldAssert)
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

    /// Performs flexible comparison testing assertions between two `[AnyCodable]` instances.
    private func assertFlexibleEqual(
        expected: [AnyCodable]?,
        actual: [AnyCodable]?,
        keyPath: [Any],
        pathTree: [String: Any]?,
        exactMatchMode: Bool,
        file: StaticString = #file,
        line: UInt = #line,
        shouldAssert: Bool = true) -> Bool {
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

        // Matches array subscripts and all the inner content (ex: "[*123]". However, only captures the inner content: ex: "123", "*123"
        let arrayIndexValueRegex = #"\[(.*?)\]"#
        // Get all of the alternate key paths for this level, and apply the array bracket inner content capture regex
        let indexValues = pathTree?.keys
            .flatMap { key in
                getCapturedRegexGroups(text: key, regexPattern: arrayIndexValueRegex, file: file, line: line)
            }
            .compactMap {$0} ?? []

        // Converts "0" -> 0
        var exactIndexes: [Int] = indexValues
            .filter { !$0.contains("*") }
            .compactMap { Int($0) }

        // Converts "*0" -> 0
        var wildcardIndexes: [Int] = indexValues
            .filter { $0.contains("*") }
            .compactMap {
                return Int($0.replacingOccurrences(of: "*", with: ""))
            }

        // Checks for [*]
        let hasWildcardAny: Bool = indexValues.contains("*")

        var seenIndexes: Set<Int> = []

        /// Relies on outer scope's:
        /// 1. **mutates** `seenIndexes`
        /// 2. `expected` array
        func createSortedValidatedRange(_ range: [Int]) -> [Int] {
            var result: [Int] = []
            for index in range {
                guard expected.indices.contains(index) else {
                    XCTFail("TEST ERROR: alternate match path using index (\(index)) is out of bounds. Verify the test setup for correctness.", file: file, line: line)
                    continue
                }
                guard seenIndexes.insert(index).inserted else {
                    XCTFail("TEST ERROR: index already seen: \(index). Verify the test setup for correctness.", file: file, line: line)
                    continue
                }
                result.append(index)
            }
            return result.sorted()
        }

        exactIndexes = createSortedValidatedRange(exactIndexes)
        wildcardIndexes = createSortedValidatedRange(wildcardIndexes)

        let unmatchedLHSIndices: Set<Int> = Set(expected.indices)
                                                .subtracting(exactIndexes)
                                                .subtracting(wildcardIndexes)

        // Evaluation precedence is:
        // Alternate match paths
        // 1. [0]
        // 2. [*0]
        // 3. [*] - mutually exclusive with 4
        // Default
        // 4. Standard indexes, all remaining expected indexes unspecified by 1-3

        var finalResult = true
        // Handle alternate match paths with format: [0]
        for index in exactIndexes {
            var keyPath = keyPath
            keyPath.append(index)
            let matchTreeValue = pathTree?["[\(index)]"]

            let isPathEnd = matchTreeValue is String

            finalResult = assertFlexibleEqual(
                expected: expected[index],
                actual: actual[index],
                keyPath: keyPath,
                pathTree: isPathEnd ? nil : matchTreeValue as? [String: Any], // if pathEnd, nil out pathTree
                exactMatchMode: isPathEnd ? !exactMatchMode : exactMatchMode, // if pathEnd, invert default equality mode
                file: file, line: line, shouldAssert: shouldAssert) && finalResult
        }

        var unmatchedRHSElements = Set(actual.indices).subtracting(exactIndexes)
                                    .sorted()
                                    .map { (originalIndex: $0, element: actual[$0]) }

        /// Relies on outer scope's:
        /// 1. pathTree
        /// 2. exactMatchMode
        /// 3. **mutates** unmatchedRHSElements
        /// 4. **mutates** finalResult
        func performWildcardMatch(expectedIndexes: [Int], isGeneralWildcard: Bool) {
            for index in expectedIndexes {
                var keyPath = keyPath
                keyPath.append(index)
                let matchTreeValue = isGeneralWildcard ? pathTree?["[*]"] : pathTree?["[*\(index)]"]

                let isPathEnd = matchTreeValue is String

                guard let result = unmatchedRHSElements.firstIndex(where: {
                    assertFlexibleEqual(
                        expected: expected[index],
                        actual: $0.element,
                        keyPath: keyPath,
                        pathTree: isPathEnd ? nil : matchTreeValue as? [String: Any], // if pathEnd, nil out pathTree
                        exactMatchMode: isPathEnd ? !exactMatchMode : exactMatchMode, // if pathEnd, invert default equality mode
                        file: file, line: line, shouldAssert: false)
                }) else {
                    XCTFail(#"""
                    Wildcard \#((isPathEnd ? !exactMatchMode : exactMatchMode) ? "exact" : "type") match found no matches on Actual side satisfying the Expected requirement.

                    Requirement: \#(String(describing: matchTreeValue))

                    Expected: \#(expected[index])

                    Actual (remaining unmatched elements): \#(unmatchedRHSElements.map { $0.element })

                    Key path: \#(keyPathAsString(keyPath))
                    """#, file: file, line: line)
                    finalResult = false
                    continue
                }
                unmatchedRHSElements.remove(at: result)

                finalResult = finalResult && true
            }
        }

        // Handle alternate match paths with format: [*<INT>]
        performWildcardMatch(expectedIndexes: wildcardIndexes.sorted(), isGeneralWildcard: false)
        // Handle alternate match paths with format: [*] - general wildcard is mutually exclusive with standard index comparison
        if hasWildcardAny {
            performWildcardMatch(expectedIndexes: unmatchedLHSIndices.sorted(by: { $0 < $1 }), isGeneralWildcard: true)
        } else {
            for index in unmatchedLHSIndices.sorted(by: { $0 < $1 }) {
                var keyPath = keyPath
                keyPath.append(index)

                guard unmatchedRHSElements.contains(where: { $0.originalIndex == index }) else {
                    XCTFail(#"""
                    Actual side's index \#(index) has already been taken by a wildcard match. Verify the test setup for correctness.

                    Expected: \#(expected[index])

                    Actual (remaining unmatched elements): \#(unmatchedRHSElements.map { $0.element })

                    Key path: \#(keyPathAsString(keyPath))
                    """#, file: file, line: line)
                    finalResult = false
                    continue
                }

                finalResult = assertFlexibleEqual(
                    expected: expected[index],
                    actual: actual[index],
                    keyPath: keyPath,
                    pathTree: nil, // There should be no array based key paths at this point
                    exactMatchMode: exactMatchMode,
                    file: file, line: line, shouldAssert: shouldAssert) && finalResult
            }
        }
        return finalResult
    }

    /// Performs flexible comparison testing assertions between two `[String: AnyCodable]` instances.
    private func assertFlexibleEqual(
        expected: [String: AnyCodable]?,
        actual: [String: AnyCodable]?,
        keyPath: [Any],
        pathTree: [String: Any]?,
        exactMatchMode: Bool,
        file: StaticString = #file,
        line: UInt = #line,
        shouldAssert: Bool = true) -> Bool {
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
            var keyPath = keyPath
            keyPath.append(key)
            let pathTreeValue = pathTree?[key]
            if pathTreeValue is String {
                finalResult = assertFlexibleEqual(
                    expected: value,
                    actual: actual[key],
                    keyPath: keyPath,
                    pathTree: nil, // is String means path terminates here
                    exactMatchMode: !exactMatchMode, // Invert default mode
                    file: file, line: line, shouldAssert: shouldAssert) && finalResult
            } else {
                finalResult = assertFlexibleEqual(
                    expected: value,
                    actual: actual[key],
                    keyPath: keyPath,
                    pathTree: pathTreeValue as? [String: Any],
                    exactMatchMode: exactMatchMode,
                    file: file, line: line, shouldAssert: shouldAssert) && finalResult
            }
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
    private func getKeyPathComponents(text: String, file: StaticString = #file, line: UInt = #line) -> [String] {
        // The empty string is a special case that the regex doesn't handle
        guard !text.isEmpty else {
            return [""]
        }
        
        // Capture groups:
        // 1. Any characters, or empty string before a `.` NOT preceded by a `\`
        // OR
        // 2. Any non-empty text preceding the end of the string
        //
        // Matches key path access in the style of: "key0\.key1.key2[1][2].key3". Captures each of the groups separated by `.` character and ignores `\.` as nesting.
        // the path example would result in: ["key0\.key1", "key2[1][2]", "key3"]
        let jsonNestingRegex = #"(.*?)(?<!\\)(?:\.)|(.+?)(?:$)"#
        
        guard let matchResult = extractRegexCaptureGroups(text: text, regexPattern: jsonNestingRegex, file: file, line: line) else {
            return []
        }
        
        var captureGroups = matchResult.flatMap({ $0.captureGroups })
        
        if matchResult.last?.matchString.last == "." {
            captureGroups.append("")
        }
        return captureGroups
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

    private func generatePathTree(paths: [String], file: StaticString = #file, line: UInt = #line) -> [String: Any]? {
        // Matches array subscripts and all the inner content. Captures the surrounding brackets and inner content: ex: "[123]", "[*123]"
        let arrayIndexRegex = #"(\[.*?\])"#
        var tree: [String: Any] = [:]

        for exactValuePath in paths {
            var allPathComponents: [String] = []
            var pathExtractionSuccessful: Bool = true

            // Break the path string into its component parts
            let keyPathComponents = getKeyPathComponents(text: exactValuePath, file: file, line: line)
            for pathComponent in keyPathComponents {
                let pathComponent = pathComponent.replacingOccurrences(of: "\\.", with: ".")

                // Get all array access levels for the given pathComponent, if any
                // KNOWN LIMITATION: this regex only extracts all open+close square brackets and inner content ("[___]") regardless
                // of their relative position within the path component, ex: "key0[2]key1[3]" will be interpreted as: "key0" with array component "[2][3]"
                let arrayComponents = getCapturedRegexGroups(text: pathComponent, regexPattern: arrayIndexRegex, file: file, line: line)

                // If no array components are detected, just add the path as-is
                if arrayComponents.isEmpty {
                    allPathComponents.append(pathComponent)
                }
                // Otherwise, extract just the path component before array components if it exists
                else {
                    guard let bracketIndex = pathComponent.firstIndex(of: "[") else {
                        XCTFail("TEST ERROR: unable to get bracket position from path: \(pathComponent). Skipping exact path: \(exactValuePath)", file: file, line: line)
                        pathExtractionSuccessful = false
                        break
                    }
                    let extractedPathComponent = String(pathComponent[..<bracketIndex])
                    // It is possible the path itself starts with an array index: "[0][1]"
                    // in that case, do not insert an empty string; all array components will be handled by the arrayComponents extraction
                    if !extractedPathComponent.isEmpty {
                        allPathComponents.append(extractedPathComponent)
                    }
                }
                allPathComponents.append(contentsOf: arrayComponents)
            }

            guard pathExtractionSuccessful else {
                XCTFail("TEST ERROR: some exact paths were not able to be extracted. Test will have unexpected results.", file: file, line: line)
                continue
            }
            let constructedTree = construct(path: allPathComponents, pathString: exactValuePath)
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
                }
                else if item.isEmpty {
                    result += "\"\""
                }
                else {
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

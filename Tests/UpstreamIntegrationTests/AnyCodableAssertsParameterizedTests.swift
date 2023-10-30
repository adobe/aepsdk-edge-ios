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

class AnyCodableAssertsParameterizedTests: XCTestCase {
    func testValueMatching() {
        let rawCases: [(expected: Any, actual: Any)] = [
            (expected: 1, actual: 1),
            (expected: 5.0, actual: 5.0),
            (expected: true, actual: true),
            (expected: "a", actual: "a"),
            (expected: "안녕하세요", actual: "안녕하세요")
        ]
        let testCases = rawCases.map { tuple in
            return (expected: AnyCodable(tuple.expected), actual: AnyCodable(tuple.actual))
        }
        for (index, (expected, actual)) in testCases.enumerated() {
            XCTContext.runActivity(named: "should match basic values: [\(index)]: test with expected=\(expected), actual=\(actual)") { _ in
                assertEqual(expected: expected, actual: actual)
                assertExactMatch(expected: expected, actual: actual)
                assertTypeMatch(expected: expected, actual: actual)
            }
        }
    }

    func testCollectionValueMatching() {
        let rawCases: [(expected: String, actual: String)] = [
            (expected: "[]", actual: "[]"), // Empty array
            (expected: "[[[]]]", actual: "[[[]]]"), // Nested arrays
            (expected: "{}", actual: "{}"), // Empty dictionary
            (expected: #"{ "key1": 1 }"#, actual: #"{ "key1": 1 }"#), // Key value pair
            (expected: #"{ "key1": { "key2": {} } }"#, actual: #"{ "key1": { "key2": {} } }"#), // Nested objects
            (expected: #"{ "key1": null }"#, actual: #"{ "key1": null }"#) // `null` as value
        ]
        let testCases = rawCases.map { tuple in
            return (expected: getAnyCodable(tuple.expected)!, actual: getAnyCodable(tuple.actual))
        }
        for (index, (expected, actual)) in testCases.enumerated() {
            XCTContext.runActivity(named: "should match basic collection values: [\(index)]: test with expected=\(expected), actual=\(actual)") { _ in
                assertEqual(expected: expected, actual: actual)
                assertExactMatch(expected: expected, actual: actual)
                assertTypeMatch(expected: expected, actual: actual)
            }
        }
    }

    func testTypeMatching() {
        let rawCases: [(expected: Any, actual: Any)] = [
            (expected: 5, actual: 10), // Int
            (expected: 5.0, actual: 10.0), // Double
            (expected: true, actual: false), // Bool
            (expected: "a", actual: "b"), // String
            (expected: "안", actual: "안녕하세요") // Non-Latin String
        ]
        let testCases = rawCases.map { tuple in
            return (expected: AnyCodable(tuple.expected), actual: AnyCodable(tuple.actual))
        }
        for (index, (expected, actual)) in testCases.enumerated() {
            XCTContext.runActivity(named: "should match only by type for values of the same type: [\(index)]: test with expected=\(expected), actual=\(actual)") { _ in
                XCTExpectFailure("Validation should fail when asserting exact equality for different values of the same type") {
                    assertExactMatch(expected: expected, actual: actual)
                }
                XCTExpectFailure("Validation should fail when asserting exact matches for different values of the same type") {
                    assertExactMatch(expected: expected, actual: actual)
                }
                assertTypeMatch(expected: expected, actual: actual)
            }
        }
    }

    func testCollectionTypeMatching() {
        let rawCases: [(expected: String, actual: String)] = [
            (expected: #"{ "key1": 1 }"#, actual: #"{ "key1": 2 }"#),
            (expected: #"{ "key1": { "key2": "a" } }"#, actual: #"{ "key1": { "key2": "b", "key3": 3 } }"#)
        ]
        let testCases = rawCases.map { tuple in
            return (expected: getAnyCodable(tuple.expected)!, actual: getAnyCodable(tuple.actual))
        }
        for (index, (expected, actual)) in testCases.enumerated() {
            XCTContext.runActivity(named: "should match only by type for values of the same type: [\(index)]: test with expected=\(expected), actual=\(actual)") { _ in
                XCTExpectFailure("Validation should fail when asserting exact equality for collections with different values or structures") {
                    assertEqual(expected: expected, actual: actual)
                }

                XCTExpectFailure("Validation should fail when asserting exact matches for collections with different values or structures") {
                    assertExactMatch(expected: expected, actual: actual)
                }

                assertTypeMatch(expected: expected, actual: actual)
            }
        }
    }

    func testFlexibleCollectionTypeMatching() {
        let rawCases: [(expected: String, actual: String)] = [
            (expected: #"[]"#, actual: #"[1]"#),
            (expected: #"[1,2,3]"#, actual: #"[1,2,3,4]"#),
            (expected: #"{}"#, actual: #"{ "k": "v" }"#),
            (expected: #"{ "key1": 1, "key2": "a", "key3": 1.0, "key4": true }"#,
             actual: #"{ "key1": 1, "key2": "a", "key3": 1.0, "key4": true, "key5": "extra" }"#)
        ]
        let testCases = rawCases.map { tuple in
            return (expected: getAnyCodable(tuple.expected)!, actual: getAnyCodable(tuple.actual))
        }
        for (index, (expected, actual)) in testCases.enumerated() {
            XCTContext.runActivity(named: "should pass flexible matching when expected is a subset: [\(index)]: test with expected=\(expected), actual=\(actual)") { _ in
                XCTExpectFailure("Validation should fail when asserting exact equality for collections where the actual has extra elements or keys") {
                    assertEqual(expected: expected, actual: actual)
                }
                assertExactMatch(expected: expected, actual: actual)
                assertTypeMatch(expected: expected, actual: actual)
            }
        }
    }

    func testFailure() {
        // Some cases do a double validation, where they check for unintended type casting
        // and the value type mismatch itself
        let rawCases: [(expected: Any?, actual: Any?)] = [
            (expected: 1, actual: 1.0), // [0]
            (expected: 1, actual: "1"),
            (expected: 1, actual: true),
            (expected: 0, actual: false),
            (expected: 1, actual: [:] as [String: Any]),
            (expected: 1, actual: [] as [Any]), // [5]
            (expected: 1, actual: nil),
            (expected: 2.0, actual: 2),
            (expected: 2.0, actual: "2.0"),
            (expected: 1.0, actual: true),
            (expected: 0.0, actual: false), // [10]
            (expected: 1.0, actual: false),
            (expected: 2.0, actual: [:] as [String: Any]),
            (expected: 2.0, actual: [] as [Any]),
            (expected: 2.0, actual: nil),
            (expected: "1", actual: 1), // [15]
            (expected: "2.0", actual: 2.0),
            (expected: "true", actual: true),
            (expected: "false", actual: false),
            (expected: "{}", actual: [:] as [String: Any]),
            (expected: "[]", actual: [] as [Any]), // [20]
            (expected: "null", actual: nil),
            (expected: "nil", actual: nil),
            (expected: true, actual: 1),
            (expected: true, actual: 1.0),
            (expected: true, actual: "true"), // [25]
            (expected: true, actual: [:] as [String: Any]),
            (expected: true, actual: [] as [Any]),
            (expected: true, actual: nil),
            (expected: false, actual: 0),
            (expected: false, actual: 0.0), // [30]
            (expected: false, actual: 1.0),
            (expected: false, actual: "false"),
            (expected: false, actual: [:] as [String: Any]),
            (expected: false, actual: [] as [Any]),
            (expected: false, actual: nil), // [35]
            (expected: [:] as [String: Any], actual: 1),
            (expected: [:] as [String: Any], actual: 2.0),
            (expected: [:] as [String: Any], actual: "{}"),
            (expected: [:] as [String: Any], actual: true),
            (expected: [:] as [String: Any], actual: [] as [Any]), // [40]
            (expected: [:] as [String: Any], actual: nil),
            (expected: ["key1": 1] as [String: Any], actual: ["key2": 1] as [String: Any]),
            (expected: [] as [Any], actual: 1),
            (expected: [] as [Any], actual: 2.0),
            (expected: [] as [Any], actual: "[]"), // [45]
            (expected: [] as [Any], actual: true),
            (expected: [] as [Any], actual: [:] as [String: Any]),
            (expected: [] as [Any], actual: nil)
        ]
        let testCases = rawCases.map { tuple in
            return (expected: AnyCodable(tuple.expected), actual: AnyCodable(tuple.actual))
        }
        for (index, (expected, actual)) in testCases.enumerated() {
            XCTContext.runActivity(named: "should error when not matching: [\(index)]: test with expected=\(expected), actual=\(actual)") { _ in
                XCTExpectFailure("Validation should fail when expected and actual have different types") {
                    assertEqual(expected: expected, actual: actual)
                }
                XCTExpectFailure("Validation should fail when expected and actual have different types") {
                    assertExactMatch(expected: expected, actual: actual)
                }
                XCTExpectFailure("Validation should fail when expected and actual have different types") {
                    assertTypeMatch(expected: expected, actual: actual)
                }
            }
        }
    }

    func testSpecialKey() {
        let rawCases: [(expected: String, actual: String)] = [
            (expected: #"{ "": 1 }"#, actual: #"{ "": 1 }"#), // Empty string
            (expected: #"{ "\\": 1 }"#, actual: #"{ "\\": 1 }"#), // Backslash
            (expected: #"{ "\\\\": 1 }"#, actual: #"{ "\\\\": 1 }"#), // Double backslash
            (expected: #"{ ".": 1 }"#, actual: #"{ ".": 1 }"#), // Dot
            (expected: #"{ "k.1.2.3": 1 }"#, actual: #"{ "k.1.2.3": 1 }"#), // Dot in key
            (expected: #"{ "k.": 1 }"#, actual: #"{ "k.": 1 }"#), // Dot at the end of key
            (expected: #"{ "\"": 1 }"#, actual: #"{ "\"": 1 }"#), // Escaped double quote
            (expected: #"{ "'": 1 }"#, actual: #"{ "'": 1 }"#), // Single quote
            (expected: #"{ "\\'": 1 }"#, actual: #"{ "\\'": 1 }"#), // Backslash before single quote
            (expected: #"{ "key with space": 1 }"#, actual: #"{ "key with space": 1 }"#), // Space in key
            (expected: #"{ "\n": 1 }"#, actual: #"{ "\n": 1 }"#), // Control character
            (expected: #"{ "key \t \n newline": 1 }"#, actual: #"{ "key \t \n newline": 1 }"#), // Control characters in key
            (expected: #"{ "안녕하세요": 1 }"#, actual: #"{ "안녕하세요": 1 }"#) // Non-Latin characters
        ]
        let testCases = rawCases.map { tuple in
            print(tuple)
            let expectedAnyCodable: AnyCodable? = getAnyCodable(tuple.expected)
            let actualAnyCodable: AnyCodable? = getAnyCodable(tuple.actual)
            return (expected: expectedAnyCodable!, actual: actualAnyCodable)
        }
        print("translated testCases: \(testCases)")
        for (index, (expected, actual)) in testCases.enumerated() {
            XCTContext.runActivity(named: "should match special key JSONs: [\(index)]: test with expected=\(expected), actual=\(actual)") { _ in
                assertEqual(expected: expected, actual: actual)
                assertExactMatch(expected: expected, actual: actual)
                assertTypeMatch(expected: expected, actual: actual)
            }
        }
    }

    func testAlternatePathValueDictionary() {
        let rawCases: [(path: String, expected: Any?, actual: Any?, format: (Any?) -> String)] = [
            (path: "key1", expected: 1, actual: 1, format: { #"{ "key1": \#($0!) }"# }),
            (path: "key1", expected: 2.0, actual: 2.0, format: { #"{ "key1": \#($0!) }"# }),
            (path: "key1", expected: "a", actual: "a", format: { #"{ "key1": "\#($0!)" }"# }),
            (path: "key1", expected: true, actual: true, format: { #"{ "key1": \#($0!) }"# }),
            (path: "key1", expected: "{}", actual: "{}", format: { #"{ "key1": \#($0!) }"# }),
            (path: "key1", expected: "[]", actual: "[]", format: { #"{ "key1": \#($0!) }"# }),
            (path: "key1", expected: nil, actual: nil, format: { #"{ "key1": \#($0 ?? "null") }"# })
        ]
        let testCases = rawCases.map { tuple in
            let expectedAnyCodable: AnyCodable? = getAnyCodable(tuple.format(tuple.expected))
            let actualAnyCodable: AnyCodable? = getAnyCodable(tuple.format(tuple.actual))
            return (path: tuple.path, expected: expectedAnyCodable!, actual: actualAnyCodable)
        }
        for (index, (path, expected, actual)) in testCases.enumerated() {
            XCTContext.runActivity(named: "should not fail because of alternate path: [\(index)]: test with path=\(path), expected=\(expected), actual=\(actual)") { _ in
                assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [path])
                assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: [path])
            }
        }
    }

    func testAlternatePathValueArray() {
        let rawCases: [(path: String, expected: Any?, actual: Any?, format: (Any?) -> String)] = [
            // Validating array format with specific index alternate mode path
            (path: "[0]", expected: 1, actual: 1, format: { #"[\#($0!)]"# }),
            (path: "[0]", expected: 2.0, actual: 2.0, format: { #"[\#($0!)]"# }),
            (path: "[0]", expected: "a", actual: "a", format: { #"["\#($0!)"]"# }),
            (path: "[0]", expected: true, actual: true, format: { #"[\#($0!)]"# }),
            (path: "[0]", expected: "{}", actual: "{}", format: { #"[\#($0!)]"# }),
            (path: "[0]", expected: "[]", actual: "[]", format: { #"[\#($0!)]"# }),
            (path: "[0]", expected: nil, actual: nil, format: { #"[\#($0 ?? "null")]"# }),
            // Validating array format with wildcard alternate mode path
            (path: "[*]", expected: 1, actual: 1, format: { #"[\#($0!)]"# }),
            (path: "[*]", expected: 2.0, actual: 2.0, format: { #"[\#($0!)]"# }),
            (path: "[*]", expected: "a", actual: "a", format: { #"["\#($0!)"]"# }),
            (path: "[*]", expected: true, actual: true, format: { #"[\#($0!)]"# }),
            (path: "[*]", expected: "{}", actual: "{}", format: { #"[\#($0!)]"# }),
            (path: "[*]", expected: "[]", actual: "[]", format: { #"[\#($0!)]"# }),
            (path: "[*]", expected: nil, actual: nil, format: { #"[\#($0 ?? "null")]"# })
        ]
        let testCases = rawCases.map { tuple in
            let expectedAnyCodable: AnyCodable? = getAnyCodable(tuple.format(tuple.expected))
            let actualAnyCodable: AnyCodable? = getAnyCodable(tuple.format(tuple.actual))
            return (path: tuple.path, expected: expectedAnyCodable!, actual: actualAnyCodable)
        }
        for (index, (path, expected, actual)) in testCases.enumerated() {
            XCTContext.runActivity(named: "should not fail because of alternate path: [\(index)]: test with path=\(path), expected=\(expected), actual=\(actual)") { _ in
                assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [path])
                assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: [path])
            }
        }
    }

    func testAlternatePathTypeDictionary() {
        let rawCases: [(path: String, expected: Any?, actual: Any?, format: (Any?) -> String)] = [
            (path: "key1", expected: 1, actual: 2, format: { #"{ "key1": \#($0!) }"# }),
            (path: "key1", expected: 1.0, actual: 2.0, format: { #"{ "key1": \#($0!) }"# }),
            (path: "key1", expected: "a", actual: "b", format: { #"{ "key1": "\#($0!)" }"# }),
            (path: "key1", expected: true, actual: false, format: { #"{ "key1": \#($0!) }"# })
        ]
        let testCases = rawCases.map { tuple in
            let expectedAnyCodable: AnyCodable? = getAnyCodable(tuple.format(tuple.expected))
            let actualAnyCodable: AnyCodable? = getAnyCodable(tuple.format(tuple.actual))
            return (path: tuple.path, expected: expectedAnyCodable!, actual: actualAnyCodable)
        }
        for (index, (path, expected, actual)) in testCases.enumerated() {
            XCTContext.runActivity(named: "should apply alternate path to matching logic: [\(index)]: test with path=\(path), expected=\(expected), actual=\(actual)") { _ in
                assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [path])
                XCTExpectFailure("Validation should fail when using a path without a match") {
                    assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: [path])
                }
            }
        }
    }

    func testAlternatePathTypeArray() {
        let rawCases: [(path: String, expected: Any, actual: Any, format: (Any) -> String)] = [
            // Validating array format with specific index alternate mode path
            (path: "[0]", expected: 1, actual: 2, format: { #"[\#($0)]"# }),
            (path: "[0]", expected: 1.0, actual: 2.0, format: { #"[\#($0)]"# }),
            (path: "[0]", expected: "a", actual: "b", format: { #"["\#($0)"]"# }),
            (path: "[0]", expected: true, actual: false, format: { #"[\#($0)]"# }),
            // Validating array format with wildcard alternate mode path
            (path: "[*]", expected: 1, actual: 2, format: { #"[\#($0)]"# }),
            (path: "[*]", expected: 1.0, actual: 2.0, format: { #"[\#($0)]"# }),
            (path: "[*]", expected: "a", actual: "b", format: { #"["\#($0)"]"# }),
            (path: "[*]", expected: true, actual: false, format: { #"[\#($0)]"# })
        ]
        let testCases = rawCases.map { tuple in
            let expectedAnyCodable: AnyCodable? = getAnyCodable(tuple.format(tuple.expected))
            let actualAnyCodable: AnyCodable? = getAnyCodable(tuple.format(tuple.actual))
            return (path: tuple.path, expected: expectedAnyCodable!, actual: actualAnyCodable)
        }
        for (index, (path, expected, actual)) in testCases.enumerated() {
            XCTContext.runActivity(named: "should apply alternate path to matching logic: [\(index)]: test with path=\(path), expected=\(expected), actual=\(actual)") { _ in
                assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [path])
                XCTExpectFailure("Validation should fail when using a path without a match") {
                    assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: [path])
                }
            }
        }
    }

    func testSpecialKeyAlternatePath() {
        let rawCases: [(path: String, expected: Any, actual: Any, format: (Any) -> String)] = [
            (path: "key1.", expected: 1, actual: 2, format: { #"{ "key1": { "": \#($0) } }"# }), // Nested empty string
            (path: "key1..key3", expected: 1, actual: 2, format: { #"{ "key1": { "": { "key3": \#($0) } } }"# }), // Non-empty strings surrounding empty string
            (path: ".key2.", expected: 1, actual: 2, format: { #"{ "": { "key2": { "": \#($0) } } }"# }),// Empty strings surrounding non-empty string
            (path: "\\\\.", expected: 1, actual: 2, format: { #"{ "\\.": \#($0) }"# }), // Backslash before dot
            (path: "", expected: 1, actual: 2, format: { #"{ "": \#($0) }"# }),  // Empty key
            (path: ".", expected: 1, actual: 2, format: { #"{ "": { "": \#($0) } }"# }), // Nested empty keys
            (path: "...", expected: 1, actual: 2, format: { #"{ "": { "": { "": { "": \#($0) } } } }"# }), // Multiple nested empty keys
            (path: "\\", expected: 1, actual: 2, format: { #"{ "\\": \#($0) }"# }), // Single backslash
            (path: "\\\\", expected: 1, actual: 2, format: { #"{ "\\\\": \#($0) }"# }), // Double backslashes
            (path: "\\.", expected: 1, actual: 2, format: { #"{ ".": \#($0) }"# }), // Backslash before dot
            (path: "k\\.1\\.2\\.3", expected: 1, actual: 2, format: { #"{ "k.1.2.3": \#($0) }"# }), // Dots in key
            (path: "k\\.", expected: 1, actual: 2, format: { #"{ "k.": \#($0) }"# }), // Dot at the end of the key
            (path: "\"", expected: 1, actual: 2, format: { #"{ "\"": \#($0) }"# }), // Escaped double quote
            (path: "\\'", expected: 1, actual: 2, format: { #"{ "\\'": \#($0) }"# }), // Backslash before single quote
            (path: "'", expected: 1, actual: 2, format: { #"{ "'": \#($0) }"# }), // Single quote
            (path: "key with space", expected: 1, actual: 2, format: { #"{ "key with space": \#($0) }"# }), // Space in key
            (path: "\n", expected: 1, actual: 2, format: { #"{ "\n": \#($0) }"# }), // Control character
            (path: "key \t \n newline", expected: 1, actual: 2, format: { #"{ "key \t \n newline": \#($0) }"# }), // Control characters in key
            (path: "안녕하세요", expected: 1, actual: 2, format: { #"{ "안녕하세요": \#($0) }"# }), // Non-Latin characters
            (path: "a]", expected: 1, actual: 2, format: { #"{ "a]": \#($0) }"# }), // Closing square bracket in key
            (path: "a[", expected: 1, actual: 2, format: { #"{ "a[": \#($0) }"# }), // Opening square bracket in key
            (path: "a[1]b", expected: 1, actual: 2, format: { #"{ "a[1]b": \#($0) }"# }), // Array style access in key
            (path: "key1\\[0\\]", expected: 1, actual: 2, format: { #"{ "key1[0]": \#($0) }"# }), // Array style access at the end of key
            (path: "\\[1\\][0]", expected: 1, actual: 2, format: { #"{ "[1]": [\#($0)] }"# }), // Array style key then actual array style access
            (path: "\\[1\\\\][0]", expected: 1, actual: 2, format: { #"{ "[1\\]": [\#($0)] }"# }) // Incomplete array style access then actual array style access
        ]
        let testCases = rawCases.map { tuple in
            let expectedAnyCodable: AnyCodable? = getAnyCodable(tuple.format(tuple.expected))
            let actualAnyCodable: AnyCodable? = getAnyCodable(tuple.format(tuple.actual))
            return (path: tuple.path, expected: expectedAnyCodable!, actual: actualAnyCodable)
        }
        for (index, (path, expected, actual)) in testCases.enumerated() {
            XCTContext.runActivity(named: "should handle special keys in alternate paths: [\(index)]: test with path=\(path), expected=\(expected), actual=\(actual)") { _ in
                assertExactMatch(expected: expected, actual: actual, typeMatchPaths: [path])
                XCTExpectFailure("Validation should fail when using a path without a match") {
                    assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: [path])
                }
            }
        }
    }

    func testExpectedArrayLarger() {
        let rawCases: [[String]] = [
            ["[0]"],
            ["[1]"],
            ["[0]", "[1]"],
            ["[*0]"],
            ["[*1]"],
            ["[*]"]
        ]
        let testCases = rawCases.map { paths in
            return (paths: paths, expected: getAnyCodable("[1,2]")!, actual: getAnyCodable("[1]"))
        }
        for (index, (paths, expected, actual)) in testCases.enumerated() {
            XCTContext.runActivity(named: "should error on larger expected arrays: [\(index)]: test with paths=\(paths), expected=\(expected), actual=\(actual)") { _ in
                XCTExpectFailure("Validation should fail when expected array size is larger") {
                    assertEqual(expected: expected, actual: actual)
                }
                XCTExpectFailure("Validation should fail when expected array size is larger") {
                    assertExactMatch(expected: expected, actual: actual, typeMatchPaths: paths)
                }
                XCTExpectFailure("Validation should fail when expected array size is larger") {
                    assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: paths)
                }
            }
        }
    }

    func testExpectedDictionaryLarger() {
        let rawCases: [[String]] = [
            ["key1"],
            ["key2"],
            ["key1", "key2"]
        ]
        let testCases = rawCases.map { paths in
            return (paths: paths,
                    expected: getAnyCodable(#"{ "key1": 1, "key2": 2 }"#)!,
                    actual: getAnyCodable(#"{ "key1": 1}"#))
        }
        for (index, (paths, expected, actual)) in testCases.enumerated() {
            XCTContext.runActivity(named: "should error on larger expected maps: [\(index)]: test with paths=\(paths), expected=\(expected), actual=\(actual)") { _ in
                XCTExpectFailure("Validation should fail when expected dictionary size is larger") {
                    assertEqual(expected: expected, actual: actual)
                }
                XCTExpectFailure("Validation should fail when expected dictionary size is larger") {
                    assertExactMatch(expected: expected, actual: actual, typeMatchPaths: paths)
                }
                XCTExpectFailure("Validation should fail when expected dictionary size is larger") {
                    assertTypeMatch(expected: expected, actual: actual, exactMatchPaths: paths)
                }
            }
        }
    }
}

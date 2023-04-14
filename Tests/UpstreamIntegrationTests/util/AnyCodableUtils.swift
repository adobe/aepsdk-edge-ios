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


import Foundation
import AEPServices
import XCTest

extension AnyCodable {
    /// Converts `AnyCodable`'s default decode strategy of array `[Any?]`  into `[AnyCodable]` value type
    public static func from(array: [Any?]?) -> [AnyCodable]? {
        guard let unwrappedArray = array else { return nil }
        
        var newArray: [AnyCodable] = []
        for val in unwrappedArray {
            if let anyCodableVal = val as? AnyCodable {
                newArray.append(anyCodableVal)
            } else {
                newArray.append(AnyCodable(val))
            }
        }
        
        return newArray
    }
    
}

class AnyCodableUtils {
    // MARK: AnyCodable helpers
    /// Performs testing assertions between two `[AnyCodable]` instances.
    @discardableResult
    static func assertEqual(lhs: [String: AnyCodable]?, rhs: [String: AnyCodable]?, keyPath: [Any], file: StaticString = #file, line: UInt = #line, shouldAssert: Bool = true) -> Bool {
        if lhs == nil, rhs == nil {
            return true
        }
        guard let lhs = lhs, let rhs = rhs else {
            if shouldAssert {
                XCTFail(#"""
                    \#(lhs == nil ? "lhs is nil" : "rhs is nil") and \#(lhs == nil ? "rhs" : "lhs") is non-nil
                
                    lhs: \#(String(describing: lhs))
                    
                    rhs: \#(String(describing: rhs))
                    
                    key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        if lhs.count != rhs.count {
            if shouldAssert {
                XCTFail(#"""
                    lhs and rhs counts do not match.
                    lhs count: \#(lhs.count)
                    rhs count: \#(rhs.count)
                    
                    lhs: \#(lhs)
                    
                    rhs: \#(rhs)
                    
                    key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        var finalResult = true
        for (key, value) in lhs {
            var keyPath = keyPath
            keyPath.append(key)
            finalResult = finalResult && assertEqual(lhs: value, rhs: rhs[key], keyPath: keyPath, file: file, line: line, shouldAssert: shouldAssert)
        }
        return finalResult
    }
    
    /// Performs flexible testing assertions between two `[AnyCodable]` instances.
    /// exactMatchTree = nil means no exact matching behavior
    static func assertFlexibleEqual(validation: [String: AnyCodable]?, input: [String: AnyCodable]?, keyPath: [Any], exactMatchTree: [String: Any]?, file: StaticString = #file, line: UInt = #line, shouldAssert: Bool = true) -> Bool {
        if validation == nil {
            return true
        }
        guard let lhs = validation, let rhs = input else {
            if shouldAssert {
                XCTFail(#"""
                    Validation JSON is non-nil but input JSON is nil.
                
                    validation: \#(String(describing: validation))
                    
                    input: \#(String(describing: input))
                    
                    key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        if lhs.count > rhs.count {
            if shouldAssert {
                XCTFail(#"""
                    Validation JSON has more elements than input.
                    validation count: \#(lhs.count)
                    input count: \#(rhs.count)
                    
                    validation: \#(lhs)
                    
                    input: \#(rhs)
                    
                    key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        var finalResult = true
        for (key, value) in lhs {
            var keyPath = keyPath
            keyPath.append(key)
            let matchTreeValue = exactMatchTree?[key]
            if matchTreeValue is String {
                finalResult = finalResult && assertEqual(lhs: value, rhs: rhs[key], keyPath: keyPath, file: file, line: line, shouldAssert: shouldAssert)
            }
            else {
                finalResult = finalResult && assertFlexibleEqual(validation: value, input: rhs[key], keyPath: keyPath, exactMatchTree: matchTreeValue as? [String: Any], file: file, line: line, shouldAssert: shouldAssert)
            }
        }
        return finalResult
    }
    
    /// Performs testing assertions between two `[AnyCodable]` instances.
    @discardableResult
    static func assertEqual(lhs: [AnyCodable]?, rhs: [AnyCodable]?, keyPath: [Any], file: StaticString = #file, line: UInt = #line, shouldAssert: Bool = true) -> Bool {
        if lhs == nil, rhs == nil {
            return true
        }
        guard let lhs = lhs, let rhs = rhs else {
            if shouldAssert {
                XCTFail(#"""
                    \#(lhs == nil ? "lhs is nil" : "rhs is nil") and \#(lhs == nil ? "rhs" : "lhs") is non-nil
                
                    lhs: \#(String(describing: lhs))
                    
                    rhs: \#(String(describing: rhs))
                    
                    key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        if lhs.count != rhs.count {
            if shouldAssert {
                XCTFail(#"""
                    lhs and rhs counts do not match.
                    lhs count: \#(lhs.count)
                    rhs count: \#(rhs.count)
                    
                    lhs: \#(lhs)
                    
                    rhs: \#(rhs)
                    
                    key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        var finalResult = true
        for (index, valueTuple) in zip(lhs, rhs).enumerated() {
            var keyPath = keyPath
            keyPath.append(index)
            finalResult = finalResult && assertEqual(lhs: valueTuple.0, rhs: valueTuple.1, keyPath: keyPath, file: file, line: line, shouldAssert: shouldAssert)
        }
        return finalResult
    }
    
    /// Performs testing assertions between two `[AnyCodable]` instances.
    static func assertFlexibleEqual(validation: [AnyCodable]?, input: [AnyCodable]?, keyPath: [Any], exactMatchTree: [String: Any]?, file: StaticString = #file, line: UInt = #line, shouldAssert: Bool = true) -> Bool {
        if validation == nil {
            return true
        }
        guard let lhs = validation, let rhs = input else {
            if shouldAssert {
                XCTFail(#"""
                    Validation JSON is non-nil but input JSON is nil.
                
                    validation: \#(String(describing: validation))
                    
                    input: \#(String(describing: input))
                    
                    key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        if lhs.count > rhs.count {
            if shouldAssert {
                XCTFail(#"""
                    Validation JSON has more elements than input.
                    validation count: \#(lhs.count)
                    input count: \#(rhs.count)
                    
                    validation: \#(lhs)
                    
                    input: \#(rhs)
                    
                    key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        // this is where the craziness begins
        // 1 check if exact match tree has [*] or [*0,1,2,3,4,...]
            // [*] means only the first element from validation is taken into account, and strongly matched
            // [*0] means the index from the validation is taken and strongly matched to any other element
            // [*].key1 means the fist element from validation is taken and matched to any other
        if let exactMatchTree = exactMatchTree {
            let arrayIndexValueRegex = #"\[(.*?)\]"#
            let indexValues = exactMatchTree.keys
                .flatMap { key in
                    getCapturedRegexGroups(text: key, regexPattern: arrayIndexValueRegex)
                }
                .compactMap {$0}
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
                if lhs.indices.contains(index) {
                    let result = seenIndices.insert(index)
                    if result.inserted {
                        finalExactIndices.append(index)
                    }
                    else {
                        print("WARNING: index already seen: \(index)")
                    }
                }
            }
            
            var finalWildcardIndices: [Int] = []
            for index in wildcardIndices {
                if lhs.indices.contains(index) {
                    let result = seenIndices.insert(index)
                    if result.inserted {
                        finalWildcardIndices.append(index)
                    }
                    else {
                        print("WARNING: wildcard index already seen: \(index)")
                    }
                }
            }
            
            var finalResult = true
            for index in finalExactIndices {
                var keyPath = keyPath
                keyPath.append(index)
                let matchTreeValue = exactMatchTree["[\(index)]"]
                if matchTreeValue is String {
                    finalResult = finalResult && assertEqual(lhs: lhs[index], rhs: rhs[index], keyPath: keyPath, file: file, line: line, shouldAssert: shouldAssert)
                }
                else {
                    finalResult = finalResult && assertFlexibleEqual(validation: lhs[index], input: rhs[index], keyPath: keyPath, exactMatchTree: matchTreeValue as? [String: Any], file: file, line: line, shouldAssert: shouldAssert)
                }
            }
            for index in finalWildcardIndices {
                var keyPath = keyPath
                keyPath.append(index)
                let matchTreeValue = exactMatchTree["[*\(index)]"]
                if matchTreeValue is String {
                    let result = rhs.first(where: {
                        assertEqual(lhs: lhs[index], rhs: $0, keyPath: keyPath, shouldAssert: false)
                    })
                    if result == nil {
                        XCTFail("wildcard exact match found no matches in input")
                        finalResult = false
                    }
                    else {
                        finalResult = finalResult && true
                    }
                }
                else {
                    let result = rhs.first(where: {
                        assertFlexibleEqual(validation: lhs[index], input: $0, keyPath: keyPath, exactMatchTree: matchTreeValue as? [String: Any], file: file, line: line, shouldAssert: false)
                    })
                    if result == nil {
                        XCTFail("wildcard match found no matches in input")
                        finalResult = false
                    }
                    else {
                        finalResult = finalResult && true
                    }
                }
            }
            if hasWildcardAny {
                for index in lhs.indices {
                    if !seenIndices.contains(index) {
                        seenIndices.insert(index)
                        var keyPath = keyPath
                        keyPath.append(index)
                        let matchTreeValue = exactMatchTree["[*]"]
                        if matchTreeValue is String {
                            let result = rhs.first(where: {
                                assertEqual(lhs: lhs[index], rhs: $0, keyPath: keyPath, shouldAssert: false)
                            })
                            if result == nil {
                                XCTFail("wildcard exact match found no matches in input")
                                finalResult = false
                            }
                            else {
                                finalResult = finalResult && true
                            }
                        }
                        else {
                            let result = rhs.first(where: {
                                assertFlexibleEqual(validation: lhs[index], input: $0, keyPath: keyPath, exactMatchTree: matchTreeValue as? [String: Any], file: file, line: line, shouldAssert: false)
                            })
                            if result == nil {
                                XCTFail("wildcard match found no matches in input")
                                finalResult = false
                            }
                            else {
                                finalResult = finalResult && true
                            }
                        }
                        break
                    }
                }
            }
            
            let finalUnusedIndices = Set(lhs.indices).subtracting(seenIndices)
            for index in finalUnusedIndices {
                var keyPath = keyPath
                keyPath.append(index)
                finalResult = finalResult && assertFlexibleEqual(validation: lhs[index], input: rhs[index], keyPath: keyPath, exactMatchTree: nil, file: file, line: line)
            }
            return finalResult
        }
        // Flexible validation based on 1:1 matching
        else {
            var finalResult = true
            for (index, valueTuple) in zip(lhs, rhs).enumerated() {
                var keyPath = keyPath
                keyPath.append(index)
                finalResult = finalResult && assertFlexibleEqual(validation: valueTuple.0, input: valueTuple.1, keyPath: keyPath, exactMatchTree: nil, file: file, line: line)
            }
            return finalResult
        }
    }
    
    /// Performs testing assertions between two `AnyCodable` instances, using a similar logic path as the `AnyCodable ==` implementation.
    /// Traces the key path (both dictionary keys and array indices) and provides the trace on assertion failure, for easier debugging.
    /// Automatically performs any required conversions of underlying `Any?` types into `AnyCodable` format.
    ///
    /// Main entrypoint for `AnyCodable` testing assertions.
    @discardableResult
    static func assertEqual(lhs: AnyCodable?, rhs: AnyCodable?, keyPath: [Any] = [], file: StaticString = #file, line: UInt = #line, shouldAssert: Bool = true) -> Bool {
        if lhs?.value == nil, rhs?.value == nil {
            return true
        }
        guard let lhs = lhs, let rhs = rhs else {
            if shouldAssert {
                XCTFail(#"""
                    \#(lhs == nil ? "lhs is nil" : "rhs is nil") and \#(lhs == nil ? "rhs" : "lhs") is non-nil
                
                    lhs: \#(String(describing: lhs))
                    
                    rhs: \#(String(describing: rhs))
                    
                    key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        
        switch (lhs.value, rhs.value) {
        case let (lhs as String, rhs as String):
            if shouldAssert {
                XCTAssertEqual(lhs, rhs, "key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
            }
            return lhs == rhs
        case let (lhs as Bool, rhs as Bool):
            if shouldAssert {
                XCTAssertEqual(lhs, rhs, "key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
            }
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            if shouldAssert {
                XCTAssertEqual(lhs, rhs, "key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
            }
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            if shouldAssert {
                XCTAssertEqual(lhs, rhs, "key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
            }
            return lhs == rhs
        case let (lhs as [String: AnyCodable], rhs as [String: AnyCodable]):
            return assertEqual(lhs: lhs, rhs: rhs, keyPath: keyPath, file: file, line: line, shouldAssert: shouldAssert)
        case let (lhs as [AnyCodable], rhs as [AnyCodable]):
            return assertEqual(lhs: lhs, rhs: rhs, keyPath: keyPath, file: file, line: line, shouldAssert: shouldAssert)
        case let (lhs as [Any?], rhs as [Any?]):
            return assertEqual(lhs: AnyCodable.from(array: lhs), rhs: AnyCodable.from(array: rhs), keyPath: keyPath, file: file, line: line, shouldAssert: shouldAssert)
        case let (lhs as [String: Any?], rhs as [String: Any?]):
            return assertEqual(lhs: AnyCodable.from(dictionary: lhs), rhs: AnyCodable.from(dictionary: rhs), keyPath: keyPath, file: file, line: line, shouldAssert: shouldAssert)
        default:
            if shouldAssert {
                XCTFail(#"""
                    lhs and rhs types do not match
                
                    lhs: \#(lhs)
                    
                    rhs: \#(rhs)
                    
                    key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
    }
    
    /// Performs testing assertions between two `AnyCodable` instances, using a similar logic path as the `AnyCodable ==` implementation.
    /// Traces the key path (both dictionary keys and array indices) and provides the trace on assertion failure, for easier debugging.
    /// Automatically performs any required conversions of underlying `Any?` types into `AnyCodable` format.
    ///
    /// Main entrypoint for `AnyCodable` testing assertions.
    @discardableResult
    static func assertFlexibleEqual(validation: AnyCodable?, input: AnyCodable?, keyPath: [Any] = [], exactMatchTree: [String: Any]?, file: StaticString = #file, line: UInt = #line, shouldAssert: Bool = true) -> Bool {
        if validation?.value == nil {
            return true
        }
        guard let lhs = validation, let rhs = input else {
            if shouldAssert {
                XCTFail(#"""
                    Validation JSON is non-nil but input JSON is nil.
                
                    validation: \#(String(describing: validation))
                    
                    input: \#(String(describing: input))
                    
                    key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
        
        switch (lhs.value, rhs.value) {
        case let (lhs as String, rhs as String):
            if exactMatchTree != nil { return true }
            if shouldAssert {
                XCTAssertEqual(lhs, rhs, "key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
            }
            return lhs == rhs
        case let (lhs as Bool, rhs as Bool):
            if exactMatchTree != nil { return true }
            if shouldAssert {
                XCTAssertEqual(lhs, rhs, "key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
            }
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            if exactMatchTree != nil { return true }
            if shouldAssert {
                XCTAssertEqual(lhs, rhs, "key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
            }
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            if exactMatchTree != nil { return true }
            if shouldAssert {
                XCTAssertEqual(lhs, rhs, "key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
            }
            return lhs == rhs
        case let (lhs as [String: AnyCodable], rhs as [String: AnyCodable]):
            return assertFlexibleEqual(validation: lhs, input: rhs, keyPath: keyPath, exactMatchTree: exactMatchTree, file: file, line: line, shouldAssert: shouldAssert)
        case let (lhs as [AnyCodable], rhs as [AnyCodable]):
            return assertFlexibleEqual(validation: lhs, input: rhs, keyPath: keyPath, exactMatchTree: exactMatchTree, file: file, line: line, shouldAssert: shouldAssert)
        case let (lhs as [Any?], rhs as [Any?]):
            return assertFlexibleEqual(validation: AnyCodable.from(array: lhs), input: AnyCodable.from(array: rhs), keyPath: keyPath, exactMatchTree: exactMatchTree, file: file, line: line, shouldAssert: shouldAssert)
        case let (lhs as [String: Any?], rhs as [String: Any?]):
            return assertFlexibleEqual(validation: AnyCodable.from(dictionary: lhs), input: AnyCodable.from(dictionary: rhs), keyPath: keyPath, exactMatchTree: exactMatchTree, file: file, line: line, shouldAssert: shouldAssert)
        default:
            if shouldAssert {
                XCTFail(#"""
                    lhs and rhs types do not match
                
                    lhs: \#(lhs)
                    
                    rhs: \#(rhs)
                    
                    key path: \#(keyPathAsString(keyPath: keyPath))
                """#, file: file, line: line)
            }
            return false
        }
    }
    
    
    static func getCapturedRegexGroups(text: String, regexPattern: String) -> [String?] {
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
    static func merge(current: [String: Any], new: [String: Any]) -> [String: Any] {
        var current = current
        for (key, newValue) in new {
            var currentValue = current[key]
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
    static func construct(path: [String], pathString: String) -> [String: Any] {
        var path = path
        let first = path.removeFirst()
        let result: [String: Any]
        if path.isEmpty {
            result = [first: pathString]
            return result
        }
        else {
            return [first: construct(path: path, pathString: pathString)]
        }
    }
    
    static func generateExactMatchTree(exactMatchPaths: [String]) -> [String: Any] {
        let arrayIndexRegex = #"(\[.*?\])"#
        let arrayIndexValueRegex = #"\[(.*?)\]"#
        let jsonNestingRegex = #"(.+?)(?<!\\)(?:\.|$)"#
        var tree: [String: Any] = [:]
        
        for exactValuePath in exactMatchPaths {
            var allPathComponents: [String] = []
            var pathExtractionSuccessful: Bool = true
            
            // Break the path string into its component parts
            let splitByNesting = getCapturedRegexGroups(text: exactValuePath, regexPattern: jsonNestingRegex)
            for pathComponent in splitByNesting {
                guard let pathComponent = pathComponent else {
                    print(#"""
                        ERROR: unable to extract valid key path component from path: \#(exactValuePath)
                        Skipping this path in validation process.
                    """#)
                    pathExtractionSuccessful = false
                    break
                }
                
                // Get all array access levels for the given pathComponent, if any
                // KNOWN LIMITATION: this regex only extracts all open+close square brackets and inner content ("[___]") regardless
                // of their relative position within the path component
                let arrayComponents = getCapturedRegexGroups(text: pathComponent, regexPattern: arrayIndexRegex)
                
                // If array components are detected, extract just the path component before array components if it exists
                if !arrayComponents.isEmpty {
                    guard let bracketIndex = pathComponent.firstIndex(of: "[") else {
                        print("ERROR: unable to get bracket position from path: \(pathComponent). Skipping exact path: \(exactValuePath)")
                        pathExtractionSuccessful = false
                        break
                    }
                    let sanitizedPathComponent = String(pathComponent[..<bracketIndex])
                    // It is possible the path itself is an array index; in that case do not insert an empty string
                    if !sanitizedPathComponent.isEmpty {
                        allPathComponents.append(sanitizedPathComponent)
                    }
                }
                // Otherwise just add the path
                else {
                    allPathComponents.append(pathComponent)
                }
                
                for arrayComponent in arrayComponents {
                    guard let arrayComponent = arrayComponent else {
                        print(#"""
                            ERROR: unable to extract valid array key path component from path: \#(exactValuePath)
                            Skipping this path in validation process.
                        """#)
                        pathExtractionSuccessful = false
                        break
                    }
                    allPathComponents.append(arrayComponent)
                }
            }
            
            guard pathExtractionSuccessful else {
                print("ERROR: some exact paths were not able to be extracted. Test will have unexpected results.")
                continue
            }
            let constructedTree = construct(path: allPathComponents, pathString: exactValuePath)
            tree = merge(current: tree, new: constructedTree)
            
        }
        return tree
    }
    
    // "payload\[\*\]\.scope", matches: "EdgeNetwork")
    // whereExactValues -> flat keys to use exact value
    static func assertContains(validation: AnyCodable?, input: AnyCodable?, exactMatchPaths: [String], file: StaticString = #file, line: UInt = #line) {
        let exactMatchTree = generateExactMatchTree(exactMatchPaths: exactMatchPaths)
        assertFlexibleEqual(validation: validation, input: input, exactMatchTree: exactMatchTree, file: file, line: line)
    }
    
    static func keyPathAsString(keyPath: [Any]) -> String {
        var result = ""
        for item in keyPath {
            switch item {
            case let item as String:
                if !result.isEmpty {
                    result += "."
                }
                if item.contains(".") {
                    result += "\"" + item + "\""
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


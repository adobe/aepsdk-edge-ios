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
    static func assertEqual(lhs: [String: AnyCodable]?, rhs: [String: AnyCodable]?, keyPath: [Any], file: StaticString = #file, line: UInt = #line) {
        if lhs == nil, rhs == nil {
            return
        }
        guard let lhs = lhs, let rhs = rhs else {
            XCTFail(#"""
                \#(lhs == nil ? "lhs is nil" : "rhs is nil") and \#(lhs == nil ? "rhs" : "lhs") is non-nil
            
                lhs: \#(String(describing: lhs))
                
                rhs: \#(String(describing: rhs))
                
                key path: \#(keyPathAsString(keyPath: keyPath))
            """#, file: file, line: line)
            return
        }
        if lhs.count != rhs.count {
            XCTFail(#"""
                lhs and rhs counts do not match.
                lhs count: \#(lhs.count)
                rhs count: \#(rhs.count)
                
                lhs: \#(lhs)
                
                rhs: \#(rhs)
                
                key path: \#(keyPathAsString(keyPath: keyPath))
            """#, file: file, line: line)
            return
        }
        for (key, value) in lhs {
            var keyPath = keyPath
            keyPath.append(key)
            assertEqual(lhs: value, rhs: rhs[key], keyPath: keyPath, file: file, line: line)
        }
    }
    
    /// Performs testing assertions between two `[AnyCodable]` instances.
    static func assertEqual(lhs: [AnyCodable]?, rhs: [AnyCodable]?, keyPath: [Any], file: StaticString = #file, line: UInt = #line) {
        if lhs == nil, rhs == nil {
            return
        }
        guard let lhs = lhs, let rhs = rhs else {
            XCTFail(#"""
                \#(lhs == nil ? "lhs is nil" : "rhs is nil") and \#(lhs == nil ? "rhs" : "lhs") is non-nil
            
                lhs: \#(String(describing: lhs))
                
                rhs: \#(String(describing: rhs))
                
                key path: \#(keyPathAsString(keyPath: keyPath))
            """#, file: file, line: line)
            return
        }
        if lhs.count != rhs.count {
            XCTFail(#"""
                lhs and rhs counts do not match.
                lhs count: \#(lhs.count)
                rhs count: \#(rhs.count)
                
                lhs: \#(lhs)
                
                rhs: \#(rhs)
                
                key path: \#(keyPathAsString(keyPath: keyPath))
            """#, file: file, line: line)
            return
        }
        for (index, valueTuple) in zip(lhs, rhs).enumerated() {
            var keyPath = keyPath
            keyPath.append(index)
            assertEqual(lhs: valueTuple.0, rhs: valueTuple.1, keyPath: keyPath, file: file, line: line)
        }
    }
    /// Performs testing assertions between two `AnyCodable` instances, using a similar logic path as the `AnyCodable ==` implementation.
    /// Traces the key path (both dictionary keys and array indices) and provides the trace on assertion failure, for easier debugging.
    /// Automatically performs any required conversions of underlying `Any?` types into `AnyCodable` format.
    ///
    /// Main entrypoint for `AnyCodable` testing assertions.
    static func assertEqual(lhs: AnyCodable?, rhs: AnyCodable?, keyPath: [Any] = [], file: StaticString = #file, line: UInt = #line) {
        if lhs?.value == nil, rhs?.value == nil {
            return
        }
        guard let lhs = lhs, let rhs = rhs else {
            XCTFail(#"""
                \#(lhs == nil ? "lhs is nil" : "rhs is nil") and \#(lhs == nil ? "rhs" : "lhs") is non-nil
            
                lhs: \#(String(describing: lhs))
                
                rhs: \#(String(describing: rhs))
                
                key path: \#(keyPathAsString(keyPath: keyPath))
            """#, file: file, line: line)
            return
        }
        
        switch (lhs.value, rhs.value) {
        case let (lhs as String, rhs as String):
            XCTAssertEqual(lhs, rhs, "key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
        case let (lhs as Bool, rhs as Bool):
            XCTAssertEqual(lhs, rhs, "key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
        case let (lhs as Int, rhs as Int):
            XCTAssertEqual(lhs, rhs, "key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
        case let (lhs as Double, rhs as Double):
            XCTAssertEqual(lhs, rhs, "key path: \(keyPathAsString(keyPath: keyPath))", file: file, line: line)
        case let (lhs as [String: AnyCodable], rhs as [String: AnyCodable]):
            return assertEqual(lhs: lhs, rhs: rhs, keyPath: keyPath, file: file, line: line)
        case let (lhs as [AnyCodable], rhs as [AnyCodable]):
            return assertEqual(lhs: lhs, rhs: rhs, keyPath: keyPath, file: file, line: line)
        case let (lhs as [Any?], rhs as [Any?]):
            return assertEqual(lhs: AnyCodable.from(array: lhs), rhs: AnyCodable.from(array: rhs), keyPath: keyPath, file: file, line: line)
        case let (lhs as [String: Any?], rhs as [String: Any?]):
            return assertEqual(lhs: AnyCodable.from(dictionary: lhs), rhs: AnyCodable.from(dictionary: rhs), keyPath: keyPath, file: file, line: line)
        default:
            XCTFail(#"""
                lhs and rhs types do not match
            
                lhs: \#(lhs)
                
                rhs: \#(rhs)
                
                key path: \#(keyPathAsString(keyPath: keyPath))
            """#, file: file, line: line)
        }
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


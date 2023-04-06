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
import XCTest

enum JSON: Equatable {
    case object([String:JSON])
    case array([JSON])
    case string(String)
    case bool(Bool)
    case number(Double)
    case null
    
    static func ==(lhs: JSON, rhs: JSON) -> Bool {
        switch lhs {
        case .object(let leftDictionary):
            guard let rightDictionary: [String: JSON] = rhs.value() else {
                XCTFail(#"""
                        rhs is NOT [String: Any] and is not equal to lhs

                        lhs: \#(leftDictionary)
                        
                        rhs: \#(rhs)
                        """#)
                return false
            }
            if rightDictionary.count != leftDictionary.count {
                XCTFail(#"""
                        lhs and rhs (type: [String: Any]) counts do not match.
                        lhs count: \#(leftDictionary.count)
                        rhs count: \#(rightDictionary.count)
                        
                        lhs: \#(leftDictionary)
                        
                        rhs: \#(rightDictionary)
                        """#)
                return false
            }
            for (key, value) in leftDictionary {
                print("KEY: \(key)")
                XCTAssertEqual(value, rightDictionary[key])
            }
        case .array(let leftArray):
            guard let rightArray: [JSON] = rhs.value() else {
                XCTFail(#"""
                        rhs is NOT [Any] and is not equal to lhs

                        lhs: \#(leftArray)
                        
                        rhs: \#(rhs)
                        """#)
                return false
                
            }
            if rightArray.count != leftArray.count {
                XCTFail(#"""
                        lhs and rhs (type: [String]) counts do not match.
                        lhs count: \#(leftArray.count)
                        rhs count: \#(rightArray.count)
                        
                        lhs: \#(leftArray)
                        
                        rhs: \#(rightArray)
                        """#)
                return false
            }
            for index in leftArray.indices {
                print("INDEX: \(index)")
                XCTAssertEqual(leftArray[index], rightArray[index])
            }
        case .string(let string):
            XCTAssertEqual(string, rhs.value() as String?, "original rhs: \(rhs)")
        case .bool(let bool):
            XCTAssertEqual(bool, rhs.value() as Bool?, "original rhs: \(rhs)")
        case .number(let number):
            XCTAssertEqual(number, rhs.value() as Double?, "original rhs: \(rhs)")
        case .null:
            guard case .null = rhs else {
                XCTFail(#"""
                        rhs is NOT nil and is not equal to lhs

                        lhs: \#(lhs)
                        
                        rhs: \#(rhs)
                        """#)
                return false
            }
        }
        return true
    }
    
    func value<T>() -> T? {
        switch self {
        case .object(let value):
            return value as? T
        case .array(let value):
            return value as? T
        case .bool(let value):
            return value as? T
        case .number(let value):
            return value as? T
        case .string(let value):
            return value as? T
        case .null:
            return nil
        }
    }
}

extension JSON : Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let object = try? container.decode([String: JSON].self) {
            self = .object(object)
        } else if let array = try? container.decode([JSON].self) {
            self = .array(array)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid JSON value."
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case let .object(object):
            try container.encode(object)
        case let .array(array):
            try container.encode(array)
        case let .string(string):
            try container.encode(string)
        case let .bool(bool):
            try container.encode(bool)
        case let .number(number):
            try container.encode(number)
        case .null:
            try container.encodeNil()
        }
    }
}

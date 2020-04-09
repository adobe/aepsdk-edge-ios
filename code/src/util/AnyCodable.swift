//
// ADOBE CONFIDENTIAL
//
// Copyright 2020 Adobe
// All Rights Reserved.
//
// NOTICE: All information contained herein is, and remains
// the property of Adobe and its suppliers, if any. The intellectual
// and technical concepts contained herein are proprietary to Adobe
// and its suppliers and are protected by all applicable intellectual
// property laws, including trade secret and copyright laws.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from Adobe.
//

import Foundation

/// A type erasing struct that can allow for dynamic `Codable` types
struct AnyCodable: Codable {
    public let value: Any?

    var stringValue: String? {
        return value as? String
    }

    var boolValue: Bool? {
        return value as? Bool
    }

    var intValue: Int? {
        return value as? Int
    }

    var doubleValue: Double? {
        return value as? Double
    }

    var arrayValue: [Any]? {
        return value as? [Any]
    }

    var dictionaryValue: [AnyHashable: Any]? {
        return value as? [AnyHashable: Any]
    }

    public init(_ value: Any?) {
        self.value = value
    }

    static func from(dictionary: [AnyHashable: Any]) -> [AnyHashable: AnyCodable] {
        var newDict: [AnyHashable: AnyCodable] = [:]
        for (key, val) in dictionary {
            newDict[key] = AnyCodable(val)
        }

        return newDict
    }

    // MARK: Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let array = try? container.decode([AnyCodable].self) {
            self.init(array.map { $0.value })
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.init(dictionary.mapValues { $0.value })
        } else if container.decodeNil() {
            self.init(nil)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Failed to decode AnyCodable")
        }
    }

    // MARK: Codable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        guard value != nil else {
            try container.encodeNil()
            return
        }

        switch value {
        case let string as String:
            try container.encode(string)
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let date as Date:
            try container.encode(date)
        case let url as URL:
            try container.encode(url)
        case let array as [Any?]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            print("AnyCodable - encode: Failed to encode \(String(describing: value))")
        }
    }
}

// MARK: Literal extensions
extension AnyCodable: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension AnyCodable: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }
}

extension AnyCodable: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (AnyHashable, Any)...) {
        let dict = [AnyHashable: Any](elements, uniquingKeysWith: { key, _ in key })
        self.init(dict)
    }
}

extension AnyCodable: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self.init(nil)
    }
}

// MARK: Equatable
extension AnyCodable: Equatable {
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        if lhs.value == nil && rhs.value == nil {
            return true
        }

        switch (lhs.value, rhs.value) {
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as [String: AnyCodable], rhs as [String: AnyCodable]):
            return lhs == rhs
        case let (lhs as [AnyCodable], rhs as [AnyCodable]):
            return lhs == rhs
        default:
            return false
        }
    }
}

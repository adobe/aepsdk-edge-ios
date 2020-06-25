//
// Copyright 2020 Adobe. All rights reserved.
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
import ACPExperiencePlatform

struct TestXDMObject {
    public init() {}
    
    public var innerKey: String?
    
    enum CodingKeys: String, CodingKey {
        case innerKey = "innerKey"
    }
}

extension TestXDMObject: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = innerKey { try container.encode(unwrapped, forKey: .innerKey) }
    }
}

struct TestXDMSchema : XDMSchema {
    public let schemaVersion = "1.5"
    public let schemaIdentifier = "https://schema.example.com"
    public let datasetIdentifier = "abc123def"
    
    public init() {}
    
    public var xdmObject: TestXDMObject?
    public var stringObject: String?
    public var intObject: Int?
    public var boolObject: Bool?
    public var doubleObject: Double?
    public var timestamp: Date?
    
    enum CodingKeys: String, CodingKey {
        case xdmObject = "xdmObject"
        case stringObject = "stringObject"
        case intObject = "intObject"
        case boolObject = "boolObject"
        case doubleObject = "doubleObject"
        case timestamp = "timestamp"
    }
}

extension TestXDMSchema: Encodable{
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = xdmObject { try container.encode(unwrapped, forKey: .xdmObject) }
        if let unwrapped = stringObject { try container.encode(unwrapped, forKey: .stringObject) }
        if let unwrapped = intObject { try container.encode(unwrapped, forKey: .intObject) }
        if let unwrapped = boolObject { try container.encode(unwrapped, forKey: .boolObject) }
        if let unwrapped = doubleObject { try container.encode(unwrapped, forKey: .doubleObject) }
        if let unwrapped = XDMFormatters.dateToISO8601String(from: timestamp) { try container.encode(unwrapped, forKey: .timestamp) }
    }
}

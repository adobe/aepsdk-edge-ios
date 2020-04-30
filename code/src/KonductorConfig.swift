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

/// Konductor configuration metadata.
/// Is contained within the `RequestMetadata` request property.
struct KonductorConfig : Codable {
    /// Configure Konductor to provide the response fragments in a streaming fashion.
    let streaming: Streaming?
}

/// Konductor configuration metadata to provide response fragments in a streaming fashion (HTTP 1.1/chunked, IETF RFC 7464).
struct Streaming {
    /// Control charactor used before each response fragment.
    let recordSeparator: Character?
    
    /// Control character used at the end of each response fragment.
    let lineFeed: Character?
    
    /// Getter to state whether response streaming is enabled.
    var enabled: Bool? {
        return recordSeparator != nil && lineFeed != nil
    }

    enum CodingKeys: String, CodingKey {
        case recordSeparator = "recordSeparator"
        case lineFeed = "lineFeed"
        case enabled = "enabled"
    }
}

extension Streaming : Codable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = recordSeparator { try container.encode(unwrapped, forKey: .recordSeparator)}
        if let unwrapped = lineFeed { try container.encode(unwrapped, forKey: .lineFeed)}
        if let unwrapped = enabled { try container.encode(unwrapped, forKey: .enabled)}
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recordSeparator = try? container.decode(Character.self, forKey: .recordSeparator)
        lineFeed = try? container.decode(Character.self, forKey: .lineFeed)
    }
}

extension Character : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(String(self))
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let string = try container.decode(String.self)
        guard string.count == 1 else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode Character with multiple characters")
        }
        guard let character = string.first else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode empty Character")
        }
        self = character
    }
    
}


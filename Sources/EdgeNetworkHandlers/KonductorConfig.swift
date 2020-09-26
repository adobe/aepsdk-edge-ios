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
struct KonductorConfig: Encodable {
    /// Configure Konductor to provide the response fragments in a streaming fashion.
    let streaming: Streaming?
}

/// Konductor configuration metadata to provide response fragments in a streaming fashion (HTTP 1.1/chunked, IETF RFC 7464).
struct Streaming {
    /// Control character used before each response fragment.
    let recordSeparator: String?

    /// Control character used at the end of each response fragment.
    let lineFeed: String?

    /// Getter to state whether response streaming is enabled.
    var enabled: Bool? {
        return recordSeparator != nil && lineFeed != nil
    }

    enum CodingKeys: String, CodingKey {
        case recordSeparator
        case lineFeed
        case enabled
    }
}

extension Streaming: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = recordSeparator { try container.encode(unwrapped, forKey: .recordSeparator)}
        if let unwrapped = lineFeed { try container.encode(unwrapped, forKey: .lineFeed)}
        if let unwrapped = enabled { try container.encode(unwrapped, forKey: .enabled)}
    }
}

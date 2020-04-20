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

/// Konductor configuration metadata.
/// Is contained within the `RequestMetadata` request property.
struct KonductorConfig : Encodable {
    /// The IMS Org ID. Typically this is the Experience Platform Org ID.
    let imsOrgId: String?
    
    /// Configure Konductor to provide the response fragments in a streaming fashion.
    let streaming: Streaming?
}

/// Konductor configuration metadata to provide response fragments in a streaming fashion (HTTP 1.1/chunked, IETF RFC 7464).
struct Streaming {
    /// Control charactor used before each response fragment.
    let recordSeparator: String?
    
    /// Control character used at the end of each response fragment.
    let lineFeed: String?
    
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

extension Streaming : Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = recordSeparator { try container.encode(unwrapped, forKey: .recordSeparator)}
        if let unwrapped = lineFeed { try container.encode(unwrapped, forKey: .lineFeed)}
        if let unwrapped = enabled { try container.encode(unwrapped, forKey: .enabled)}
    }
}


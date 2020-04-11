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

struct RequestMetadata {
    var konductorConfig: KonductorConfig?
    var state: StateMetadata?
    
    enum CodingKeys: String, CodingKey {
        case konductorConfig = "konductorConfig"
        case state = "state"
    }
}

extension RequestMetadata : Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = konductorConfig { try container.encode(unwrapped, forKey: .konductorConfig)}
        if let unwrapped = state { try container.encode(unwrapped, forKey: .state)}
    }
}

extension RequestMetadata : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        konductorConfig = try? container.decode(KonductorConfig.self, forKey: .konductorConfig)
        state = try? container.decode(StateMetadata.self, forKey: .state)
    }
}

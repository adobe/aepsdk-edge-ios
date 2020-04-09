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

/// Property that holds the global XDM context data within an Edge Request object.
struct RequestContext {
    var identityMap: IdentityMap?

    enum CodingKeys: String, CodingKey {
        case identityMap = "identityMap"
    }
}

extension RequestContext : Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = identityMap { try container.encode(unwrapped, forKey: .identityMap)}
    }
}

extension RequestContext : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identityMap = try? container.decode(IdentityMap.self, forKey: .identityMap)
    }
}

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

struct StateMetadata {
    private var cookiesEnabled: Bool
    private var entries: [StoreResponsePayload]

    init(payload: [String : StoreResponsePayload]) {
        cookiesEnabled = ExperiencePlatformConstants.Defaults.requestStateCookiesEnabled
        entries = []
        // convert map to list of StoreResponsePayload objects
        for (_, payload) in payload {
            entries.append(payload)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case entries = "entries"
        case cookiesEnabled = "cookiesEnabled"
    }
}

extension StateMetadata : Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cookiesEnabled, forKey: .cookiesEnabled)
        if !entries.isEmpty {
            try container.encode(entries, forKey: .entries)
        }
    }
}

extension StateMetadata : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cookiesEnabled = (try? container.decode(Bool.self, forKey: .cookiesEnabled)) ?? ExperiencePlatformConstants.Defaults.requestStateCookiesEnabled
        entries = (try? container.decode([StoreResponsePayload].self, forKey: .entries)) ?? []
    }
}

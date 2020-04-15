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

struct StoreResponsePayload {
    
    /// The store payload from the server response
    let payload: StorePayload
    
    var key: String {
        return payload.key
    }
    
    /// The `Date` at which this payload expires
    let expiryDate: Date
    
    /// Checks if the payload has exceeded its max age
    var isExpired: Bool {
        return Date() >= expiryDate
    }
    
    init(key: String, value: String, maxAgeSeconds: TimeInterval) {
        payload = StorePayload(key: key, value: value, maxAge: maxAgeSeconds)
        expiryDate = Date(timeIntervalSinceNow: maxAgeSeconds)
    }
    
    enum CodingKeys: String, CodingKey {
        case key = "key"
        case value = "value"
        case maxAgeSeconds = "maxAge"
        case expiryDate = "expiryDate"
    }
}

extension StoreResponsePayload : Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(payload.key, forKey: .key)
        try container.encode(payload.value, forKey: .value)
        try container.encode(payload.maxAge, forKey: .maxAgeSeconds)
        try container.encode(expiryDate, forKey: .expiryDate)
    }
}

extension StoreResponsePayload : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = try container.decode(String.self, forKey: .key)
        let value = try container.decode(String.self, forKey: .value)
        let maxAgeSeconds = try container.decode(TimeInterval.self, forKey: .maxAgeSeconds)
        self.payload = StorePayload(key: key, value: value, maxAge: maxAgeSeconds)
        
        if let date = try? container.decode(Date.self, forKey: .expiryDate) {
            expiryDate = date
        } else {
            expiryDate = Date(timeIntervalSinceNow: maxAgeSeconds)
        }
    }
}

struct StorePayload : Codable {
    /// They payload key identifier
    let key: String
    
    /// The payload value
    let value: String
    
    /// The max age in seconds this payload should be stored
    let maxAge: TimeInterval
}

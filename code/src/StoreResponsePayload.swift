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
    let key: String
    let value: String
    let maxAgeSeconds: TimeInterval
    let expiryDate: Date
    var isExpired: Bool {
        return Date() >= expiryDate
    }
    
    init(key: String, value: String, maxAgeSeconds: TimeInterval) {
        self.key = key
        self.value = value
        self.maxAgeSeconds = maxAgeSeconds
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
        try container.encode(key, forKey: .key)
        try container.encode(value, forKey: .value)
        try container.encode(maxAgeSeconds, forKey: .maxAgeSeconds)
        try container.encode(expiryDate.timeIntervalSince1970, forKey: .expiryDate)
    }
}

extension StoreResponsePayload : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = (try? container.decode(String.self, forKey: .key)) ?? ""
        value = (try? container.decode(String.self, forKey: .value)) ?? ""
        maxAgeSeconds = (try? container.decode(TimeInterval.self, forKey: .maxAgeSeconds)) ?? 0
        if let expiryTime = try? container.decode(TimeInterval.self, forKey: .expiryDate) {
            expiryDate = Date(timeIntervalSince1970: expiryTime)
        } else {
            expiryDate = Date(timeIntervalSinceNow: maxAgeSeconds)
        }
    }
}

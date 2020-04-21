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

/// Contains a `StorePayload` plus bookeeping expires information.
/// Use this object when serializing to local storage.
struct StoreResponsePayload : Codable {
    
    /// The store payload from the server response
    let payload: StorePayload
    
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
}

/// Store payload from the server response.
/// Contains only the parameters sent over the network.
struct StorePayload : Codable {
    /// They payload key identifier
    let key: String
    
    /// The payload value
    let value: String
    
    /// The max age in seconds this payload should be stored
    let maxAge: TimeInterval
}

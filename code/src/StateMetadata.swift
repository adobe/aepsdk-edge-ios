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

/// Client side stored information.
/// A property in the `RequestMetadata` object.
struct StateMetadata : Codable {
    private var entries: [StorePayload]?

    init(payload: [StorePayload]) {
        entries = payload.isEmpty ? nil : payload
    }
}

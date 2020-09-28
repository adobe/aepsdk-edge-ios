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

/// Contains a `StorePayload` with its expiring information.
/// Use this object when serializing to local storage.
struct StoreResponsePayload: Codable {

    /// The store payload from the server response
    let payload: StorePayload

    /// The `Date` at which this payload expires
    let expiryDate: Date

    /// Checks if the payload has exceeded its max age
    var isExpired: Bool {
        return Date() >= expiryDate
    }

    init(payload: StorePayload) {
        self.payload = payload
        expiryDate = Date(timeIntervalSinceNow: payload.maxAge)
    }
}

/// Store payload from the server response.
/// Contains only the parameters sent over the network.
struct StorePayload: Codable {
    /// They payload key identifier
    let key: String

    /// The payload value
    let value: String

    /// The max age in seconds this payload should be stored
    let maxAge: TimeInterval
}

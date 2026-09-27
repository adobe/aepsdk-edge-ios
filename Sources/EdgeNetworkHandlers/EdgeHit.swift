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

import AEPCore
import AEPServices
import Foundation

/// Protocol used for defining hits to Experience Edge service
protocol EdgeHit {

    /// The Edge endpoint
    var endpoint: EdgeEndpoint { get }

    /// The Edge configuration identifier
    var datastreamId: String { get }

    /// Unique identifier for the Edge request
    var requestId: String { get }

    /// The network request payload for this `EdgeHit`
    func getPayload() -> String?

    /// Retrieves the `Streaming` settings for this `EdgeHit` or nil if not enabled
    func getStreamingSettings() -> Streaming?
}

/// `EdgeHit` for the consent-override (device‑attributes) path. Unlike `ExperienceEventsEdgeHit`,
/// its body is a dynamic dictionary produced by `RequestBuilder.generateNoConsentPayload`, so any
/// producer field flows through without a typed model. Response streaming is not used.
struct NoConsentEdgeHit: EdgeHit {
    let endpoint: EdgeEndpoint
    let datastreamId: String
    let requestId: String = UUID().uuidString

    /// The fully-formed request body (producer `app`/`tokens`/`timezone` + SDK `xdm`/`meta`).
    let payload: [String: AnyCodable]

    func getPayload() -> String? {
        guard !payload.isEmpty else { return nil }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(payload) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    func getStreamingSettings() -> Streaming? {
        return nil
    }
}

//
// Copyright 2026 Adobe. All rights reserved.
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

/// `EdgeHit` for the consent-independent device-attributes path.
/// Its dynamic body is produced by `RequestBuilder.generateNoConsentPayload`.
/// Response streaming is not used.
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

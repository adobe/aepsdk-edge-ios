//
// Copyright 2021 Adobe. All rights reserved.
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

/// Implementation of `EdgeHit` for Consent update requests
struct ConsentEdgeHit: EdgeHit {
    let endpoint: EdgeEndpoint
    let configId: String
    let requestId: String = UUID().uuidString

    /// The `EdgeConsentUpdate` for the corresponding hit
    let consents: EdgeConsentUpdate

    func getPayload() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(self.consents) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    func getStreamingSettings() -> Streaming? {
        return consents.meta?.konductorConfig?.streaming
    }
}

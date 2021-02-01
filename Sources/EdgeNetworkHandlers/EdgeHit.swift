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
import Foundation

/// Struct which represents an Edge hit
protocol EdgeHit {
    /// The Edge configuration identifier
    var configId: String { get }

    /// Unique identifier for this hit
    var requestId: String { get }

    /// The `ExperienceEdgeRequestType` to be used for this `EdgeHit`
    func getType() -> ExperienceEdgeRequestType

    /// The network request payload for this `EdgeHit`
    func getPayload() -> String?

    /// Retrieves the `Streaming` settings for this `EdgHit` or nil if not enabled
    func getStreamingSettings() -> Streaming?
}

class ExperienceEventsEdgeHit: EdgeHit {
    var configId: String
    var requestId: String

    /// The `EdgeRequest` for the corresponding hit
    let request: EdgeRequest?

    init(configId: String, request: EdgeRequest) {
        self.configId = configId
        self.requestId = UUID().uuidString
        self.request = request
    }

    func getType() -> ExperienceEdgeRequestType {
        ExperienceEdgeRequestType.interact
    }

    func getPayload() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        guard let data = try? encoder.encode(self.request) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    func getStreamingSettings() -> Streaming? {
        return request?.meta?.konductorConfig?.streaming
    }
}

class ConsentEdgeHit: EdgeHit {
    var configId: String
    var requestId: String

    /// The `EdgeConsentUpdate` for the corresponding hit
    let consents: EdgeConsentUpdate?

    init(configId: String, consents: EdgeConsentUpdate) {
        self.configId = configId
        self.requestId = UUID().uuidString
        self.consents = consents
    }

    func getType() -> ExperienceEdgeRequestType {
        ExperienceEdgeRequestType.consent
    }

    func getPayload() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        guard let data = try? encoder.encode(self.consents) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    func getStreamingSettings() -> Streaming? {
        return nil
    }
}

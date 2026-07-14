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

import AEPCore
import AEPServices
import Foundation

/// Represents the data persisted with a hit
struct EdgeDataEntity: Codable {
    /// The `Event` responsible for the hit
    let event: Event

    /// The current configuration shared state at the time `Event` was queued
    let configuration: [String: AnyCodable]

    /// The current identity shared state at the time `Event` was queued
    let identityMap: [String: AnyCodable]

    /// Whether batching was enabled (via the `edge.batching.enabled` Configuration flag) at the time `Event` was queued
    let batchingEnabled: Bool

    init(event: Event, configuration: [String: AnyCodable], identityMap: [String: AnyCodable], batchingEnabled: Bool = false) {
        self.event = event
        self.configuration = configuration
        self.identityMap = identityMap
        self.batchingEnabled = batchingEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case event
        case configuration
        case identityMap
        case batchingEnabled
    }

    // Custom decoder so hits persisted before `batchingEnabled` was introduced (no such key in their
    // stored JSON) still decode successfully, defaulting to `false` instead of failing the whole hit.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        event = try container.decode(Event.self, forKey: .event)
        configuration = try container.decode([String: AnyCodable].self, forKey: .configuration)
        identityMap = try container.decode([String: AnyCodable].self, forKey: .identityMap)
        batchingEnabled = (try? container.decode(Bool.self, forKey: .batchingEnabled)) ?? false
    }
}

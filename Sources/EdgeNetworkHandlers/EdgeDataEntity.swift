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

    /// The current configuration shared state at the time `Event` was queued. May also contain the
    /// `edge.batching.enabled`/`edge.batching.eventNameAllowlist` keys snapshotted at enqueue time
    /// (see `SharedStateReader.getEdgeBatchingConfig`).
    let configuration: [String: AnyCodable]

    /// The current identity shared state at the time `Event` was queued
    let identityMap: [String: AnyCodable]
}

extension Dictionary where Key == String, Value == AnyCodable {
    /// This dictionary's values unwrapped as `[String: Any]`, dropping any `nil` `AnyCodable` values.
    /// Used to safely read individually-typed keys (e.g. batching config flags) out of a heterogeneous
    /// snapshot without risking a blanket `as? [String: T]` cast failing because of unrelated keys.
    var asAnyDictionary: [String: Any] {
        AnyCodable.toAnyDictionary(dictionary: self) ?? [:]
    }
}

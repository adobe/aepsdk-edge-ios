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

import Foundation

/// Parsed, immutable view of the Edge batching configuration object (`edge.batching`), mirroring
/// `aepsdk-edge-android`'s `EdgeBatchingConfig`.
///
/// The same grouped format is used whether the object arrives via Configuration shared state
/// (remote/Launch) or the bundled asset file, so this parser is the single source of truth for both:
///
/// ```
/// {
///   "_meta": { ... },            // ignored
///   "enabled": true,             // master switch
///   "maxBatchSize": 10,          // clamped to MAX_BATCH_SIZE_LIMIT
///   "wildcards": [ { "xdmEventType": "media.*", "enabled": true } ],
///   "<anyExtensionName>": [ { "xdmEventType": "media.play", "enabled": true } ]
/// }
/// ```
///
/// Reserved top-level keys are `_meta`, `enabled`, `maxBatchSize` and `wildcards`; every other
/// top-level key is treated as an *extension group*: an array of event objects. Extension grouping is
/// cosmetic - all groups are flattened (OR-deduped) into a single allow-list of enabled `xdmEventType`
/// values. An event is batchable strictly by whitelist: only if its `xdm.eventType` matches an enabled
/// exact entry or an enabled wildcard.
struct EdgeBatchingConfig {
    let isEnabled: Bool
    let maxBatchSize: Int
    private let enabledEventTypes: Set<String>
    private let enabledWildcards: Set<String>

    /// Disabled, empty config used when no batching object is present.
    static let disabled = EdgeBatchingConfig(isEnabled: false,
                                             maxBatchSize: EdgeConstants.Defaults.MAX_BATCH_SIZE,
                                             enabledEventTypes: [],
                                             enabledWildcards: [])

    /// Strict allow-list check: whether an outgoing event's `xdm.eventType` is batchable. An event with
    /// no `xdm.eventType`, or one matched only by disabled entries, is not batchable.
    ///
    /// - Parameter xdmEventType: the `xdm.eventType` of the outgoing Experience Event (may be nil)
    /// - Returns: true if the event type is whitelisted (exact or wildcard) for batching
    func isEventTypeBatchable(_ xdmEventType: String?) -> Bool {
        guard let xdmEventType = xdmEventType, !xdmEventType.isEmpty else {
            return false
        }
        if enabledEventTypes.contains(xdmEventType) {
            return true
        }
        return enabledWildcards.contains { Self.matchesWildcard(pattern: $0, value: xdmEventType) }
    }

    /// Parses the `edge.batching` object out of the provided (already-resolved) Edge configuration
    /// map. Returns a disabled, empty config when the object is missing or not a map.
    ///
    /// - Parameter edgeConfiguration: the Edge configuration map snapshotted on an entity (see
    ///   `SharedStateReader.getEdgeBatchingConfig`)
    /// - Returns: an immutable parsed view; never nil
    static func from(_ edgeConfiguration: [String: Any]?) -> EdgeBatchingConfig {
        guard let batching = edgeConfiguration?[EdgeConstants.SharedState.Configuration.EDGE_BATCHING] as? [String: Any] else {
            return disabled
        }

        let enabled = batching[EdgeConstants.Batching.ENABLED] as? Bool ?? false

        var maxBatchSize = batching[EdgeConstants.Batching.MAX_BATCH_SIZE] as? Int ?? EdgeConstants.Defaults.MAX_BATCH_SIZE
        if maxBatchSize <= 0 {
            maxBatchSize = EdgeConstants.Defaults.MAX_BATCH_SIZE
        }
        maxBatchSize = min(maxBatchSize, EdgeConstants.Defaults.MAX_BATCH_SIZE_LIMIT)

        var exactTypes = Set<String>()
        var wildcards = Set<String>()

        // Wildcards: dedicated reserved array, parsed as patterns.
        collectEnabled(batching, key: EdgeConstants.Batching.WILDCARDS, into: &wildcards)

        // Every other top-level key (i.e. not a reserved key) is an extension group of exact entries.
        for key in batching.keys where !isReservedKey(key) {
            collectEnabled(batching, key: key, into: &exactTypes)
        }

        return EdgeBatchingConfig(isEnabled: enabled,
                                  maxBatchSize: maxBatchSize,
                                  enabledEventTypes: exactTypes,
                                  enabledWildcards: wildcards)
    }

    /// Reads the array under `key` as event objects and adds the `xdmEventType` of each enabled
    /// entry to `target`. Missing arrays are ignored; malformed entries within an otherwise-valid array
    /// are skipped individually rather than discarding the whole array.
    private static func collectEnabled(_ batching: [String: Any], key: String, into target: inout Set<String>) {
        guard let entries = batching[key] as? [Any] else {
            return
        }
        for entry in entries {
            guard let entry = entry as? [String: Any],
                  entry[EdgeConstants.Batching.ENABLED] as? Bool ?? false else {
                continue
            }
            if let type = entry[EdgeConstants.Batching.XDM_EVENT_TYPE] as? String, !type.isEmpty {
                target.insert(type)
            }
        }
    }

    private static let reservedKeys: Set<String> = [
        EdgeConstants.Batching.META,
        EdgeConstants.Batching.ENABLED,
        EdgeConstants.Batching.MAX_BATCH_SIZE,
        EdgeConstants.Batching.WILDCARDS
    ]

    private static func isReservedKey(_ key: String) -> Bool {
        return reservedKeys.contains(key)
    }

    /// Case-sensitive wildcard match. Supports a single trailing `*` (prefix match), a single leading
    /// `*` (suffix match), and a bare `*` (match all). Any other pattern (including an infix `*` or no
    /// `*`) is compared for exact equality.
    private static func matchesWildcard(pattern: String, value: String) -> Bool {
        if pattern == "*" {
            return true
        }
        let leadingStar = pattern.hasPrefix("*")
        let trailingStar = pattern.hasSuffix("*")
        if trailingStar && !leadingStar {
            return value.hasPrefix(String(pattern.dropLast()))
        }
        if leadingStar && !trailingStar {
            return value.hasSuffix(String(pattern.dropFirst()))
        }
        return pattern == value
    }
}

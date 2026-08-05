//
// Copyright 2024 Adobe. All rights reserved.
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

struct SharedStateReader {
    private let SELF_TAG = "SharedStateReader"
    private var getSharedState: (String, Event?, Bool) -> SharedStateResult?

    init(getSharedState: @escaping (String, Event?, Bool) -> SharedStateResult?) {
        self.getSharedState = getSharedState
    }

    /// Get the Edge configuration by quering the Configuration shared state and filtering out only the key needed for Edge requests.
    /// - Parameter event: the `Event` to get the configuration
    /// - Returns: A dictionary of Edge configuration values, or empty dictionary if the Configuration shared state could not be retrieved.
    func getEdgeConfig(event: Event) -> [String: String] {
        guard let configurationState = getSharedState(EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME, event, false)?.value else {
            Log.trace(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Configuration shared state is nil for event '\(event.id.uuidString)'.")
            return [:]
        }

        let edgeConfig = configurationState.filter {
            return $0.key == EdgeConstants.SharedState.Configuration.CONFIG_ID ||
                $0.key == EdgeConstants.SharedState.Configuration.EDGE_ENVIRONMENT ||
                $0.key == EdgeConstants.SharedState.Configuration.EDGE_DOMAIN
        } as? [String: String]

        return edgeConfig ?? [:]
    }

    /// Reads the `edge.batching.enabled` and `edge.batching.eventNameAllowlist` keys for the given `event`,
    /// mirroring `aepsdk-edge-android`'s `EventUtils.getEdgeConfiguration` batching section.
    ///
    /// This is a per-key fallback, not a wholesale configuration replacement: the bundled config
    /// (`EdgeBundledBatchingConfig`) is only consulted for a given key when that key is absent from the
    /// Configuration shared state. Any value present in the Configuration shared state - whether set
    /// programmatically or delivered by a remote/Launch-published configuration - always wins over the
    /// bundled file's value for that same key.
    /// - Parameter event: the `Event` used to retrieve the Configuration shared state.
    /// - Returns: a dictionary containing whichever of the two batching keys resolved to a value, from
    ///   Configuration shared state or the bundled fallback.
    func getEdgeBatchingConfig(event: Event) -> [String: Any] {
        let configurationState = getSharedState(EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME, event, false)?.value ?? [:]
        let bundledBatchingConfig = EdgeBundledBatchingConfig.get()

        var batchingConfig: [String: Any] = [:]

        if let enabled = configurationState[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_ENABLED] {
            batchingConfig[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_ENABLED] = enabled as? Bool ?? false
        } else if let bundledEnabled = bundledBatchingConfig[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_ENABLED] {
            batchingConfig[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_ENABLED] = bundledEnabled as? Bool ?? false
        }

        if let allowlist = configurationState[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_EVENT_NAME_ALLOWLIST] {
            batchingConfig[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_EVENT_NAME_ALLOWLIST] = allowlist as? [String]
        } else if let bundledAllowlist = bundledBatchingConfig[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_EVENT_NAME_ALLOWLIST] {
            batchingConfig[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_EVENT_NAME_ALLOWLIST] = bundledAllowlist as? [String]
        }

        return batchingConfig
    }

    /// Get the Assurance integration ID from the Assurance shared state for the given `event`.
    /// - Parameter event: the `Event` used to retrieve the Assurance shared state.
    /// - Returns: the `integrationid` from the Assurance shared state or nil if the shared state or integration id is does not exist.
    func getAssuranceIntegrationId(event: Event) -> String? {
        if let assuranceSharedState = getSharedState(EdgeConstants.SharedState.Assurance.STATE_OWNER_NAME, event, false)?.value {
            if let assuranceIntegrationId = assuranceSharedState[EdgeConstants.SharedState.Assurance.INTEGRATION_ID] as? String {
                return assuranceIntegrationId
            }
        }
        return nil
    }
}

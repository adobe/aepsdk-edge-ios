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

import AEPServices
import Foundation

/// Loads the bundled fallback for the Edge batching configuration (`edge.batching`) from a JSON file
/// bundled in the app, mirroring `aepsdk-edge-android`'s `EdgeBundledBatchingConfig`. The file uses the
/// same grouped format as the Configuration shared-state value (see `EdgeBatchingConfig`), so both are
/// parsed identically.
///
/// This is a *wholesale* fallback, not a per-key merge: `SharedStateReader.getEdgeBatchingConfig` uses
/// this bundled object only when `edge.batching` is absent from the Configuration shared state at the
/// time an event is queued. A batching config present in the Configuration shared state - whether set
/// programmatically via `MobileCore.updateConfiguration()` or delivered by a remote/Launch-published
/// configuration - wins in its entirety over the bundled file.
enum EdgeBundledBatchingConfig {
    private static let SELF_TAG = "EdgeBundledBatchingConfig"

    /// Name (without extension) of the JSON file expected in the app bundle.
    static let BUNDLED_CONFIG_FILE_NAME = "ADBMobileEdgeBatchingConfig"
    static let BUNDLED_CONFIG_FILE_TYPE = "json"

    private static let loadLock = NSLock()
    private static var cachedConfig: [String: Any]?
    private static var loadAttempted = false

    /// Returns the parsed contents of the bundled batching config file, loading and caching it the
    /// first time this is called. Subsequent calls return the cached result without re-reading the
    /// file. Returns an empty dictionary (never nil) if the file is missing, empty, or malformed.
    static func get() -> [String: Any] {
        loadLock.lock()
        defer { loadLock.unlock() }

        if !loadAttempted {
            cachedConfig = load()
            loadAttempted = true
        }

        return cachedConfig ?? [:]
    }

    /// Clears the cached result so the next call to `get()` re-reads the bundled file.
    /// Test-only; production code should never need to force a re-read.
    static func resetForTesting() {
        loadLock.lock()
        defer { loadLock.unlock() }

        cachedConfig = nil
        loadAttempted = false
    }

    private static func load() -> [String: Any] {
        guard let content: String = ServiceProvider.shared.systemInfoService.getAsset(fileName: BUNDLED_CONFIG_FILE_NAME, fileType: BUNDLED_CONFIG_FILE_TYPE),
              !content.isEmpty else {
            Log.trace(label: EdgeConstants.LOG_TAG,
                      "\(SELF_TAG) - No bundled batching config file '\(BUNDLED_CONFIG_FILE_NAME).\(BUNDLED_CONFIG_FILE_TYPE)' found; skipping.")
            return [:]
        }

        guard let data = content.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let parsed = jsonObject as? [String: Any] else {
            Log.warning(label: EdgeConstants.LOG_TAG,
                        "\(SELF_TAG) - Failed to parse bundled batching config file '\(BUNDLED_CONFIG_FILE_NAME).\(BUNDLED_CONFIG_FILE_TYPE)'.")
            return [:]
        }

        Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Loaded bundled batching config from '\(BUNDLED_CONFIG_FILE_NAME).\(BUNDLED_CONFIG_FILE_TYPE)': \(parsed)")
        return parsed
    }
}

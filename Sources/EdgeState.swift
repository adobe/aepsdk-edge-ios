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

/// Updates the state of the  `Edge` extension based on the Collect consent status
class EdgeState {
    private let SELF_TAG = "EdgeState"
    private static let DEFAULT_WRAPPER_TYPE = "N"
    private(set) var hitQueue: HitQueuing
    private(set) var hasBooted = false
    private(set) var currentCollectConsent: ConsentStatus
    private(set) var wrapperType = DEFAULT_WRAPPER_TYPE

    /// Creates a new `EdgeState` and initializes the required properties and sets the initial collect consent
    init(hitQueue: HitQueuing) {
        self.hitQueue = hitQueue
        self.currentCollectConsent = EdgeConstants.Defaults.COLLECT_CONSENT_PENDING
        hitQueue.handleCollectConsentChange(status: currentCollectConsent)
    }

    /// Completes init for the `Edge` extension and the collect consent is set based on either Consent shared state
    /// or the default value if this extension is not registered
    ///
    /// - Parameters:
    ///   - event: The `Event` triggering the bootup
    ///   - getSharedState: used to fetch the `Event Hub` shared state
    func bootupIfNeeded(event: Event, getSharedState: @escaping (_ name: String, _ event: Event?, _ barrier: Bool) -> SharedStateResult?) {
        guard !hasBooted else { return }

        // check if consent extension is registered
        var consentRegistered = false
        if let registeredExtensionsWithHub = getSharedState(EdgeConstants.SharedState.Hub.SHARED_OWNER_NAME, event, false)?.value,
           let extensions = registeredExtensionsWithHub[EdgeConstants.SharedState.Hub.EXTENSIONS] as? [String: Any],
           extensions[EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME] as? [String: Any] != nil {
            consentRegistered = true
        }

        if !consentRegistered {
            Log.warning(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Consent extension is not registered yet, using default collect status (yes)")
            updateCurrentConsent(status: EdgeConstants.Defaults.COLLECT_CONSENT_YES)
        }
        // else keep consent pending until the consent preferences update event is received

        // extract wrapper type from hub shared state
        if let registeredExtensionsWithHub = getSharedState(EdgeConstants.SharedState.Hub.SHARED_OWNER_NAME, event, false)?.value,
           let wrapperInfo = registeredExtensionsWithHub[EdgeConstants.SharedState.Hub.WRAPPER] as? [String: Any],
           let type = wrapperInfo[EdgeConstants.SharedState.Hub.WRAPPER_TYPE] as? String {
            wrapperType = type
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Wrapper type set to (\(wrapperType)), extracted from hub shared state")
        }

        hasBooted = true
        Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Edge has successfully booted up")
    }

    /// Updates `currentCollectConsent` value and updates the hitQueue state based on it.
    ///
    /// - Parameters:
    ///   - status: The new collect consent status
    func updateCurrentConsent(status: ConsentStatus) {
        currentCollectConsent = status
        hitQueue.handleCollectConsentChange(status: status)
    }
}

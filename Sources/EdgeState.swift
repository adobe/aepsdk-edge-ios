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

class EdgeState {
    private let LOG_TAG = "EdgeState"
    private(set) var hitQueue: HitQueuing
    private(set) var hasBooted = false
    private(set) var currentCollectConsent = EdgeConstants.Defaults.COLLECT_CONSENT_PENDING

    /// Creates a new `EdgeState` and initializes the required properties
    init(hitQueue: HitQueuing) {
        self.hitQueue = hitQueue
    }

    /// Completes init for the `Edge` extension and the collect consent is set based on either Consent shared state
    /// or the default value if this extension is not registered
    ///
    /// - Parameters:
    ///   - event: The `Event` triggering the bootup
    ///   - getXDMSharedState: used to fetch the Consent data
    func bootupIfNeeded(event: Event, getXDMSharedState: @escaping (String, Event?) -> SharedStateResult?) {
        guard !hasBooted else { return }

        // check if consent extension is registered
        let consentSharedState = getXDMSharedState(EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME, nil)
        if consentSharedState == nil {
            Log.warning(label: LOG_TAG, "Consent extension is not registered yet, using default collect status (yes)")
            currentCollectConsent = EdgeConstants.Defaults.COLLECT_CONSENT_YES
        } else {
            currentCollectConsent = ConsentStatus.getCollectConsentOrDefault(eventData: consentSharedState?.value ?? [:])
        }

        // update hitQueue based on current collect consent status
        hitQueue.handleCollectConsentChange(status: currentCollectConsent)

        hasBooted = true
        Log.debug(label: LOG_TAG, "Edge has successfully booted up")
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

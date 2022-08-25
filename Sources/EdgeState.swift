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
    private let queue: DispatchQueue
    private var _implementationDetails: [String: Any]?
    private var locationHint: String?
    private var locationHintExpiryDate: Date?
    private(set) var hitQueue: HitQueuing
    private(set) var hasBooted = false
    private(set) var currentCollectConsent: ConsentStatus
    private(set) var implementationDetails: [String: Any]? {
        get { queue.sync { self._implementationDetails } }
        set { queue.async { self._implementationDetails = newValue } }
    }
    private let dataStore = NamedCollectionDataStore(name: EdgeConstants.EXTENSION_NAME)

    /// Creates a new `EdgeState` and initializes the required properties and sets the initial collect consent
    init(hitQueue: HitQueuing) {
        self.queue = DispatchQueue(label: "com.adobe.edgestate.queue")
        self.hitQueue = hitQueue
        self.currentCollectConsent = EdgeConstants.Defaults.COLLECT_CONSENT_PENDING
        hitQueue.handleCollectConsentChange(status: currentCollectConsent)

        // Assigns locationHint and locationHintExpiryDate variables from DataStore
        loadLocationHintFromPersistence()
    }

    /// Completes init for the `Edge` extension and the collect consent is set based on either Consent shared state
    /// or the default value if this extension is not registered
    ///
    /// - Parameters:
    ///   - event: The `Event` triggering the bootup
    ///   - getSharedState: used to fetch the `Event Hub` shared state
    func bootupIfNeeded(event: Event, getSharedState: @escaping (_ name: String, _ event: Event?, _ barrier: Bool) -> SharedStateResult?) {
        guard !hasBooted else { return }

        // Important: set implementationDetails before starting the hit queue so it is available to the EdgeHitProcessor
        let hubSharedState = getSharedState(EdgeConstants.SharedState.Hub.SHARED_OWNER_NAME, event, false)
        implementationDetails = ImplementationDetails.from(hubSharedState?.value)

        // check if consent extension is registered
        var consentRegistered = false
        if let registeredExtensionsWithHub = hubSharedState?.value,
           let extensions = registeredExtensionsWithHub[EdgeConstants.SharedState.Hub.EXTENSIONS] as? [String: Any],
           extensions[EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME] as? [String: Any] != nil {
            consentRegistered = true
        }

        if !consentRegistered {
            Log.warning(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Consent extension is not registered yet, using default collect status (yes)")
            updateCurrentConsent(status: EdgeConstants.Defaults.COLLECT_CONSENT_YES)
        }
        // else keep consent pending until the consent preferences update event is received

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

    /// Get the current Edge Network location hint. May return `nil` if the hint has expired or is not set.
    /// - Returns: the Edge Network location hint or nil if expired or not set
    func getLocationHint() -> String? {
        queue.sync {
            if let expiryDate = self.locationHintExpiryDate, expiryDate > Date() {
                return self.locationHint
            }
            return nil
        }
    }

    /// Update the Edge Network location hint and persist the new hint to the data store. If the new location hint is different from the previous, then a shared state
    /// is also created with the new location hint value.
    /// - Parameters:
    ///   - hint: the Edge Network location hint to set
    ///   - ttlSeconds: the time-to-live in seconds for the given location hint
    ///   - createSharedState: function which creates a shared state with the Event Hub
    func setLocationHint(hint: String, ttlSeconds: TimeInterval, createSharedState: @escaping (_ data: [String: Any], _ event: Event?) -> Void) {
        queue.async {
            let needsStateUpdate = self.locationHint != hint
            let newExpiryDate = Date() + ttlSeconds

            self.locationHint = hint
            self.locationHintExpiryDate = newExpiryDate

            self.persistLocationHint(hint: hint, expiryDate: newExpiryDate)

            if needsStateUpdate {
                // Create shared state if location hint changed
                // Important - Using nil Event here which creates a shared state at the next available Event number.
                //             An extension should NOT mix creating shared states using nil and using received events
                //             as it can cause shared state generation to fail due to received events having potentially
                //             lower event numbers than states using nil. If this extension later needs to create shared
                //             states from received events, then this code must be refactored to also use received
                //             events as the state version.
                createSharedState([EdgeConstants.SharedState.Edge.LOCATION_HINT: hint], nil)
            }
        }
    }

    /// Clears the Edge Network location hint from memory and persistent storage. If the previous location hint was set, then shared state is also created
    /// which clears the location hint value.
    /// - Parameter createSharedState: function which creates a shared state with the Event Hub
    func clearLocationHint(createSharedState: @escaping (_ data: [String: Any], _ event: Event?) -> Void) {
        queue.async {
            if self.locationHint != nil {
                // Create empty shared state to "clear" location hint
                createSharedState([:], nil)
            }

            self.locationHint = nil
            self.locationHintExpiryDate = nil
            self.persistLocationHint(hint: nil, expiryDate: nil)
        }
    }

    /// Store a location hint to local persistent storage. Passing a nil `hint` will remove the location hint from persistent storage.
    /// Passing a nil `expiryDate` while passing a non-nil `hint` will result in no changes to persistent storage (a no-op).
    /// Note, operation is not atomic and is not thread-safe. It is expected that no other thread is accessing the location hint and expiry date when this function is called.
    /// - Parameters:
    ///   - hint: the Edge Network location hint to persist. A value of nil will remove the location hint from persistence.
    ///   - expiryDate: the expiry `Date` for the location hint to persist.
    private func persistLocationHint(hint: String?, expiryDate: Date?) {
        if let hint = hint, let expiryDate = expiryDate {
            self.dataStore.setObject(key: EdgeConstants.DataStoreKeys.LOCATION_HINT_EXPIRY_DATE, value: expiryDate)
            self.dataStore.set(key: EdgeConstants.DataStoreKeys.LOCATION_HINT, value: hint)
        } else if hint == nil {
            self.dataStore.remove(key: EdgeConstants.DataStoreKeys.LOCATION_HINT_EXPIRY_DATE)
            self.dataStore.remove(key: EdgeConstants.DataStoreKeys.LOCATION_HINT)
        }
    }

    /// Load the Edge Network location hint from persistence and assign to local instance variables.
    private func loadLocationHintFromPersistence() {
        queue.async {
            self.locationHint = self.dataStore.getString(key: EdgeConstants.DataStoreKeys.LOCATION_HINT)
            self.locationHintExpiryDate = self.dataStore.getObject(key: EdgeConstants.DataStoreKeys.LOCATION_HINT_EXPIRY_DATE, fallback: nil)
        }
    }
}

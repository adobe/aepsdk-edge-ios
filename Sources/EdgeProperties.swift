//
// Copyright 2022 Adobe. All rights reserved.
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

/// Structure to manage properties used by the Edge extension.
struct EdgeProperties: Codable {

    // Edge Network location hint and expiration date. Location hint is invalid after expiry date.
    private var _locationHint: String?
    private(set) var locationHintExpiryDate: Date?

    /// Retrieves the Edge Network location hint. Returns nil if location hit expired or is not set.
    var locationHint: String? {
        if let expiryDate = self.locationHintExpiryDate, expiryDate > Date() {
            return self._locationHint
        }
        return nil
    }

    /// Update the Edge Network location hint and persist the new hint to the data store. If the new location hint is different from the previous, then returns true.
    /// - Parameters:
    ///   - hint: the Edge Network location hint to set
    ///   - ttlSeconds: the time-to-live in seconds for the given location hint
    ///   - Returns: true if the location hint value changed
    mutating func setLocationHint(hint: String, ttlSeconds: TimeInterval) -> Bool {
        // Determine if hint changed. Use "locationHint" here so expiry date is checked
        // As this check can determine if a shared state is created, need to check expiry date to determine if hint
        // changed in cases where state is not shared if hint expired, such as boot up case
        let hasHintChanged = locationHint != hint
        let newExpiryDate = Date() + ttlSeconds

        _locationHint = hint
        locationHintExpiryDate = newExpiryDate

        saveToPersistence()

        return hasHintChanged
    }

    /// Clears the Edge Network location hint from memory and persistent storage. If the previous location hint was set, then returns true.
    /// - Returns: true if a non-nil location hint value was cleared
    mutating func clearLocationHint() -> Bool {
        // Determine if hint changed. Use "_locationHint" here so expiry date is not checked.
        // As this check can determine if a shared state is created, need to check hint regardless of expiry date
        // to create shared state with cleared hint as the shared state doesn't include the ttl or expiry date.
        let hasHintChanged = _locationHint != nil
        _locationHint = nil
        locationHintExpiryDate = nil

        saveToPersistence()

        return hasHintChanged
    }

    /// Loads the fields of this `EdgeProperties` with the values stored in the Edge extension's data store.
    mutating func loadFromPersistence() {
        let dataStore = NamedCollectionDataStore(name: EdgeConstants.EXTENSION_NAME)
        let savedProperties: EdgeProperties? = dataStore.getObject(key: EdgeConstants.DataStoreKeys.EDGE_PROPERTIES)

        if let savedProperties = savedProperties {
            self = savedProperties
        }
    }

    /// Saves this instance of `EdgeProperties` to the Edge extension's data store.
    func saveToPersistence() {
        let dataStore = NamedCollectionDataStore(name: EdgeConstants.EXTENSION_NAME)
        dataStore.setObject(key: EdgeConstants.DataStoreKeys.EDGE_PROPERTIES, value: self)
    }

    /// Returns a dictionary of the fields stored in this `EdgeProperties`.  Fields which have nil values are not included in the resultant dictionary.
    /// The returned dictionary is suitable for sharing in the `EventHub` as a shared state.
    /// - Returns: a dictionary of this `EdgeProperties`
    func toEventData() -> [String: Any] {
        var map: [String: Any] = [:]

        // Use "locationHint", not "_locationHint" so expiry date is checked
        if let hint = locationHint {
            map[EdgeConstants.SharedState.Edge.LOCATION_HINT] = hint
        }

        return map
    }

}

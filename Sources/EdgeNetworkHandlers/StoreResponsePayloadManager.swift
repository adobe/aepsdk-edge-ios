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
import AEPServices
import Foundation

class StoreResponsePayloadManager {
    private let LOG_TAG: String = "StoreResponsePayloadManager"
    private let dataStoreName: String
    private let storePayloadKeyName: String = EdgeConstants.DataStoreKeys.STORE_PAYLOADS

    init(_ storeName: String) {
        dataStoreName = storeName
    }

    /// Reads all the active saved store payloads from the Data Store.
    /// Any store payload that has expired is not included and is evicted from the Data Store.
    /// - Returns: a map of `StoreResponsePayload` objects keyed by `StoreResponsePayload.key`
    func getActiveStores() -> [String: StoreResponsePayload] {
        let dataStore = NamedCollectionDataStore(name: dataStoreName)
        guard let serializedPayloads = dataStore.getDictionary(key: storePayloadKeyName) as? [String: Any] else {
            Log.trace(label: LOG_TAG, "No active store payloads were found in the Data Store.")
            return [:]
        }

        // list of expired payloads to be deleted
        var expiredList: [String] = []

        // list of valid decoded payloads
        var payloads: [String: StoreResponsePayload] = [:]

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        for (_, codedPayload) in serializedPayloads {
            guard let codedPayloadString = codedPayload as? String, let data = codedPayloadString.data(using: .utf8) else {
                Log.debug(label: LOG_TAG, "Failed to convert store response payload string to data.")
                continue
            }

            let storeResponse: StoreResponsePayload
            do {
                storeResponse = try decoder.decode(StoreResponsePayload.self, from: data)
                if storeResponse.isExpired {
                    expiredList.append(storeResponse.payload.key)
                } else {
                    payloads[storeResponse.payload.key] = storeResponse
                }
            } catch {
                Log.debug(label: LOG_TAG, "Failed to decode store response payload, error: \(error.localizedDescription)")
            }
        }

        deleteStoredResponses(keys: expiredList)
        return payloads
    }

    /// Reads all the active saved store payloads from the Data Store and returns them as a list.
    /// Any store payload that has expired is not included and is evicted from the Data Store
    /// - Returns: a list of `StorePayload` objects
    func getActivePayloadList() -> [StorePayload] {
        let storeResponses = getActiveStores()
        var payloads: [StorePayload] = []
        for (_, storeResponse) in storeResponses {
            payloads.append(storeResponse.payload)
        }
        return payloads
    }

    /// Saves a list of `StoreResponsePayload` objects to the Data Store. Payloads with `maxAge <= 0` are deleted.
    /// - Parameter payloads: a list of `StoreResponsePayload` to be saved to the Data Store
    func saveStorePayloads(_ payloads: [StoreResponsePayload]) {
        if payloads.isEmpty {
            return
        }

        let previouslyStoredPayloads = ServiceProvider.shared.namedKeyValueService.get(collectionName: dataStoreName, key: storePayloadKeyName)
        var serializedPayloads: [String: Any] = [:]
        if previouslyStoredPayloads != nil {
            guard let temp = previouslyStoredPayloads as? [String: Any] else {
                Log.debug(label: LOG_TAG, "Failed to decode previously stored payloads, unable to update the client side store")
                return
            }

            serializedPayloads = temp
        }

        // list of expired payloads to be deleted
        var expiredList: [String] = []

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        for storeResponse in payloads {
            // The Experience Edge server (Konductor) defines state values with 0 or -1 max age as to be deleted on the client.
            if storeResponse.payload.maxAge <= 0 {
                expiredList.append(storeResponse.payload.key)
                continue
            }

            do {
                let payloadData = try encoder.encode(storeResponse)
                guard let serializedPayload = String(data: payloadData, encoding: .utf8) else {
                    continue
                }

                serializedPayloads[storeResponse.payload.key] = serializedPayload
            } catch {
                Log.debug(label: LOG_TAG, "Failed to encode store response payload: \(error.localizedDescription)")
                continue
            }
        }

        ServiceProvider.shared.namedKeyValueService.set(collectionName: dataStoreName, key: storePayloadKeyName, value: serializedPayloads)
        deleteStoredResponses(keys: expiredList)
    }

    /// Deletes all the stores from the data store
    func deleteAllStorePayloads() {
        let dataStore = NamedCollectionDataStore(name: dataStoreName)
        dataStore.remove(key: EdgeConstants.DataStoreKeys.STORE_PAYLOADS)
    }

    /// Deletes a list of stores from the data store
    /// - Parameter keys: a list of `StoreResponsePayload.key`
    private func deleteStoredResponses(keys: [String]) {
        let dataStore = NamedCollectionDataStore(name: dataStoreName)
        guard var codedPayloads = dataStore.getDictionary(key: storePayloadKeyName) as? [String: Any] else {
            Log.trace(label: LOG_TAG, "Unable to delete expired payloads. No payloads were found in the data store.")
            return
        }

        for key in keys {
            codedPayloads.removeValue(forKey: key)
        }

        ServiceProvider.shared.namedKeyValueService.set(collectionName: dataStoreName, key: storePayloadKeyName, value: codedPayloads)
    }
}

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

import Foundation
import ACPCore

class StoreResponsePayloadManager {
    private let TAG: String = "StoreResponsePayloadManager"
    private let dataStore: KeyValueStore
    private let storePayloadKeyName: String = ExperiencePlatformConstants.DataStoreKeys.storePayloads
    
    init(_ store: KeyValueStore) {
        dataStore = store
    }
    
    /// Reads all the active saved store payloads from the data store.
    /// Any store payload that has expired is not included and is evicted from the data store.
    /// - Returns: a map of `StoreResponsePayload` objects keyed by `StoreResponsePayload.key`
    func getActiveStores() -> [String : StoreResponsePayload] {
        
        guard let serializedPayloads = dataStore.getDictionary(key: storePayloadKeyName, fallback: nil) else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Unable to retrieve active payloads. No payloads were found in the data store.")
            return [:]
        }
        
        // list of expired payloads to be deleted
        var expiredList: [String] = []
        
        // list of valid decoded payloads
        var payloads: [String : StoreResponsePayload] = [:]
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for (_, codedPayload) in serializedPayloads {
            
            guard let data = codedPayload.data(using: .utf8) else {
                ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Failed to convert store response payload string to data.")
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
                ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Failed to decode store response payload with: \(error.localizedDescription)")
            }
        }
        
        deleteStoredResponses(keys: expiredList)
        return payloads
    }
    
    /// Reads all the active saved store payloads from the data store and returns them as a list.
    /// Any store payload that has expired is not included and is evicted from the data store
    /// - Returns: a list of `StorePayload` objects
    func getActivePayloadList() -> [StorePayload] {
        let storeResponses = getActiveStores()
        var payloads: [StorePayload] = []
        for (_, storeResponse) in storeResponses {
            payloads.append(storeResponse.payload)
        }
        return payloads
    }
    
    /// Saves a list of `StoreResponsePayload` objects to the data store. Payloads with `maxAge <= 0` are deleted.
    /// - Parameter payloads: a list of `StoreResponsePayload` to be saved to the data store
    func saveStorePayloads(_ payloads: [StoreResponsePayload]) {
        if payloads.isEmpty {
            return
        }
        
        guard var serializedPayloads = dataStore.getDictionary(key: storePayloadKeyName, fallback: [:]) else {
            return
        }
        
        // list of expired payloads to be deleted
        var expiredList: [String] = []
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        for storeResponse in payloads {
            // The Experience Edge server (Konductor) defines state values with 0 or -1 max age as to be deleted on the client.
            if (storeResponse.payload.maxAge <= 0) {
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
                ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Failed to encode store response payload: \(error.localizedDescription)")
                continue
            }
        }
        
        dataStore.setDictionary(key: storePayloadKeyName, value: serializedPayloads)
        deleteStoredResponses(keys: expiredList)
        
    }
    
    /// Deletes a list of stores from the data store
    /// - Parameter keys: a list of `StoreResponsePayload.key`
    private func deleteStoredResponses(keys: [String]) {
        guard var codedPayloads = dataStore.getDictionary(key: storePayloadKeyName, fallback: nil) else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Unable to delete expired payloads. No payloads were found in the data store.")
            return
        }
        
        for key in keys {
            codedPayloads.removeValue(forKey: key)
        }
        
        dataStore.setDictionary(key: storePayloadKeyName, value: codedPayloads)
    }
}

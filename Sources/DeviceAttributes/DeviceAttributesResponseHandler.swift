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

import AEPCore
import AEPServices
import Foundation

/// Handles the plain JSON success response of the `mobile/device-attributes` endpoint:
/// `{"requestId": "...", "handle": [{"type": "...", "payload": [...]}]}`.
/// Only `locationHint:result` (scope `EdgeNetwork`) and `state:store` handles are applied; no events are dispatched.
class DeviceAttributesResponseHandler {
    private let SELF_TAG = "DeviceAttributesResponseHandler"
    private let updateLocationHint: (String, TimeInterval) -> Void
    private let storeResponsePayloadManager: StoreResponsePayloadManager

    /// - Parameters:
    ///   - dataStoreName: data store holding the `state:store` payloads
    ///   - updateLocationHint: sets the Edge Network location hint and its TTL in seconds
    init(dataStoreName: String = EdgeConstants.DataStoreKeys.STORE_NAME,
         updateLocationHint: @escaping (String, TimeInterval) -> Void) {
        self.storeResponsePayloadManager = StoreResponsePayloadManager(dataStoreName)
        self.updateLocationHint = updateLocationHint
    }

    /// Parses `responseBody` and applies the supported handles.
    /// - Parameters:
    ///   - responseBody: plain JSON response body
    ///   - applyStorePayloads: false to ignore `state:store` handles (the ECID changed while the request was in flight)
    func handle(responseBody: String?, applyStorePayloads: Bool) {
        typealias Keys = EdgeConstants.DeviceAttributes.ResponseKeys
        guard let responseBody = responseBody, !responseBody.isEmpty else {
            Log.trace(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Device attributes response has no content.")
            return
        }
        guard let json = try? JSONSerialization.jsonObject(with: Data(responseBody.utf8)) as? [String: Any] else {
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Unable to parse device attributes response: \(responseBody)")
            return
        }
        guard let handles = json[Keys.HANDLE] as? [[String: Any]] else { return }

        for handle in handles {
            guard let type = handle[Keys.TYPE] as? String,
                  let payload = handle[Keys.PAYLOAD] as? [[String: Any]] else { continue }

            switch type {
            case EdgeConstants.JsonKeys.Response.EventHandleType.LOCATION_HINT:
                handleLocationHint(payload: payload)
            case EdgeConstants.JsonKeys.Response.EventHandleType.STORE:
                if applyStorePayloads {
                    handleStorePayloads(payload: payload)
                } else {
                    Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - ECID changed during the request, ignoring state:store handle.")
                }
            default:
                continue
            }
        }
    }

    /// Applies the first `EdgeNetwork` scoped location hint, mirroring `NetworkResponseHandler`.
    private func handleLocationHint(payload: [[String: Any]]) {
        typealias Keys = EdgeConstants.JsonKeys.Response.LocationHint
        for locationHint in payload {
            guard let scope = locationHint[Keys.SCOPE] as? String, scope == EdgeConstants.DeviceAttributes.EDGE_NETWORK_SCOPE else { continue }
            if let hint = locationHint[Keys.HINT] as? String, !hint.isEmpty,
               let ttlSeconds = locationHint[Keys.TTL_SECONDS] as? Int {
                updateLocationHint(hint, TimeInterval(ttlSeconds))
            }
            break
        }
    }

    /// Persists `state:store` payloads, mirroring `NetworkResponseHandler`.
    private func handleStorePayloads(payload: [[String: Any]]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        var storeResponsePayloads: [StoreResponsePayload] = []
        for storeElement in payload {
            if let storeElementAnyCodable = AnyCodable.from(dictionary: storeElement),
               let data = try? encoder.encode(storeElementAnyCodable),
               let storePayload = try? decoder.decode(StorePayload.self, from: data) {
                storeResponsePayloads.append(StoreResponsePayload(payload: storePayload))
            }
        }

        storeResponsePayloadManager.saveStorePayloads(storeResponsePayloads)
        if !storeResponsePayloads.isEmpty {
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Processed \(storeResponsePayloads.count) store response payload(s).")
        }
    }
}

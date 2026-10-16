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
/// Only `state:store` handles are applied; other handles (including location hints) are ignored and no events are dispatched.
class DeviceAttributesResponseHandler {
    private let SELF_TAG = "DeviceAttributesResponseHandler"
    private let storeResponsePayloadManager: StoreResponsePayloadManager

    /// - Parameter dataStoreName: data store holding the `state:store` payloads
    init(dataStoreName: String = EdgeConstants.DataStoreKeys.STORE_NAME) {
        self.storeResponsePayloadManager = StoreResponsePayloadManager(dataStoreName)
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
            guard let type = handle[Keys.TYPE] as? String, type == EdgeConstants.JsonKeys.Response.EventHandleType.STORE,
                  let payload = handle[Keys.PAYLOAD] as? [[String: Any]] else { continue }
            if applyStorePayloads {
                handleStorePayloads(payload: payload)
            } else {
                Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - ECID changed during the request, ignoring state:store handle.")
            }
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

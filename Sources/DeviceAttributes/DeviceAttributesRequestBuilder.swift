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

/// Builds the flat request body for the `mobile/device-attributes` endpoint.
/// Producer data (e.g. `app`, `tokens`, `timezone`) is passed through as-is; the SDK owns `xdm` and `meta`.
class DeviceAttributesRequestBuilder {
    private let SELF_TAG = "DeviceAttributesRequestBuilder"

    /// Read-only access to stored `state:store` payloads used for `meta.state`.
    private let storeResponsePayloadManager: StoreResponsePayloadManager

    init(dataStoreName: String = EdgeConstants.DataStoreKeys.STORE_NAME) {
        storeResponsePayloadManager = StoreResponsePayloadManager(dataStoreName)
    }

    /// Builds the device-attributes request body. Producer-supplied `xdm` and `meta` are ignored.
    /// The SDK adds `xdm` (implementationDetails + identityMap) and `meta.state` when available.
    /// - Parameters:
    ///   - eventData: the request event (E3) data forming the base of the request body
    ///   - implementationDetails: the SDK `implementationDetails` to attach under `xdm`
    ///   - identityMap: the identity map to attach under `xdm`
    /// - Returns: the request body, or nil if there is nothing to send
    func buildPayload(eventData: [String: Any]?,
                      implementationDetails: [String: Any]?,
                      identityMap: [String: Any]?) -> [String: AnyCodable]? {
        guard let data = eventData, !data.isEmpty else { return nil }

        let producerData = data.filter { $0.key != EdgeConstants.JsonKeys.XDM && $0.key != EdgeConstants.JsonKeys.META }
        if producerData.count != data.count {
            Log.warning(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Ignoring producer-supplied SDK-owned xdm/meta fields for device attributes.")
        }
        var payload: [String: AnyCodable] = AnyCodable.from(dictionary: producerData) ?? [:]

        var xdm = [String: Any]()
        if let implementationDetails = implementationDetails {
            xdm[EdgeConstants.JsonKeys.IMPLEMENTATION_DETAILS] = implementationDetails
        }
        if let identityMap = identityMap {
            xdm[EdgeConstants.SharedState.Identity.IDENTITY_MAP] = identityMap
        }
        if !xdm.isEmpty {
            payload[EdgeConstants.JsonKeys.XDM] = AnyCodable(xdm)
        }

        // meta.state uses the same StateMetadata shape sent to the interact endpoint (entries include maxAge).
        let storedPayloads = storeResponsePayloadManager.getActivePayloadList()
        if !storedPayloads.isEmpty,
           let stateData = try? JSONEncoder().encode(StateMetadata(payload: storedPayloads)),
           let stateDict = try? JSONSerialization.jsonObject(with: stateData) as? [String: Any] {
            payload[EdgeConstants.JsonKeys.META] = AnyCodable(["state": stateDict])
        }

        return payload.isEmpty ? nil : payload
    }

    /// Builds the device-attributes request body and encodes it as compact JSON.
    /// - Returns: the JSON request body, or nil if there is nothing to send or encoding fails
    func buildRequestBody(eventData: [String: Any]?,
                          implementationDetails: [String: Any]?,
                          identityMap: [String: Any]?) -> String? {
        guard let payload = buildPayload(eventData: eventData,
                                         implementationDetails: implementationDetails,
                                         identityMap: identityMap),
              let data = try? JSONEncoder().encode(payload) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

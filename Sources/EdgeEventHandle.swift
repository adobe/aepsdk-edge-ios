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

import AEPServices
import Foundation

/// The `EdgeEventHandle` is a response fragment from Adobe Experience Edge Service for a sent XDM Experience Event.
/// One event can receive none, one or multiple `EdgeEventHandle`(s) as response.
@objc(AEPEdgeEventHandle)
public class EdgeEventHandle: NSObject, Codable {

    /// Encodes the event to which this handle is attached as the index in the events array in EdgeRequest
    internal let eventIndex: Int?

    /// Payload type
    @objc public let type: String?

    /// Event payload values
    @objc public let payload: [[String: Any]]?

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case eventIndex
        case type
        case payload
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        eventIndex = try values.decodeIfPresent(Int.self, forKey: .eventIndex)
        type = try values.decodeIfPresent(String.self, forKey: .type)

        var tempPayload: [[String: Any]] = []
        if let anyCodablePayload = try? values.decodeIfPresent([[String: AnyCodable]].self, forKey: .payload) {
            for item in anyCodablePayload {
                if let itemAnyDictionary = AnyCodable.toAnyDictionary(dictionary: item) {
                    tempPayload.append(itemAnyDictionary)
                }
            }
        }

        payload = tempPayload.isEmpty ? nil : tempPayload
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // skip eventIndex when encoding

        try container.encodeIfPresent(type, forKey: .type)

        if let unwrappedPayload = payload {
            var tempPayload: [[String: AnyCodable]] = []
            for item in unwrappedPayload {
                if let itemAnyCodableDictionary = AnyCodable.from(dictionary: item) {
                    tempPayload.append(itemAnyCodableDictionary)
                }
            }

            try container.encodeIfPresent(tempPayload, forKey: .payload)
        }
    }
}

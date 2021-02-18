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

/// Property that holds the global XDM context data within an `EdgeRequest` object.
/// It is contained within the `EdgeRequest` request property.
struct RequestContextData: Encodable {
    var xdmPayloads: [[String: AnyCodable]] = []

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        for payload in xdmPayloads {
            guard let firstKey = payload.keys.first, let nestedPayload = payload[firstKey] else { continue }
            guard let dynamicKey = DynamicKey(stringValue: firstKey) else { continue }
            try container.encodeIfPresent(nestedPayload, forKey: dynamicKey)
        }
    }
}

// Helper struct to encode payloads dynamically
private struct DynamicKey: CodingKey {

    var stringValue: String

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int? { return nil }

    init?(intValue: Int) { return nil }
}

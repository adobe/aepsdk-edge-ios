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

import Foundation

struct MobileLifecycleDetails: XDMDirectMappable {
    init() {}

    var application: Application?
    var device: Device?
    var environment: Environment?
    let eventType = "application.lifecycle"
    var timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case application
        case device
        case environment
        case eventType
        case timestamp
    }

    // MARK: XDMDirectMappable

    static func fromDirect(data: [String: Any]) -> XDMDirectMappable? {
        var lifecycleDetails = MobileLifecycleDetails()
        lifecycleDetails.application = Application.fromDirect(data: data) as? Application
        lifecycleDetails.device = Device.fromDirect(data: data) as? Device
        lifecycleDetails.environment = Environment.fromDirect(data: data) as? Environment

        // TODO: AMSDK-9271 Set timestamp when we receive the lifecycle event

        return lifecycleDetails
    }
}

extension MobileLifecycleDetails: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = application { try container.encode(unwrapped, forKey: .application) }
        if let unwrapped = device { try container.encode(unwrapped, forKey: .device) }
        if let unwrapped = environment { try container.encode(unwrapped, forKey: .environment) }
        try container.encode(eventType, forKey: .eventType)
        if let unwrapped = XDMFormatters.dateToISO8601String(from: timestamp) { try container.encode(unwrapped, forKey: .timestamp) }
    }
}

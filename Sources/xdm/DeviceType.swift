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

import AEPServices
import Foundation

enum DeviceType: String, Encodable {
    case mobile = "mobile"
    case tablet = "tablet"
    case desktop = "desktop"
    case tvScreens = "tv screens"

    /// Creates a new `DeviceType` from the already known `AEPServices.DeviceType`
    /// - Parameter servicesDeviceType: a `AEPServices.DeviceType` value
    /// - Returns: The `servicesDeviceType` mapped to an `AEPEdge.DeviceType`, nil if no mappings found
    static func from(servicesDeviceType: AEPServices.DeviceType) -> DeviceType? {
        switch servicesDeviceType {
        case .PHONE:
            return .mobile
        case .PAD:
            return .tablet
        case .TV:
            return .tvScreens
        default:
            return nil
        }
    }
}

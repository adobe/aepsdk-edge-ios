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

struct Device {
    init() {}

    var manufacturer: String?
    var model: String?
    var modelNumber: String?
    var screenHeight: Int64?
    var screenOrientation: ScreenOrientation?
    var screenWidth: Int64?
    var type: DeviceType?

    enum CodingKeys: String, CodingKey {
        case manufacturer
        case model
        case modelNumber
        case screenHeight
        case screenOrientation
        case screenWidth
        case type
    }
}

extension Device: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = manufacturer { try container.encode(unwrapped, forKey: .manufacturer) }
        if let unwrapped = model { try container.encode(unwrapped, forKey: .model) }
        if let unwrapped = modelNumber { try container.encode(unwrapped, forKey: .modelNumber) }
        if let unwrapped = screenHeight { try container.encode(unwrapped, forKey: .screenHeight) }
        if let unwrapped = screenOrientation { try container.encode(unwrapped, forKey: .screenOrientation) }
        if let unwrapped = screenWidth { try container.encode(unwrapped, forKey: .screenWidth) }
        if let unwrapped = type { try container.encode(unwrapped, forKey: .type) }
    }
}

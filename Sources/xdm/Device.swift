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

struct Device: Encodable, XDMDirectMappable {
    init() {}

    var manufacturer: String?
    var model: String?
    var modelNumber: String?
    var screenHeight: Int64?
    var screenOrientation: ScreenOrientation?
    var screenWidth: Int64?
    var type: DeviceType?

    static func fromDirect(data: [String: Any]) -> XDMDirectMappable? {
        var device = Device()
        let systemInfoService = ServiceProvider.shared.systemInfoService
        device.manufacturer = "apple"
        device.model = systemInfoService.getDeviceName()
//        device.modelNumber = systemInfoService.getDeviceBuildId() uncomment once new API is merged
        let (width, height) = systemInfoService.getDisplayInformation()
        device.screenWidth = Int64(width)
        device.screenHeight = Int64(height)
        device.screenOrientation = ScreenOrientation.from(deviceOrientation: systemInfoService.getCurrentOrientation())
        device.type = DeviceType.from(servicesDeviceType: systemInfoService.getDeviceType())

        return device
    }
}

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

struct Environment: Encodable, XDMDirectMappable {
    init() {}

    var carrier: String?
    // Connection type not supported in iOS
    var language: String?
    var operatingSystemVendor: String?
    var operatingSystem: String?
    var operatingSystemVersion: String?
    var type: EnvironmentType?

    static func fromDirect(data: [String: Any]) -> XDMDirectMappable? {
        var env = Environment()

        let systemInfoService = ServiceProvider.shared.systemInfoService
        env.carrier = systemInfoService.getMobileCarrierName()
        env.operatingSystemVendor = systemInfoService.getCanonicalPlatformName()
        env.operatingSystem = systemInfoService.getOperatingSystemName()
        env.operatingSystemVersion = systemInfoService.getOperatingSystemVersion()

        if let lifecycleContextData = data[EdgeConstants.SharedState.Lifecycle.CONTEXT_DATA] as? [String: Any] {
            env.type = EnvironmentType.from(runMode: lifecycleContextData[EdgeConstants.SharedState.Lifecycle.ContextData.RUN_MODE] as? String)
            env.language = lifecycleContextData[EdgeConstants.SharedState.Lifecycle.ContextData.LOCALE] as? String
        }

        return env
    }
}

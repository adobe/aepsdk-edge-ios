//
// Copyright 2023 Adobe. All rights reserved.
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

struct TestEnvironment {
    /// Retrieves the value of an environment variable by its key.
    ///
    /// - Parameter keyName: The key for which the environment variable's value is retrieved.
    /// - Returns: The value of the environment variable if it exists, or `nil` if not found.
    static func environmentVariable(forKey keyName: String) -> String? {
        return ProcessInfo.processInfo.environment[keyName]
    }

    /// Retrieves the Edge location hint from the shell environment.
    ///
    /// - Returns: The Edge location hint if set in the environment, or `nil` if not set.
    static var defaultLocationHint: String? {
        guard let locationHint = environmentVariable(forKey: IntegrationTestConstants.EnvironmentKeys.EDGE_LOCATION_HINT) else {
            return nil
        }
        switch locationHint {
        case IntegrationTestConstants.LocationHintSpecialCases.EMPTY_STRING:
            return ""
        case IntegrationTestConstants.LocationHintSpecialCases.INVALID:
            return locationHint
        case IntegrationTestConstants.LocationHintSpecialCases.NONE:
            return nil
        default:
            return locationHint
        }
    }

    /// Retrieves the mobile property ID from the shell environment.
    ///
    /// - Returns: The mobile property ID if set in the environment, or a default value if not set.
    static var defaultMobilePropertyId: String {
        let mobilePropertyId = environmentVariable(forKey: IntegrationTestConstants.EnvironmentKeys.MOBILE_PROPERTY_ID) ?? IntegrationTestConstants.MobilePropertyId.PROD
        return mobilePropertyId
    }
}

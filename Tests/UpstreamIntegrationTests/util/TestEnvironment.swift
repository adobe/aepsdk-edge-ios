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
        // Note: Remember to update Scheme -> Test -> Arguments to pull in the environment variables
        // and make them accessible here. The default value for keys if not set is the empty string `""`.
        return ProcessInfo.processInfo.environment[keyName]
    }

    /// Retrieves the Edge location hint from the shell environment.
    ///
    /// - Returns: The Edge location hint if set in the environment, or `""` if not set.
    static var defaultLocationHint: String? {
        guard let locationHint = environmentVariable(forKey: IntegrationTestConstants.EnvironmentKey.EDGE_LOCATION_HINT)?.trimmingCharacters(in: .whitespacesAndNewlines), !locationHint.isEmpty else {
            return nil
        }
        switch locationHint {
        case IntegrationTestConstants.LocationHintMapping.NONE:
            return nil
        case IntegrationTestConstants.LocationHintMapping.EMPTY_STRING:
            return ""
        default:
            return locationHint
        }
    }

    /// Retrieves the tags mobile property ID from the shell environment.
    ///
    /// - Returns: The tags mobile property ID if set in the environment, or a default value if not set.
    static var defaultTagsMobilePropertyId: String {
        guard let tagsMobilePropertyId = environmentVariable(forKey: IntegrationTestConstants.EnvironmentKey.TAGS_MOBILE_PROPERTY_ID), !tagsMobilePropertyId.isEmpty else {
            return IntegrationTestConstants.TagsMobilePropertyId.PROD
        }
        return tagsMobilePropertyId
    }
}

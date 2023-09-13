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

/// Edge Network environment levels that correspond to actual deployment environment levels
enum EdgeEnvironment: String {
    /// Production
    case prod
    /// Pre-production - aka: staging
    case preProd = "pre-prod"
    /// Integration - aka: development
    case int

    /// Initializer that gets the value from the environment variable `EDGE_ENVIRONMENT` and creates an `EdgeEnvironment` instance.
    init() {
        guard let edgeEnvironment = extractEnvironmentVariable(keyName: "EDGE_ENVIRONMENT", enum: EdgeEnvironment.self) else {
            self = .prod
            return
        }
        self = edgeEnvironment
    }
}

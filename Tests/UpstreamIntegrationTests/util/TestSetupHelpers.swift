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

/// Extracts Edge location hint from shell environment. If nothing is set the default value `nil` is returned
 func getLocationHint() -> EdgeLocationHint? {
    let edgeLocationHint = EdgeLocationHint()
    return edgeLocationHint
}

/// Extracts Edge enviroment from shell environment. If nothing is set the default value `prod` is returned
func getEdgeEnvironment() -> EdgeEnvironment {
    let edgeEnvironment = EdgeEnvironment()
    print("Using Edge Network environment: \(edgeEnvironment.rawValue)")

    return edgeEnvironment
}

/// Returns Tags environment file ID based on the environment
/// - Parameter edgeEnvironment:Edge Network environment levels that correspond to actual deployment environment levels
/// - Returns: A environment file ID string
func getTagsEnvironmentFileId(for edgeEnvironment: EdgeEnvironment) -> String {
    switch edgeEnvironment {
    case .prod:
        return "94f571f308d5/6b1be84da76a/launch-023a1b64f561-development"
    case .preProd:
        return "94f571f308d5/6b1be84da76a/launch-023a1b64f561-development"
    case .int:
        // TODO: create integration environment environment file ID
        return "94f571f308d5/6b1be84da76a/launch-023a1b64f561-development"
    }
}

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

import AEPCore
import AEPServices
import Foundation

enum ImplementationDetails {
    static func from(_ hubState: [String: Any]?) -> [String: Any] {
        let coreVersion = hubState?[EdgeConstants.SharedState.Hub.VERSION] as? String
        let wrapperType = (hubState?[EdgeConstants.SharedState.Hub.WRAPPER] as? [String: Any])?[EdgeConstants.SharedState.Hub.TYPE] as? String
        var wrapperName: String

        switch wrapperType {
        case "R":
            wrapperName = "/\(EdgeConstants.JsonValues.ImplementationDetails.WRAPPER_REACT_NATIVE)" // note forward slash
        default:
            wrapperName = ""
        }

        return [
            EdgeConstants.JsonKeys.ImplementationDetails.VERSION: "\(coreVersion ?? "")+\(EdgeConstants.EXTENSION_VERSION)",
            EdgeConstants.JsonKeys.ImplementationDetails.NAME: "\(EdgeConstants.JsonValues.ImplementationDetails.BASE_NAMESPACE)\(wrapperName)",
            EdgeConstants.JsonKeys.ImplementationDetails.ENVIRONMENT: EdgeConstants.JsonValues.ImplementationDetails.ENVIRONMENT_APP
        ]
    }
}

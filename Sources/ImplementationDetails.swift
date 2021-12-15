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
import Foundation

enum ImplementationDetails {

    /// Builds and returns the Implementation Details for the current session. Parses the given `hubState` to retrieve the Mobile Core version and wrapper type.
    /// If no Mobile Core version is found in `hubState`, then "unknown" is used.
    /// If the Mobile Core "wrapper" exists but the "type" cannot be parsed, then "unknown" is used for the wrapper type.
    /// If the "wrapper" does not exist in `hubState`, or the found wrapper type is not supported, then the default `WrapperType.None` is used.
    ///
    /// - Parameter hubState: `EventHub` shared state`
    /// - Returns: the implementation details for current session, or nil if `hubState` is nil or empty
    static func from(_ hubState: [String: Any]?) -> [String: Any]? {
        guard let hubState = hubState, !hubState.isEmpty else {
            return nil
        }

        // if core version is not found set to "unknown"
        let coreVersion: String = hubState[EdgeConstants.SharedState.Hub.VERSION] as? String ?? EdgeConstants.JsonValues.ImplementationDetails.UNKNOWN

        var wrapperName: String = getWrapperName(from: hubState)
        if !wrapperName.isEmpty {
            wrapperName = "/\(wrapperName)"
        }

        return [
            EdgeConstants.JsonKeys.ImplementationDetails.VERSION: "\(coreVersion)+\(EdgeConstants.EXTENSION_VERSION)",
            EdgeConstants.JsonKeys.ImplementationDetails.NAME: "\(EdgeConstants.JsonValues.ImplementationDetails.BASE_NAMESPACE)\(wrapperName)",
            EdgeConstants.JsonKeys.ImplementationDetails.ENVIRONMENT: EdgeConstants.JsonValues.ImplementationDetails.ENVIRONMENT_APP
        ]
    }

    /// Get the wrapper named used for the Implementation Details namespace from the Event Hub shared state.
    ///
    /// - Parameter hubState: `EventHub` shared state
    /// - Returns: wrapper type name used in the Implementation Details namespace, or an empty string if no wrapper is set
    private static func getWrapperName(from hubState: [String: Any]) -> String {
        if hubState[EdgeConstants.SharedState.Hub.WRAPPER] != nil {
            let typeString = (hubState[EdgeConstants.SharedState.Hub.WRAPPER] as? [String: Any])?[EdgeConstants.SharedState.Hub.TYPE] as? String
            if let wrapperTypeString = typeString, let wrapperType = WrapperType.init(rawValue: wrapperTypeString) {
                return wrapperType == .none ? "" : wrapperType.stringValue
            } else {
                // "wrapper" entry exists but "type" not found. Unexpected, set to "unknown"
                return EdgeConstants.JsonValues.ImplementationDetails.UNKNOWN
            }
        }

        return "" // No "wrapper" object in shared state, default to none
    }
}

extension WrapperType {
    var stringValue: String {
        switch self {
        case .none:
            return ""
        case .reactNative:
            return EdgeConstants.JsonValues.ImplementationDetails.WRAPPER_REACT_NATIVE
        case .flutter:
            return EdgeConstants.JsonValues.ImplementationDetails.WRAPPER_FLUTTER
        case .cordova:
            return EdgeConstants.JsonValues.ImplementationDetails.WRAPPER_CORDOVA
        case .unity:
            return EdgeConstants.JsonValues.ImplementationDetails.WRAPPER_UNITY
        case .xamarin:
            return EdgeConstants.JsonValues.ImplementationDetails.WRAPPER_XAMARIN
        default:
            return EdgeConstants.JsonValues.ImplementationDetails.UNKNOWN
        }
    }
}

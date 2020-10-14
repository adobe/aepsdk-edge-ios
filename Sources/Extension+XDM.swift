//
// Copyright 2020 Adobe. All rights reserved.
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
import AEPCore

/// Provides functionality for setting and reading XDM shared state
public extension Extension {
    
    /// Appends `data` to the XDM shared state, if any of the keys in `data` map to existing keys in the XDM shared state, those values will be updated with the values in `data`.
    /// - Parameter data: Data to be appended to XDM shared state
    func createXDMSharedState(data: [String: Any]) {
        let existingXDMSharedState = getXDMSharedState()?.value ?? [:]
        // add the new shared state on-top of existing shared state
        let newXDMSharedState = existingXDMSharedState.merging(data) { (_, new) in new }
        createSharedState(data: newXDMSharedState, event: nil) // always version at latest, shared state is published to "com.adobe.edge"
    }
    
    /// Reads and returns the XDM shared state
    /// - Returns: The XDM shared state
    func getXDMSharedState() -> SharedStateResult? {
        return getSharedState(extensionName: Constants.EXTENSION_NAME, event: nil)
    }
}

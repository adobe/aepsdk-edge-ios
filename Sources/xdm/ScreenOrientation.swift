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

enum ScreenOrientation: String, Encodable {
    case portrait
    case landscape

    /// Creates a `ScreenOrientation` from a `DeviceOrientation`
    /// - Parameter deviceOrientation: a `DeviceOrientation`
    /// - Returns: The `ScreenOrientation` corresponding to the `DeviceOrientation`, nil if no match found
    static func from(deviceOrientation: DeviceOrientation) -> ScreenOrientation? {
        switch deviceOrientation {
        case .PORTRAIT:
            return .portrait
        case .LANDSCAPE:
            return .landscape
        default:
            return nil
        }
    }
}

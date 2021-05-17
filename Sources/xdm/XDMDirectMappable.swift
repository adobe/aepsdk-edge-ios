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

import Foundation

/// Represents a type that can take data in the form from a direct solution and map to XDM data
protocol XDMDirectMappable {

    /// Creates a new `XDMDirectMappable` which is represented in the direct data
    /// - Parameter data: The newly created `XDMDirectMappable`, nil if creation fails
    static func fromDirect(data: [String: Any]) -> XDMDirectMappable?
}

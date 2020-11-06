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

import AEPCore
import Foundation

/// Struct which represents an Identity hit
struct EdgeHit: Codable {
    /// URL to be requested for this Edge hit
    let url: URL

    /// The `EdgeRequest` for the corresponding hit
    let request: EdgeRequest
    
    /// Request headers for this `EdgeHit`
    let headers: [String: String]
    
    /// The `Event` associated with the `EdgeHit`
    let event: Event
}

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

import AEPServices
import Foundation

/// A request for pushing events to the Adobe Experience Edge.
/// An `EdgeRequest` is the top-level request object sent to Experience Edge.
struct EdgeRequest: Encodable {
    /// Metadata passed to the Experience Cloud Solutions and even to the Edge itself with possibility of overriding at event level
    let meta: RequestMetadata?

    /// XDM data applied for the entire request
    let xdm: [String: AnyCodable]?

    /// List of Experience events
    let events: [[String: AnyCodable]]?
}

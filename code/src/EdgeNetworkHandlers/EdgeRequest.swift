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

/// A request for pushing events to the Adobe Data Platform.
/// An `EdgeRequest` is the top-level request object sent to Konductor.
struct EdgeRequest: Encodable {
    /// Metadata passed to solutions and even to Konductor itself with possiblity of overriding at event level
    let meta: RequestMetadata?

    /// XDM context data for the entire request
    let xdm: RequestContextData?

    /// List of Experience events
    let events: [[String: AnyCodable]]?
}

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

/// A request for sending a consent update to the Adobe Experience Edge.
/// An `EdgeConsentUpdate` is the top-level request object sent to Experience Edge to the set-consent endpoint.
struct EdgeConsentUpdate: Encodable {
    /// Metadata passed with the Consent request
    let meta: RequestMetadata?

    /// Additional query options that specify the consent operation type
    let query: QueryOptions?

    /// The IdentityMap at the moment of this request
    let identityMap: [String: AnyCodable]?

    /// Consent payload
    let consent: [EdgeConsentPayload]?

}

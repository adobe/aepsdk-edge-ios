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

/// Represents all the known endpoints for the Edge Network
enum EdgeEndpoint: String {
    /// The production Edge Network endpoint
    case production = "prod"

    /// The pre-production Edge Network endpoint
    case preProduction = "pre-prod"

    /// The integration Edge Network endpoint
    case integration = "int"

    /// Initializes the appropriate `EdgeEndpoint` enum for the given `optionalRawValue`
    /// - Parameter optionalRawValue: a `RawValue` representation of a `EdgeEndpoint` enum, default is `production`
    init(optionalRawValue: RawValue?) {
        guard let rawValue = optionalRawValue,
              let validEndpoint = EdgeEndpoint(rawValue: rawValue) else {
            self = EdgeConstants.Defaults.DEFAULT_ENDPOINT
            return
        }

        self = validEndpoint
    }

    /// Computes the endpoint URL based on this
    var endpointUrl: String {
        switch self {
        case .production:
            return EdgeConstants.NetworkKeys.EDGE_ENDPOINT
        case .preProduction:
            return EdgeConstants.NetworkKeys.EDGE_ENDPOINT_PRE_PRODUCTION
        case .integration:
            return EdgeConstants.NetworkKeys.EDGE_ENDPOINT_INTEGRATION
        }
    }
}

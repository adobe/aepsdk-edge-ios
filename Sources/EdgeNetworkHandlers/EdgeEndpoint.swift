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

/// Represents all the known Edge Network environment types
enum EdgeEnvironmentType: String {
    /// The production Edge Network endpoint
    case production = "prod"

    /// The pre-production Edge Network endpoint
    case preProduction = "pre-prod"

    /// The integration Edge Network endpoint
    case integration = "int"

    init(optionalRawValue: RawValue?) {
        guard let rawValue = optionalRawValue?.lowercased(), let validEndpoint = EdgeEnvironmentType(rawValue: rawValue) else {
            self = .production
            return
        }
        self = validEndpoint
    }
}

struct EdgeEndpoint {
    let url: URL?

    /// Initializes the appropriate `EdgeEndpoint` for the given `type` and `optionalDomain`
    /// - Parameters:
    ///   - requestType: the `EdgeRequestType` to be used
    ///   - environmentType: the `EdgeEnvironmentType` for the `EdgeEndpoint`
    ///   - optionalDomain: an optional custom domain for the `EdgeEndpoint`. If not set the default domain is used.
    ///   - optionalPath: an optional path to be used to overwrite the default path.
    ///   - locationHint: an optional location hint for the `EdgeEndpoint` which hints at the Edge Network cluster to send requests.
    init(requestType: EdgeRequestType,
         environmentType: EdgeEnvironmentType,
         optionalDomain: String? = nil,
         optionalPath: String? = nil,
         locationHint: String? = nil) {
        let domain: String
        if let unwrappedDomain = optionalDomain, !unwrappedDomain.isEmpty {
            domain = unwrappedDomain
        } else {
            domain = EdgeConstants.NetworkKeys.EDGE_DEFAULT_DOMAIN
        }

        var components = URLComponents()
        components.scheme = EdgeConstants.NetworkKeys.HTTPS

        switch environmentType {
        case .production:
            components.host = domain
            components.path = EdgeConstants.NetworkKeys.EDGE_ENDPOINT_PATH
        case .preProduction:
            components.host = domain
            components.path = EdgeConstants.NetworkKeys.EDGE_ENDPOINT_PRE_PRODUCTION_PATH
        case .integration:
            // Edge Integration endpoint does not support custom domains, so there is just the one URL
            components.host = EdgeConstants.NetworkKeys.EDGE_INTEGRATION_DOMAIN
            components.path = EdgeConstants.NetworkKeys.EDGE_ENDPOINT_PATH

        }

        if let locationHint = locationHint, !locationHint.isEmpty {
            components.path.append("/\(locationHint)")
        }

        if let customPath = optionalPath {
            // path should contain the leading "/"
            components.path.append(customPath)
        } else {
            components.path.append(EdgeConstants.NetworkKeys.EDGE_ENDPOINT_VERSION_PATH)
            components.path.append("/\(requestType.rawValue)")
        }

        url = components.url
    }
}

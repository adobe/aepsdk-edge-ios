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
    let endpointUrl: String

    /// Initializes the appropriate `EdgeEndpoint` for the given `type` and `optionalDomain`
    /// - Parameters:
    ///   - type: the `EdgeEnvironmentType` for the `EdgeEndpoint`
    ///   - optionalDomain: an optional custom domain for the `EdgeEndpoint`. If not set the default domain is used.
    init(type: EdgeEnvironmentType, optionalDomain: String? = nil) {
        let domain = EdgeEndpoint.cleanDomain(optionalDomain)

        switch type {
        case .production:
            endpointUrl = "https://\(domain)\(EdgeConstants.NetworkKeys.EDGE_ENDPOINT_PATH)"
        case .preProduction:
            endpointUrl = "https://\(domain)\(EdgeConstants.NetworkKeys.EDGE_ENDPOINT_PRE_PRODUCTION_PATH)"
        case .integration:
            // Edge Integration endpoint does not support custom domains, so there is just the one URL
            endpointUrl = EdgeConstants.NetworkKeys.EDGE_ENDPOINT_INTEGRATION
        }
    }

    /// Clean the given `domain` name by removing any HTTP scheme prefix and lowercasing the name.
    /// - Parameter domain: a URI domain name
    /// - Returns: the given `domain` lowercased and with any HTTP scheme removed
    private static func cleanDomain(_ domain: String?) -> String {
        guard let domain = domain, !domain.isEmpty else {
            return EdgeConstants.NetworkKeys.EDGE_DEFAULT_DOMAIN
        }
        return domain.lowercased().deletePrefix("https://").deletePrefix("http://")
    }
}

extension String {

    /// Remove the given `prefix` from the current string.
    /// - Parameter prefix: the prefix to remove from the current string
    /// - Returns: the current string with the given `prefix` removed
    func deletePrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix.lowercased()) else {
            return self
        }
        return String(self.dropFirst(prefix.count))
    }
}

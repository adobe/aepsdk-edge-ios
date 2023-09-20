//
// Copyright 2023 Adobe. All rights reserved.
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
import AEPServices

/// Wrapper class for `NetworkRequest` that has custom `Equatable` and `Hashable` conformance for use as
/// a custom dictionary key.
class TestableNetworkRequest: Equatable, Hashable {
    private let networkRequest: NetworkRequest
    // MARK: - Read-only properties of wrapped NetworkRequest instance
    var url: URL {
        return networkRequest.url
    }
    
    var httpMethod: HttpMethod {
        return networkRequest.httpMethod
    }
    
    var connectPayload: Data {
        return networkRequest.connectPayload
    }
    
    var httpHeaders: [String: String] {
        return networkRequest.httpHeaders
    }
    
    var connectTimeout: TimeInterval {
        return networkRequest.connectTimeout
    }
    
    var readTimeout: TimeInterval {
        return networkRequest.readTimeout
    }
    
    init(networkRequest: NetworkRequest) {
        self.networkRequest = networkRequest
    }
    
    init?(urlString: String, httpMethod: HttpMethod) {
        guard let request = NetworkRequest(urlString: urlString, httpMethod: httpMethod) else {
            return nil
        }
        self.networkRequest = request
    }
    
    // MARK: - Equatable conformance
    static func == (lhs: TestableNetworkRequest, rhs: TestableNetworkRequest) -> Bool {
        // Compare hosts
        if let lhsHost = lhs.networkRequest.url.host, let rhsHost = rhs.networkRequest.url.host {
            if lhsHost.caseInsensitiveCompare(rhsHost) != .orderedSame {
                return false
            }
        } else if lhs.networkRequest.url.host != nil || rhs.networkRequest.url.host != nil {
            return false
        }

        // Compare schemes
        if let lhsScheme = lhs.networkRequest.url.scheme, let rhsScheme = rhs.networkRequest.url.scheme {
            if lhsScheme.caseInsensitiveCompare(rhsScheme) != .orderedSame {
                return false
            }
        } else if lhs.networkRequest.url.scheme != nil || rhs.networkRequest.url.scheme != nil {
            return false
        }

        // Compare paths (case-sensitive)
        if lhs.networkRequest.url.path != rhs.networkRequest.url.path {
            return false
        }

        // Compare HTTP methods
        return lhs.networkRequest.httpMethod.rawValue == rhs.networkRequest.httpMethod.rawValue
    }
    
    // MARK: - Hashable conformance
    func hash(into hasher: inout Hasher) {
        if let scheme = networkRequest.url.scheme,
           let host = networkRequest.url.host {
            hasher.combine(scheme)
            hasher.combine(host)
            hasher.combine(networkRequest.url.path)
            hasher.combine(networkRequest.httpMethod.rawValue)
        } else {
            hasher.combine(networkRequest.url)
            hasher.combine(networkRequest.httpMethod.rawValue)
        }
    }
}

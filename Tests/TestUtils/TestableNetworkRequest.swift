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
@testable import AEPServices

class TestableNetworkRequest: NetworkRequest {
    /// Construct from existing `NetworkRequest` instance
    convenience init(from networkRequest: NetworkRequest) {
        self.init(url: networkRequest.url,
                  httpMethod: networkRequest.httpMethod,
                  connectPayloadData: networkRequest.connectPayload,
                  httpHeaders: networkRequest.httpHeaders,
                  connectTimeout: networkRequest.connectTimeout,
                  readTimeout: networkRequest.readTimeout)
    }
    // MARK: - Equatable (ObjC) conformance
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NetworkRequest else {
            return false
        }
        // Compare hosts
        if let lhsHost = url.host, let rhsHost = other.url.host {
            if lhsHost.caseInsensitiveCompare(rhsHost) != .orderedSame {
                return false
            }
        } else if url.host != nil || other.url.host != nil {
            return false
        }
        
        // Compare schemes
        if let lhsScheme = url.scheme, let rhsScheme = other.url.scheme {
            if lhsScheme.caseInsensitiveCompare(rhsScheme) != .orderedSame {
                return false
            }
        } else if url.scheme != nil || other.url.scheme != nil {
            return false
        }
        
        // Compare paths (case-sensitive)
        if url.path != other.url.path {
            return false
        }
        
        // Compare HTTP methods
        return httpMethod.rawValue == other.httpMethod.rawValue
    }
    
    // MARK: - Hashable (ObjC) conformance
    public override var hash: Int {
        var hasher = Hasher()
        if let scheme = url.scheme,
           let host = url.host {
            hasher.combine(scheme)
            hasher.combine(host)
            hasher.combine(url.path)
            hasher.combine(httpMethod.rawValue)
        } else {
            hasher.combine(url)
            hasher.combine(httpMethod.rawValue)
        }
        return hasher.finalize()
    }
}

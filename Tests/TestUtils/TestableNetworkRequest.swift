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
    // Note that the Equatable and Hashable conformance logic needs to align exactly for it to work as expected
    // in the case of dictionary keys. Lowercased is used because across current test cases it has the same
    // properties as case insensitive compare, and is straightforward to implement for isEqual and hash. However,
    // if there are new cases where lowercased does not satisfy the property of case insensitive compare, this logic
    // will need to be updated accordingly to handle that case.
    
    // MARK: - Equatable (ObjC) conformance
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NetworkRequest else {
            return false
        }
        
        return url.host?.lowercased() == other.url.host?.lowercased()
                && url.scheme?.lowercased() == other.url.scheme?.lowercased()
                && url.path == other.url.path
                && httpMethod.rawValue == other.httpMethod.rawValue
    }
    
    // MARK: - Hashable (ObjC) conformance
    public override var hash: Int {
        var hasher = Hasher()
        if let scheme = url.scheme {
            hasher.combine(scheme.lowercased())
        }
        if let host = url.host {
            hasher.combine(host.lowercased())
        }
        hasher.combine(url.path)
        hasher.combine(httpMethod.rawValue)
        return hasher.finalize()
    }
}

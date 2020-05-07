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


import Foundation

/// Protocol for network overrides.
/// To be implemented by anyone who wishes to override the SDK's default network stack.
/// Implementer is responsible for updating the  `shouldOverride(url:httpMethod:)` method to let the SDK know if the default network stack should be overriden or not.
public protocol HttpConnectionPerformer {
    
    /// Determines if the provided URL & HTTP method should be overriden by this instance. Used to determine if the network stack should be overriden.
    /// - Parameters:
    ///   - url: URL of the request to override
    ///   - httpMethod: `HttpMethod` for the request to override
    /// - Returns: `Bool` indicating if the override should be enabled or not for current URL
    func shouldOverride(url:URL, httpMethod: HttpMethod) -> Bool
    
    
    /// NetworkRequest to override with a completion handler
    /// - Parameters:
    ///   - networkRequest: `NetworkRequest` instance containing the full URL for the connection, the `HttpMethod`, HTTP body, connect and read timeout
    ///   - completionHandler: Optional completion handler which needs to be called once the connection is initiated
    func connectAsync(networkRequest:NetworkRequest, completionHandler: ((HttpConnection) -> Void)?)
}

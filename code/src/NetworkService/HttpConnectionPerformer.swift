//
// ADOBE CONFIDENTIAL
//
// Copyright 2020 Adobe
// All Rights Reserved.
//
// NOTICE: All information contained herein is, and remains
// the property of Adobe and its suppliers, if any. The intellectual
// and technical concepts contained herein are proprietary to Adobe
// and its suppliers and are protected by all applicable intellectual
// property laws, including trade secret and copyright laws.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from Adobe.
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

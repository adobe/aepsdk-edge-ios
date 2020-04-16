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

/// The HttpConnection represents the response to NetworkRequest, to be used for network completion handlers and when overriding the network stack in place of internal network connection implementation.
public struct HttpConnection {
    
    /// Returns application server response data from the connection or nil if there was an error
    public let data: Data?
    
    /// Response metadata provided by the server
    public let response: HTTPURLResponse?
    
    /// The error associated with the request failure or nil on success
    public let error: Error?
    
    /// Returns application server response as string from the connection, if available.
    public var responseString: String? {
        if let unwrappedData = data {
            return String(data: unwrappedData, encoding: .utf8)
        }
        
        return nil
    }
    
    /// Returns the connection response code for the connection request.
    public var responseCode: Int? {
        return response?.statusCode
    }
    
    /// Returns application server response message as string extracted from the `response` property, if available.
    public var responseMessage: String? {
        if let code = responseCode {
            return HTTPURLResponse.localizedString(forStatusCode: code)
        }
        
        return nil
    }
    
    
    /// Returns a value for the response header key from the `response` property, if available.
    /// This is protocol specific. For example, HTTP URLs could have headers like "last-modified", or "ETag" set.
    /// - Parameter forKey: the header key name sent in response when requesting a connection to the URL.
    public func responseHttpHeader(forKey: String) -> String? {
        return response?.allHeaderFields[forKey] as? String
    }
}

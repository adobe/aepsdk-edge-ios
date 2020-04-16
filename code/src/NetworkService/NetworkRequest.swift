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

/// NetworkRequest struct to be used by the NetworkService and the HttpConnectionPerformer when initiating network calls
public struct NetworkRequest {
    public let url: URL
    public let httpMethod: HttpMethod
    public let connectPayload: String
    public let httpHeaders: [String: String]
    public let connectTimeout: TimeInterval
    public let readTimeout: TimeInterval
    
    /// Initialize the `NetworkRequest`
    /// - Parameters:
    ///   - url: URL used to initiate the network connection, should use https scheme
    ///   - httpMethod: `HttpMethod` to be used for this network request; the default value is GET
    ///   - connectPayload: the body of the network request as a String; this parameter is ignored for GET requests
    ///   - httpHeaders: optional HTTP headers for the request
    ///   - connectTimeout: optional connect timeout value in seconds; default is 5 seconds
    ///   - readTimeout: optional read timeout value in seconds, used to wait for a read to finish after a successful connect, default is 5 seconds
    /// - Returns: an initialized `NetworkRequest` object
    public init(url: URL, httpMethod: HttpMethod = HttpMethod.get, connectPayload: String = "", httpHeaders: [String: String] = [:], connectTimeout: TimeInterval = 5, readTimeout: TimeInterval = 5) {
        self.url = url
        self.httpMethod = httpMethod
        self.connectPayload = connectPayload
        self.httpHeaders = httpHeaders
        self.connectTimeout = connectTimeout
        self.readTimeout = readTimeout
    }
}

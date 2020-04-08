/*
Copyright 2020 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/


import Foundation

public enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
}

public struct HttpConnection {
    public let data: Data?
    public let response: HTTPURLResponse?
    public let error: Error?
    
    public var responseString: String? {
        if let unwrappedData = data {
            return String(data: unwrappedData, encoding: .utf8)
        }
        
        return nil
    }
    
    public var responseCode: Int? {
        return response?.statusCode
    }
    
    public var responseMessage: String? {
        if let code = responseCode {
            return HTTPURLResponse.localizedString(forStatusCode: code)
        }
        
        return nil
    }
    
    public func responseHttpHeader(forKey: String) -> String? {
        return response?.allHeaderFields[forKey] as? String
    }
}

public struct NetworkRequest {
    public let url: URL
    public let httpMethod: HttpMethod
    public let connectPayload: String
    public let httpHeaders: [String: String]
    public let connectTimeout: TimeInterval
    public let readTimeout: TimeInterval
    
    /// Initialize the NetworkRequest
    /// - Parameters:
    ///   - url: URL used to initiate the network connection, should use https scheme
    ///   - httpMethod: HttpMethod to be used for this network request; the default value is GET
    ///   - connectPayload: the body of the network request as a String; this parameter is ignored for GET requests
    ///   - httpHeaders: optional HTTP headers for the request
    ///   - connectTimeout: optional connect timeout value in seconds; default is 5 seconds
    ///   - readTimeout: optional read timeout value in seconds, used to wait for a read to finish after a successful connect, default is 5 seconds
    /// - Returns: an initialized NetworkRequest object or nil if an error occured durinng initialization
    public init?(url: URL, httpMethod: HttpMethod = HttpMethod.get, connectPayload: String = "", httpHeaders: [String: String] = [:], connectTimeout: TimeInterval = 5, readTimeout: TimeInterval = 5) {
        guard url.absoluteString.starts(with: "https") else {
            print("NetworkRequest - Network request for (\(url.absoluteString)) could not be created, only https requests are accepted.");
            return nil
        }
        
        self.url = url
        self.httpMethod = httpMethod
        self.connectPayload = connectPayload
        self.httpHeaders = httpHeaders
        self.connectTimeout = connectTimeout
        self.readTimeout = readTimeout
    }
}

public protocol NetworkServiceProtocol {
    
    /// Initiates an asynchronous network connection to the specified NetworkRequest.url
    /// - Parameters:
    ///   - networkRequest: the NetworkRequest used for this connection
    ///   - completionHandler:invoked whe the HttpConnection is available
    func connectUrlAsync(networkRequest: NetworkRequest, completionHandler: @escaping (HttpConnection) -> Void)
    
    
    /// Initiates an asynchronous network connection.
    /// - Parameter networkRequest: the NetworkRequest used for this connection
    func connectUrlAsync(networkRequest: NetworkRequest)
}

public class NetworkService: NetworkServiceProtocol {
    
    public init() {}
    
    // TODO: use ThreadSafeDictionary when moving to core
    var sessions = [String:URLSession]()
    
    // fire and forget
    public func connectUrlAsync(networkRequest: NetworkRequest) {
        let urlRequest = createURLRequest(networkRequest: networkRequest)
        guard urlRequest != nil else {return;}
        
        let urlSession = createURLSession(networkRequest: networkRequest)
        
        // initiate the request
        print("NetworkService - Initiated (\(networkRequest.httpMethod.rawValue)) network request to (\(networkRequest.url.absoluteString)).")
        let task = urlSession?.dataTask(with: urlRequest!);
        task?.resume()
    }
    
    public func connectUrlAsync(networkRequest: NetworkRequest, completionHandler: @escaping (HttpConnection) -> Void) {
        let urlRequest = createURLRequest(networkRequest: networkRequest)
        guard urlRequest != nil else {return;}
        
        let urlSession = createURLSession(networkRequest: networkRequest)
        
        // initiate the request
        print("NetworkService - Initiated (\(networkRequest.httpMethod.rawValue)) network request to (\(networkRequest.url.absoluteString)) with completion handler.")
        let task = urlSession?.dataTask(with: urlRequest!, completionHandler: { (data, response, error) in
            let httpConnection = HttpConnection(data: data, response: response as? HTTPURLResponse , error: error)
            completionHandler(httpConnection)
        })
        
        task?.resume()
    }
    
    private func createURLRequest(networkRequest: NetworkRequest) -> URLRequest? {
        var request = URLRequest(url: networkRequest.url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = networkRequest.httpMethod.rawValue
        
        if !networkRequest.connectPayload.isEmpty && networkRequest.httpMethod == .post {
            request.httpBody = networkRequest.connectPayload.data(using: .utf8)
        }
        
        // TODO: Set default user agent from system info service
        for (key, val) in networkRequest.httpHeaders {
            request.setValue(key, forHTTPHeaderField: val)
        }
        
        return request;
    }
    
    
    /// Check if a session is already created for the specified URL, readTimeout, connectTimeout or create a new one with a new URLSessionConfiguration
    /// - Parameter networkRequest: current network request
    private func createURLSession(networkRequest: NetworkRequest) -> URLSession? {
        let sessionId = "\(networkRequest.url.absoluteString)\(networkRequest.readTimeout)\(networkRequest.connectTimeout)"
        var session = self.sessions[sessionId]
        
        if session == nil {
            // Create config for an ephemeral NSURLSession with specified timeouts
            let config = URLSessionConfiguration.ephemeral
            config.urlCache = nil
            config.timeoutIntervalForRequest = networkRequest.readTimeout
            config.timeoutIntervalForResource = networkRequest.connectTimeout
            
            session = URLSession(configuration: config)
            self.sessions[sessionId] = session
        }
        
        return session;
    }
}

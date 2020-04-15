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

extension String {

    private func matches(pattern: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: pattern,options: [.caseInsensitive])
        return regex.firstMatch(in: self, range: NSRange(location: 0, length: utf16.count)) != nil
    }

    func isValidUrl() -> Bool {
        // taken from Diego Perini's post, https://gist.github.com/dperini/729294
        // see also https://mathiasbynens.be/demo/url-regex
        let urlPattern:String = """
                                ^\
                                (?:(?:https?|ftp)://)\
                                (?:\\S+(?::\\S*)?@)?\
                                (?:\
                                (?!(?:10)(?:\\.\\d{1,3}){3})\
                                (?!(?:169\\.254|192\\.168)(?:\\.\\d{1,3}){2})\
                                (?!172\\.(?:1[6-9]|2\\d|3[0-1])(?:\\.\\d{1,3}){2})\
                                (?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])\
                                (?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}\
                                (?:\\.(?:[1-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))\
                                |\
                                (?:(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)\
                                (?:\\.(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)*\
                                \\.?\
                                )\
                                (?::\\d{2,5})?\
                                (?:[/?#]\\S*)?\
                                $
                                """
        return self.matches(pattern: urlPattern)
    }
}

@objc public enum HttpMethod: Int {
    case get
    case post
    
    func toString() -> String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        }
    }
}

enum NetworkServiceError: Error {
    case invalidUrl
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
    /// - Returns: an initialized NetworkRequest object
    public init(url: URL, httpMethod: HttpMethod = HttpMethod.get, connectPayload: String = "", httpHeaders: [String: String] = [:], connectTimeout: TimeInterval = 5, readTimeout: TimeInterval = 5) {
        self.url = url
        self.httpMethod = httpMethod
        self.connectPayload = connectPayload
        self.httpHeaders = httpHeaders
        self.connectTimeout = connectTimeout
        self.readTimeout = readTimeout
    }
}

/// Protocol for network overrides.
/// To be implemented by anyone who wishes to override the SDK's default network stack.
/// Implementer is responsible for updating the  `shouldOverride(url:httpMethod:) method to let the SDK know if the default network stack should be overriden or not.
public protocol HttpConnectionPerformer {
    
    /// Determines if the provided URL & HTTP method should be overriden by this instance. Used to determine if the network stack should be overriden
    /// - Parameters:
    ///   - url: URL of the request to override
    ///   - httpMethod: HttpMethod for the request to override
    func shouldOverride(url:URL, httpMethod: HttpMethod) -> Bool
    
    
    /// NetworkRequest to override with a completion handler
    /// - Parameters:
    ///   - networkRequest: NetworkRequest instance containing the full URL for the connection, the HttpMethod, HTTP body, connect and read timeout
    ///   - completionHandler: Optional completion handler which needs to be called once the connection is initiated
    func connectAsync(networkRequest:NetworkRequest, completionHandler: ((HttpConnection) -> Void)?)
}

protocol NetworkServiceProtocol {
    
    /// Initiates an asynchronous network connection to the specified NetworkRequest.url. This API uses URLRequest.CachePolicy.reloadIgnoringLocalCache.
    /// - Parameters:
    ///   - networkRequest: the NetworkRequest used for this connection
    ///   - completionHandler:Optional completion handler which is called once the HttpConnection is available; it can be called from an HttpConnectionPerformer if NetworkServiceOverrider is enabled.
    ///   In case of a network error, timeout or an unexpected error, the HttpConnection is nil
    func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?)
}

public class NetworkService: NetworkServiceProtocol {
  
    // TODO: use ThreadSafeDictionary when moving to core
    private var sessions:[String:URLSession]
    var session: URLSession? // to be used only for dependency injection for testing
    public static let shared = NetworkService()
    
    private init() {
        sessions = [String:URLSession]()
        session = nil
    }
    
    public func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)? = nil) {
        
        if !networkRequest.url.absoluteString.starts(with: "https") {
            print("NetworkService - Network request for (\( networkRequest.url.absoluteString)) could not be created, only https requests are accepted.")
            if let closure = completionHandler {
                closure(HttpConnection(data: nil, response: nil, error: NetworkServiceError.invalidUrl))
            }
            return
        }
        if !networkRequest.url.absoluteString.isValidUrl() {
            print("NetworkService - Invalid URL (\( networkRequest.url.absoluteString))")
            if let closure = completionHandler {
                closure(HttpConnection(data: nil, response: nil, error: NetworkServiceError.invalidUrl))
            }
            return
        }
        
        let overridePerformer = NetworkServiceOverrider.shared.performer
        if overridePerformer != nil && overridePerformer!.shouldOverride(url: networkRequest.url, httpMethod: networkRequest.httpMethod) {
            // TODO: AMSDK-9800 should the default headers be injected in the network request even when networkOverride is enabled
            print("NetworkService - Initiated (\(networkRequest.httpMethod.rawValue)) network request to (\(networkRequest.url.absoluteString)) with completion handler using the NetworkServiceOverrider.")
            overridePerformer!.connectAsync(networkRequest: networkRequest, completionHandler: completionHandler)
        } else {
            // using the default network service
            let urlRequest = createURLRequest(networkRequest: networkRequest)
            let urlSession = createURLSession(networkRequest: networkRequest)
            
            // initiate the request with/without completion handler
            guard let closure = completionHandler else {
                print("NetworkService - Initiated (\(networkRequest.httpMethod.rawValue)) network request to (\(networkRequest.url.absoluteString)).")
                let task = urlSession.dataTask(with: urlRequest)
                task.resume()
                return
            }
            
            print("NetworkService - Initiated (\(networkRequest.httpMethod.rawValue)) network request to (\(networkRequest.url.absoluteString)) with completion handler.")
            let task = urlSession.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                let httpConnection = HttpConnection(data: data, response: response as? HTTPURLResponse , error: error)
                closure(httpConnection)
            })
            task.resume()
        }
    }
    
    /// Creates an URLRequest with the provided parameters and adds the SDK default headers. The cache policy used is reloadIgnoringLocalCacheData.
    /// - Parameter networkRequest: NetworkRequest
    private func createURLRequest(networkRequest: NetworkRequest) -> URLRequest {
        var request = URLRequest(url: networkRequest.url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = networkRequest.httpMethod.toString()
        
        if !networkRequest.connectPayload.isEmpty && networkRequest.httpMethod == .post {
            request.httpBody = networkRequest.connectPayload.data(using: .utf8)
        }
        
        // TODO: AMSDK-9800 Set default user agent from system info service
        for (key, val) in networkRequest.httpHeaders {
            request.setValue(val, forHTTPHeaderField: key)
        }
        
        return request;
    }
    
    /// Check if a session is already created for the specified URL, readTimeout, connectTimeout or create a new one with a new URLSessionConfiguration
    /// - Parameter networkRequest: current network request
    private func createURLSession(networkRequest: NetworkRequest) -> URLSession {
        let sessionId = "\(networkRequest.url.absoluteString)\(networkRequest.readTimeout)\(networkRequest.connectTimeout)"
        guard let session = self.sessions[sessionId] else {
            // Create config for an ephemeral NSURLSession with specified timeouts
            let config = URLSessionConfiguration.ephemeral
            config.urlCache = nil
            config.timeoutIntervalForRequest = networkRequest.readTimeout
            config.timeoutIntervalForResource = networkRequest.connectTimeout
            
            let newSession:URLSession = self.session != nil ? self.session! : URLSession(configuration: config)
            self.sessions[sessionId] = newSession
            return newSession
        }
        
        return session;
    }
}

/// Used to set the HttpConnectionPerformer instance being used to override the network stack
public class NetworkServiceOverrider {
    private let queue: DispatchQueue // used to ensure concurrent mutations of the performer
    private var internalPerformer:HttpConnectionPerformer?
    public static let shared = NetworkServiceOverrider()
    
    private init(){
        queue = DispatchQueue(label: "com.adobe.networkserviceoverrider", attributes: .concurrent)
    }
    
    /// Current HttpConnectionPerformer, nil if NetworkServiceOverrider is not set or `reset()` was called before
    public var performer: HttpConnectionPerformer? {
        self.queue.sync { self.internalPerformer}
    }
    
    /// Sets a new HttpConnectionPerformer to override default network activity.
    /// - Parameter with: HttpConnectionPerformer new performer to be used in place of default network stack.
    public func enableOverride(with : HttpConnectionPerformer) {
        print("NetworkServiceOverrider - Enabling network override.")
        self.queue.async(flags: .barrier) { self.internalPerformer = with }
    }
    
    
    /// Resets currently set HttpConnectionPerformer and allows the SDK to use the default network stack for network requests
    public func reset() {
        print("NetworkServiceOverrider - Disabling network override, using default network service.")
        self.queue.async(flags: .barrier) { self.internalPerformer = nil }
    }
}

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

enum HttpCommandType: String {
    case get = "GET"
    case post = "POST"
}

protocol NetworkServiceProtocol {
    func connectUrlAsync(url: URL, command: HttpCommandType, connectPayload: String, requestProperty: [String: String],
                         connectTimeout: Int, readTimout: Int, completion: @escaping (HttpConnection) -> Void)
}

class NetworkService: NetworkServiceProtocol {
    
    var sessions = [String: URLSession]() // TODO: Ensure thread safe
    
    func connectUrlAsync(url: URL, command: HttpCommandType, connectPayload: String, requestProperty: [String : String],
                         connectTimeout: Int, readTimout: Int, completion: @escaping (HttpConnection) -> Void) {
        
        guard url.absoluteString.contains("https") else {
            // throw error or return error via completion block
            return
        }
        
        // Create config for an ephemeral NSURLSession with specified timeouts
        let config = URLSessionConfiguration.ephemeral
        config.urlCache = nil
        config.timeoutIntervalForRequest = TimeInterval(readTimout)
        config.timeoutIntervalForResource = TimeInterval(connectTimeout)
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = command.rawValue
        
        if !connectPayload.isEmpty && command == .post {
            request.httpBody = connectPayload.data(using: .utf8)
        }
        
        // TODO: Set default user agent from system info service
        
        for (key, val) in requestProperty {
            request.setValue(key, forHTTPHeaderField: val)
        }
        
        let timeoutString = "\(readTimout),\(connectTimeout)"
        var session = self.sessions[timeoutString]
        
        if session == nil {
            session = URLSession(configuration: config)
            self.sessions[timeoutString] = session
        }
        
        let task = session?.dataTask(with: request, completionHandler: { (data, response, error) in
            let httpConnection = HttpConnection(data: data, response: response as? HTTPURLResponse , error: error)
            completion(httpConnection)
        })
        
        task?.resume()
    }
    
}

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
import ACPCore

enum RequestType: String {
   case interact = "interact"
   case collect = "collect"
}

enum Retry: Int {
   case yes = 1
   case no = 0
}

enum HttpResponseCodes: Int {
    case ok = 200
    case noContent = 204
    case clientTimeout = 408
    case tooManyRequests = 429
    case serviceUnavailable = 503
    case gatewayTimeout = 504
}

protocol ResponseCallback {
    func onResponse(jsonResponse: String)
    
    func onError(jsonError: String)
    
    func onComplete(shouldRetry: Retry)
}

class ExperiencePlatformNetworkService {
    private let TAG:String = "ExperiencePlatformNetworkService"
    private let recoverableNetworkErrorCodes:[Int] = [HttpResponseCodes.clientTimeout.rawValue,
                                                      HttpResponseCodes.tooManyRequests.rawValue,
                                                      HttpResponseCodes.serviceUnavailable.rawValue,
                                                      HttpResponseCodes.gatewayTimeout.rawValue
                                                      ]
    var defaultHeaders = [ExperiencePlatformConstants.NetworkKeys.headerKeyAccept: ExperiencePlatformConstants.NetworkKeys.headerValueApplicationJson,
                        ExperiencePlatformConstants.NetworkKeys.headerKeyContentType: ExperiencePlatformConstants.NetworkKeys.headerValueApplicationJson]
    
    
    /// Builds the URL required for connections to ExEdge with the provided `RequestType`
    /// - Parameters:
    ///   - requestType: see `RequestType`
    ///   - configId: blackbird configuration id
    ///   - requestId: batch request identifier
    /// - Returns: built URL or nil on error
    func buildUrl(requestType: RequestType, configId: String, requestId: String) -> URL? {
        guard var url = URL(string: ExperiencePlatformConstants.NetworkKeys.edgeEndpoint) else { return nil }
        url.appendPathComponent(requestType.rawValue)
        
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        urlComponents.queryItems = [URLQueryItem(name: ExperiencePlatformConstants.NetworkKeys.requestParamConfigId, value: configId),
                                    URLQueryItem(name: ExperiencePlatformConstants.NetworkKeys.requestParamRequestId, value: requestId)]
        
        return urlComponents.url
    }
    
    func doConnectAsync(url: URL, jsonBody: Data?, requestHeaders: [String: String]? = [:], responseCallback: ResponseCallback) {
        let decoder = JSONDecoder()
        let streaming = try? decoder.decode(Streaming.self, from: jsonBody!)
        let headers = defaultHeaders.merging(requestHeaders ?? [:]) { (_, new) in new}
        let networkNetwork:NetworkRequest = NetworkRequest(url: url, httpMethod: HttpMethod.post, httpHeaders: headers,
                                                           connectTimeout: ExperiencePlatformConstants.NetworkKeys.defaultConnectTimeout,
                                                           readTimeout: ExperiencePlatformConstants.NetworkKeys.defaultReadTimeout);
        ACPNetworkService.shared.connectAsync(networkRequest: networkNetwork) { (connection:HttpConnection) in
            if (connection.error != nil) {
                // handle generic error
                self.handleError(connection: connection, responseCallback: responseCallback)
                responseCallback.onComplete(shouldRetry: Retry.no)
                return
            }
            
            var shouldRetry = Retry.no
            if let responseCode = connection.responseCode {
                if (responseCode == HttpResponseCodes.ok.rawValue) {
                    ACPCore.log(ACPMobileLogLevel.debug, tag: self.TAG, message: "doConnectAsync - Interact connection to data platform successful.")
                    if let responseString = connection.responseString {
                        ACPCore.log(ACPMobileLogLevel.debug, tag: self.TAG, message: "doConnectAsync - Response message: " + responseString)
                    }
                   
                    self.handleContent(connection: connection, streaming: streaming, responseCallback: responseCallback)
                   
               } else if (responseCode == HttpResponseCodes.noContent.rawValue) {
                   // Successful collect requests do not return content
                    ACPCore.log(ACPMobileLogLevel.debug, tag: self.TAG, message: "doConnectAsync - Collect connection to data platform successful.")
                   
                } else if (self.recoverableNetworkErrorCodes.contains(responseCode)) {
                    ACPCore.log(ACPMobileLogLevel.debug, tag: self.TAG, message: "doConnectAsync - Connection to data platform returned recoverable error code \(responseCode)")
                   shouldRetry = Retry.yes
               } else {
                    ACPCore.log(ACPMobileLogLevel.warning, tag: self.TAG, message: "doConnectAsync - Connection to ExEdge returned unrecoverable error code")
                    self.handleError(connection: connection, responseCallback: responseCallback)
               }
           } else {
                ACPCore.log(ACPMobileLogLevel.warning, tag: self.TAG, message: "doConnectAsync - Connection to ExEdge returned unrecoverable error code")
                self.handleError(connection: connection, responseCallback: responseCallback)
           }
           
            responseCallback.onComplete(shouldRetry: shouldRetry)
        }
    }
    
    func handleContent(connection: HttpConnection, streaming: Streaming?, responseCallback: ResponseCallback) {
        guard let unwrappedResponseString = connection.responseString else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "handleContent - No data to handle")
            return
        }
        if let unwrappedStreaming = streaming {
            if (unwrappedStreaming.enabled == true) {
                handleStreamingResponse(connection: connection, streaming: unwrappedStreaming, responseCallback: responseCallback)
            } else {
                responseCallback.onResponse(jsonResponse: unwrappedResponseString)
            }
        } else {
            responseCallback.onResponse(jsonResponse: unwrappedResponseString)
        }
    }
    
    func handleStreamingResponse(connection: HttpConnection, streaming: Streaming, responseCallback: ResponseCallback) {
        
        guard let unwrappedResponseString = connection.responseString else { return }
        guard let recordSerapator: Character = streaming.recordSeparator else { return }
        guard let lineFeedDelimiter: Character = streaming.lineFeed else { return }
        
        let splitResult = unwrappedResponseString.split(separator: lineFeedDelimiter)
        print(splitResult)
        
        var trimmingChars = CharacterSet()
        trimmingChars.insert(charactersIn: String(recordSerapator))
        for jsonResult in splitResult {
            print(jsonResult.trimmingCharacters(in: trimmingChars))
            responseCallback.onResponse(jsonResponse: String(jsonResult))
        }
    }
    
    func handleError(connection: HttpConnection, responseCallback: ResponseCallback) {
        if connection.error != nil {
            if let unwrappedResponseMessage = connection.responseMessage {
                responseCallback.onError(jsonError: unwrappedResponseMessage)
            } else {
                
            }
        } else {
            if let unwrappedResponseAsString = connection.responseString {
                responseCallback.onError(jsonError: unwrappedResponseAsString)
            }
        }
        
    }
        
    
    /// Composes a generic error (string with JSON format), containing generic namespace and the provided error message, after removing the leading and trailing spaces.
    /// - Parameter plainTextErrorMessage: error message to be formatted; if nil/empty is provided, a default error message will be returned.
    /// - Returns: the JSON formatted error
    func composeGenericErrorAsJson(plainTextErrorMessage: String?) -> String {
        // todo
        return ""
    }
}

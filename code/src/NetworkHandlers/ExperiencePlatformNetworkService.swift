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

/// ExperienceEdge Request Types:
///     - interact - makes request and expects a response
///     - collect - makes request without expecting a response
enum ExperienceEdgeRequestType: String {
    case interact = "interact"
    case collect = "collect"
}

/// Used to identify if a `NetworkRequest` should be retried or not
enum RetryNetworkRequest: Int {
    case yes
    case no
}

/// Convenience enum for the known error codes
enum HttpResponseCodes: Int {
    case ok = 200
    case noContent = 204
    case clientTimeout = 408
    case tooManyRequests = 429
    case serviceUnavailable = 503
    case gatewayTimeout = 504
}

/// Network service for requests to the Adobe Experience Edge
class ExperiencePlatformNetworkService {
    private let TAG:String = "ExperiencePlatformNetworkService"
    private let defaultGenericErrorMessage = "Request to ExEdge failed with an unknown exception"
    private let defaultNamespace = "global"
    private let recoverableNetworkErrorCodes:[Int] = [HttpResponseCodes.clientTimeout.rawValue,
                                                      HttpResponseCodes.tooManyRequests.rawValue,
                                                      HttpResponseCodes.serviceUnavailable.rawValue,
                                                      HttpResponseCodes.gatewayTimeout.rawValue]
    private let waitTimeout:TimeInterval = max(ExperiencePlatformConstants.NetworkKeys.defaultConnectTimeout, ExperiencePlatformConstants.NetworkKeys.defaultReadTimeout) + 1
    private var defaultHeaders = [ExperiencePlatformConstants.NetworkKeys.headerKeyAccept: ExperiencePlatformConstants.NetworkKeys.headerValueApplicationJson,
                                  ExperiencePlatformConstants.NetworkKeys.headerKeyContentType: ExperiencePlatformConstants.NetworkKeys.headerValueApplicationJson]
    
    /// Builds the URL required for connections to ExEdge with the provided `ExperienceEdgeRequestType`
    /// - Parameters:
    ///   - requestType: see `ExperienceEdgeRequestType`
    ///   - configId: blackbird configuration id
    ///   - requestId: batch request identifier
    /// - Returns: built URL or nil on error
    func buildUrl(requestType: ExperienceEdgeRequestType, configId: String, requestId: String) -> URL? {
        guard var url = URL(string: ExperiencePlatformConstants.NetworkKeys.edgeEndpoint) else { return nil }
        url.appendPathComponent(requestType.rawValue)
        
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        urlComponents.queryItems = [URLQueryItem(name: ExperiencePlatformConstants.NetworkKeys.requestParamConfigId, value: configId),
                                    URLQueryItem(name: ExperiencePlatformConstants.NetworkKeys.requestParamRequestId, value: requestId)]
        
        return urlComponents.url
    }
    
    /// Make a network request to the Experience Edge and handle the connection.
    /// - Parameters:
    ///   - url: request URL
    ///   - requestBody: `EdgeRequest` containing the encoded events
    ///   - requestHeaders: request HTTP headers
    ///   - responseCallback: `ResponseCallback` to be invoked once the server response is received
    ///   - retryTimes: number of retries required for this request in case the connection failed or a `recoverableNetworkErrorCodes` was encountered
    func doRequest(url: URL, requestBody: EdgeRequest, requestHeaders: [String: String]? = [:], responseCallback: ResponseCallback, retryTimes: UInt = 0) {
        // AMSDK-8909 check if this network request fails and needs a retry. The retry will happen right away, repeatedly (if needed) for
        // maximum NETWORK_REQUEST_MAX_RETRIES times or until the request is accepted by the server.
        // To be reconsidered when implementing AMSDK-8822 when we may not need the max retries limit anymore.
        
        var shouldRetry = self.doRequest(url: url, requestBody: requestBody, requestHeaders: requestHeaders, responseCallback: responseCallback)
        var retries = 0
        while shouldRetry == RetryNetworkRequest.yes && retries < retryTimes {
            ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "doRequest with retry - Error occurred for network request, retrying...")
            shouldRetry = self.doRequest(url: url, requestBody: requestBody, requestHeaders: requestHeaders, responseCallback: responseCallback)
            retries += 1
        }
        
        // force cleanup if the network request did not succeed
        if (shouldRetry == RetryNetworkRequest.yes) {
            responseCallback.onComplete();
        }
    }
    
    /// Make a network request to the Experience Edge and handle the connection.
    /// - Parameters:
    ///   - url: request URL
    ///   - requestBody: `EdgeRequest` containing the encoded events
    ///   - requestHeaders: request HTTP headers
    ///   - responseCallback: `ResponseCallback` to be invoked once the server response is received
    /// - Returns: `RetryNetworkRequest` status, returns yes if the connection was not successful or a `recoverableNetworkErrorCodes` was encountered; the caller should retry this request if needed
    func doRequest(url: URL, requestBody: EdgeRequest, requestHeaders: [String: String]? = [:], responseCallback: ResponseCallback) -> RetryNetworkRequest {
        var shouldRetry: RetryNetworkRequest = RetryNetworkRequest.no
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        
        guard let data = try? encoder.encode(requestBody) else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Failed to encode request to JSON, dropping this request")
            return shouldRetry
        }
        
        let headers = defaultHeaders.merging(requestHeaders ?? [:]) { (_, new) in new}
        let payload = String(decoding: data, as: UTF8.self)
        
        let networkRequest:NetworkRequest = NetworkRequest(url: url,
                                                           httpMethod: HttpMethod.post,
                                                           connectPayload: payload,
                                                           httpHeaders: headers,
                                                           connectTimeout: ExperiencePlatformConstants.NetworkKeys.defaultConnectTimeout,
                                                           readTimeout: ExperiencePlatformConstants.NetworkKeys.defaultReadTimeout);
        ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Sending request to URL \(url.absoluteString) with header: \(headers) and body: \n\(payload)")
        
        // make sync call to process the response right away and retry if needed
        let semaphore = DispatchSemaphore(value: 0)
        
        AEPServiceProvider.shared.networkService.connectAsync(networkRequest: networkRequest) { (connection:HttpConnection) in
            if connection.error != nil {
                // handle generic error
                self.handleError(connection: connection, responseCallback: responseCallback)
                
                shouldRetry = RetryNetworkRequest.no
                semaphore.signal()
                return
            }
            
            shouldRetry = RetryNetworkRequest.no
            if let responseCode = connection.responseCode {
                if responseCode == HttpResponseCodes.ok.rawValue {
                    ACPCore.log(ACPMobileLogLevel.debug, tag: self.TAG, message: "doRequest - Interact connection to ExEdge was successful.")
                    if let responseString = connection.responseString {
                        ACPCore.log(ACPMobileLogLevel.debug, tag: self.TAG, message: "doRequest - Response message: \(responseString)")
                    }
                    
                    self.handleContent(connection: connection, streaming: requestBody.meta?.konductorConfig?.streaming, responseCallback: responseCallback)
                    
                } else if responseCode == HttpResponseCodes.noContent.rawValue {
                    // Successful collect requests do not return content
                    ACPCore.log(ACPMobileLogLevel.debug, tag: self.TAG, message: "doRequest - Collect connection to data platform successful.")
                    
                } else if self.recoverableNetworkErrorCodes.contains(responseCode) {
                    ACPCore.log(ACPMobileLogLevel.debug, tag: self.TAG, message: "doRequest - Connection to ExEdge returned recoverable error code \(responseCode)")
                    shouldRetry = RetryNetworkRequest.yes
                } else {
                    ACPCore.log(ACPMobileLogLevel.warning, tag: self.TAG, message: "doRequest - Connection to ExEdge returned unrecoverable error code \(responseCode)")
                    self.handleError(connection: connection, responseCallback: responseCallback)
                }
            } else {
                ACPCore.log(ACPMobileLogLevel.warning, tag: self.TAG, message: "doRequest - Connection to ExEdge returned unknown error")
                self.handleError(connection: connection, responseCallback: responseCallback)
            }
            
            semaphore.signal()
        }
        
        let _ = semaphore.wait(timeout: .now() + waitTimeout)
        if shouldRetry == RetryNetworkRequest.no {
            responseCallback.onComplete()
        }
        
        return shouldRetry
    }
    
    /// Attempts the read the response from the c`connection`and return the content via the `responseCallback`. This method should be used for handling 2xx server response.
    /// In the eventuality of an error, this method returns false and an error message will be logged.
    /// - Parameters:
    ///   - connection: `HttpConnection` containing the response from the server
    ///   - streaming: `Streaming` settings to be used to determine if streaming is enabled or not
    ///   - responseCallback: `ResponseCallback` that is invoked for each individual stream if streaming is enabled or once with the unrapped response content
    func handleContent(connection: HttpConnection, streaming: Streaming?, responseCallback: ResponseCallback) {
        guard let unwrappedResponseString = connection.responseString else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "handleContent - No data to handle")
            return
        }
        if let unwrappedStreaming = streaming {
            if unwrappedStreaming.enabled == true {
                handleStreamingResponse(connection: connection, streaming: unwrappedStreaming, responseCallback: responseCallback)
            } else {
                responseCallback.onResponse(jsonResponse: unwrappedResponseString)
            }
        } else {
            responseCallback.onResponse(jsonResponse: unwrappedResponseString)
        }
    }
    
    /// Attempts to read the error response from the `connection` error response message and returns it in the
    /// `ResponseCallback.onError(jsonError)` callback.
    /// - Parameters:
    ///   - connection: `HttpConnection` containing the response from the server
    ///   - responseCallback: `ResponseCallback` that is invoked with the error message
    func handleError(connection: HttpConnection, responseCallback: ResponseCallback) {
        var errorJson: String? = nil
        if let _ = connection.error {
            if let unwrappedResponseMessage = connection.responseMessage {
                errorJson = composeGenericErrorAsJson(plainTextErrorMessage: unwrappedResponseMessage)
            } else {
                errorJson = composeGenericErrorAsJson(plainTextErrorMessage: nil)
            }
        } else {
            errorJson = composeGenericErrorAsJson(plainTextErrorMessage: connection.responseString)
        }
        
        if let unwrappedErrorJson  = errorJson {
            responseCallback.onError(jsonError: unwrappedErrorJson)
        }
    }
    
    /// Attempts to read the streamed response from the `connection` and return the content via the `responseCallback`
    /// - Parameters:
    ///   - connection: `HttpConnection` containing the response from the server, the `responseString` is used so it should not be nil
    ///   - streaming: `Streaming` settings to be used to determine the record and line feed separators for the response, streaming properties should not be nil
    ///   - responseCallback: `ResponseCallback` that is invoked for each individual stream
    private func handleStreamingResponse(connection: HttpConnection, streaming: Streaming, responseCallback: ResponseCallback) {
        
        guard let unwrappedResponseString = connection.responseString else { return }
        guard let recordSerapator: String = streaming.recordSeparator else { return }
        guard let lineFeedDelimiter: String = streaming.lineFeed else { return }
        guard let lineFeedCharacter: Character = lineFeedDelimiter.convertToCharacter() else { return }
        
        let splitResult = unwrappedResponseString.split(separator: lineFeedCharacter)
        
        var trimmingChars = CharacterSet()
        trimmingChars.insert(charactersIn: recordSerapator)
        for jsonResult in splitResult {
            let trimmedResult = jsonResult.trimmingCharacters(in: trimmingChars)
            responseCallback.onResponse(jsonResponse: trimmedResult)
        }
    }
    
    /// Composes a generic error (string with JSON format), containing generic namespace and the provided error message, after removing the leading and trailing spaces.
    /// - Parameter plainTextErrorMessage: error message to be formatted; if nil/empty is provided, a default error message is returned.
    /// - Returns: the JSON formatted error as a String or nil if there was an error while serlizinging the error message
    private func composeGenericErrorAsJson(plainTextErrorMessage: String?) -> String? {
        if let unwrappedMessage = plainTextErrorMessage {
            // check if this is a json error response from ExEdge, and if so passed unchanged
            let data = Data(unwrappedMessage.utf8)
            
            if let _ = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return plainTextErrorMessage
            }
        }
        
        var unwrappedErrorMessage = plainTextErrorMessage ?? defaultGenericErrorMessage
        unwrappedErrorMessage = unwrappedErrorMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let errorDictionary = [ExperiencePlatformConstants.JsonKeys.Response.Error.message : unwrappedErrorMessage, ExperiencePlatformConstants.JsonKeys.Response.Error.namespace: defaultNamespace]
        guard let json = try? JSONSerialization.data(withJSONObject: errorDictionary, options: []) else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "composeGenericErrorAsJson - Failed to serialize the error message.")
            return nil
        }
        guard let jsonString = String(data: json, encoding: .utf8) else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "composeGenericErrorAsJson - Failed to serialize the error message.")
            return nil
        }
        
        return jsonString
    }
}

extension String {
    /// Converts a String to Character. The `string` needs to have only one Character and it should not be empty.
    /// - Parameter string: String to be convert to Character
    /// - Returns: the result Character or nil if the convertion failed
    func convertToCharacter() -> Character? {
        guard self.count == 1 else {
            ACPCore.log(ACPMobileLogLevel.verbose, tag: "convertToCharacter", message: "Unable to decode Character with multiple characters (\(self))")
            return nil
        }
        guard let character = self.first else {
            ACPCore.log(ACPMobileLogLevel.verbose, tag: "convertToCharacter", message: "Unable to decode empty Character (\(self)")
            return nil
        }
        return character
    }
}

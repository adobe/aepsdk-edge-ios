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

import AEPCore
import AEPServices
import Foundation

/// ExperienceEdge Request Types:
///     - interact - makes request and expects a response
///     - collect - makes request without expecting a response
enum ExperienceEdgeRequestType: String {
    case interact
    case collect
}

/// Convenience enum for the known error codes
enum HttpResponseCodes: Int {
    case ok = 200
    case noContent = 204
    case multiStatus = 207
    case clientTimeout = 408
    case tooManyRequests = 429
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
}

/// Network service for requests to the Adobe Experience Edge
class EdgeNetworkService {
    private let LOG_TAG: String = "EdgeNetworkService"
    private let DEFAULT_GENERIC_ERROR_MESSAGE = "Request to Experience Edge failed with an unknown exception"
    private let DEFAULT_NAMESPACE = "global"
    private let recoverableNetworkErrorCodes: [Int] = [HttpResponseCodes.clientTimeout.rawValue,
                                                       HttpResponseCodes.tooManyRequests.rawValue,
                                                       HttpResponseCodes.badGateway.rawValue,
                                                       HttpResponseCodes.serviceUnavailable.rawValue,
                                                       HttpResponseCodes.gatewayTimeout.rawValue]
    private let waitTimeout: TimeInterval = max(EdgeConstants.NetworkKeys.DEFAULT_CONNECT_TIMEOUT, EdgeConstants.NetworkKeys.DEFAULT_READ_TIMEOUT) + 1
    private var defaultHeaders = [EdgeConstants.NetworkKeys.HEADER_KEY_ACCEPT: EdgeConstants.NetworkKeys.HEADER_VALUE_APPLICATION_JSON,
                                  EdgeConstants.NetworkKeys.HEADER_KEY_CONTENT_TYPE: EdgeConstants.NetworkKeys.HEADER_VALUE_APPLICATION_JSON]

    /// Builds the URL required for connections to Experience Edge with the provided `ExperienceEdgeRequestType`
    /// - Parameters:
    ///   - requestType: see `ExperienceEdgeRequestType`
    ///   - configId: Edge configuration identifier
    ///   - requestId: batch request identifier
    /// - Returns: built URL or nil on error
    func buildUrl(requestType: ExperienceEdgeRequestType, configId: String, requestId: String) -> URL? {
        guard var url = URL(string: EdgeConstants.NetworkKeys.EDGE_ENDPOINT) else { return nil }
        url.appendPathComponent(requestType.rawValue)

        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        urlComponents.queryItems = [URLQueryItem(name: EdgeConstants.NetworkKeys.REQUEST_PARAM_CONFIG_ID, value: configId),
                                    URLQueryItem(name: EdgeConstants.NetworkKeys.REQUEST_PARAM_REQUEST_ID, value: requestId)]

        return urlComponents.url
    }

    /// Make a network request to the Experience Edge and handle the connection.
    /// - Parameters:
    ///   - url: request URL
    ///   - requestBody: `EdgeRequest` containing the encoded events
    ///   - requestHeaders: request HTTP headers
    ///   - responseCallback: `ResponseCallback` to be invoked once the server response is received
    ///   - completion: a closure that is invoked with true if the hit should not be retried, false if the hit should be retried, along with the time interval that should elapse before retrying the hit
    func doRequest(url: URL,
                   requestBody: EdgeRequest,
                   requestHeaders: [String: String]? = [:],
                   responseCallback: ResponseCallback,
                   completion: @escaping (Bool, TimeInterval?) -> Void) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        guard let data = try? encoder.encode(requestBody) else {
            Log.warning(label: LOG_TAG, "doRequest - Failed to encode request to JSON, dropping this request")
            responseCallback.onComplete()
            completion(true, nil)
            return
        }

        let headers = defaultHeaders.merging(requestHeaders ?? [:]) { _, new in new}
        let payload = String(decoding: data, as: UTF8.self)

        let networkRequest: NetworkRequest = NetworkRequest(url: url,
                                                            httpMethod: HttpMethod.post,
                                                            connectPayload: payload,
                                                            httpHeaders: headers,
                                                            connectTimeout: EdgeConstants.NetworkKeys.DEFAULT_CONNECT_TIMEOUT,
                                                            readTimeout: EdgeConstants.NetworkKeys.DEFAULT_READ_TIMEOUT)
        Log.debug(label: LOG_TAG, "doRequest - Sending request to URL \(url.absoluteString) with headers: \(headers) and body: \n\(payload)")

        ServiceProvider.shared.networkService.connectAsync(networkRequest: networkRequest) { (connection: HttpConnection) in
            if connection.error != nil {
                // handle generic error
                self.handleError(connection: connection, responseCallback: responseCallback)
                responseCallback.onComplete()
                completion(true, nil) // don't retry
                return
            }

            if let responseCode = connection.responseCode {
                if responseCode == HttpResponseCodes.ok.rawValue {
                    Log.debug(label: self.LOG_TAG, "doRequest - Interact connection to Experience Edge was successful.")
                    self.handleContent(connection: connection,
                                       streaming: requestBody.meta?.konductorConfig?.streaming,
                                       responseCallback: responseCallback)
                    responseCallback.onComplete()
                    completion(true, nil) // successful request, return true
                } else if responseCode == HttpResponseCodes.noContent.rawValue {
                    // Successful collect requests do not return content
                    Log.debug(label: self.LOG_TAG, "doRequest - Collect connection to Experience Edge was successful.")
                    responseCallback.onComplete()
                    completion(true, nil) // successful request, return true
                } else if self.recoverableNetworkErrorCodes.contains(responseCode) {
                    Log.debug(label: self.LOG_TAG, "doRequest - Connection to Experience Edge returned recoverable error code \(responseCode)")
                    let retryHeader = connection.responseHttpHeader(forKey: EdgeConstants.NetworkKeys.HEADER_KEY_RETRY_AFTER)
                    var retryInterval = EdgeConstants.Defaults.RETRY_INTERVAL
                    // Do not currently support HTTP-date only parsing Ints for now. Konductor will only send back Retry-After as Ints.
                    if let retryHeader = retryHeader, let retryAfterInterval = TimeInterval(retryHeader) {
                        retryInterval = retryAfterInterval
                    }
                    completion(false, retryInterval) // failed, but recoverable so retry
                } else if responseCode == HttpResponseCodes.multiStatus.rawValue {
                    Log.debug(label: self.LOG_TAG,
                              "doRequest - Connection to Experience Edge was successful but encountered non-fatal errors/warnings. \(responseCode)")
                    self.handleContent(connection: connection,
                                       streaming: requestBody.meta?.konductorConfig?.streaming,
                                       responseCallback: responseCallback)
                    responseCallback.onComplete()
                    completion(true, nil) // non-fatal error, don't retry
                } else {
                    Log.warning(label: self.LOG_TAG, "doRequest - Connection to Experience Edge returned unrecoverable error code \(responseCode)")
                    self.handleError(connection: connection, responseCallback: responseCallback)
                    responseCallback.onComplete()
                    completion(true, nil) // failed, but unrecoverable, don't retry
                }
            } else {
                Log.warning(label: self.LOG_TAG, "doRequest - Connection to Experience Edge returned unknown error")
                self.handleError(connection: connection, responseCallback: responseCallback)
                responseCallback.onComplete()
                completion(true, nil) // failed, but unrecoverable, don't retry
            }
        }
    }

    /// Attempts the read the response from the `connection`and return the content via the `responseCallback`. This method should be used for handling 2xx server responses.
    /// In the eventuality of an error, this method returns false and an error message is logged.
    /// - Parameters:
    ///   - connection: `HttpConnection` containing the response from the server
    ///   - streaming: `Streaming` settings to be used to determine if streaming is enabled or not
    ///   - responseCallback: `ResponseCallback` that is invoked for each individual stream if streaming is enabled or once with the unwrapped response content
    func handleContent(connection: HttpConnection, streaming: Streaming?, responseCallback: ResponseCallback) {
        guard let unwrappedResponseString = connection.responseString else {
            Log.trace(label: LOG_TAG, "handleContent - No data to handle")
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
        var errorJson: String?
        if connection.error != nil {
            if let unwrappedResponseMessage = connection.responseMessage {
                errorJson = composeGenericErrorAsJson(plainTextErrorMessage: unwrappedResponseMessage)
            } else {
                errorJson = composeGenericErrorAsJson(plainTextErrorMessage: nil)
            }
        } else {
            errorJson = composeGenericErrorAsJson(plainTextErrorMessage: connection.responseString)
        }

        if let unwrappedErrorJson = errorJson {
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

        Log.trace(label: LOG_TAG, "handleStreamingResponse - Handle server response with streaming enabled")

        let splitResult = unwrappedResponseString.split(separator: lineFeedCharacter)

        var trimmingChars = CharacterSet()
        trimmingChars.insert(charactersIn: recordSerapator)
        for jsonResult in splitResult {
            let trimmedResult = jsonResult.trimmingCharacters(in: trimmingChars)
            responseCallback.onResponse(jsonResponse: trimmedResult)
        }
    }

    /// Composes a generic error (String with JSON format), containing a generic namespace and the provided error message, after removing the leading and trailing spaces.
    /// - Parameter plainTextErrorMessage: error message to be formatted; if nil/empty is provided, a default error message is returned.
    /// - Returns: the JSON formatted error as a String or nil if there was an error while serializing the error message
    private func composeGenericErrorAsJson(plainTextErrorMessage: String?) -> String? {
        if let unwrappedMessage = plainTextErrorMessage {
            // check if this is a JSON error response from Experience Edge, and if so pass it unchanged
            let data = Data(unwrappedMessage.utf8)

            if (try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]) != nil {
                return plainTextErrorMessage
            }
        }

        var unwrappedErrorMessage = plainTextErrorMessage ?? DEFAULT_GENERIC_ERROR_MESSAGE
        unwrappedErrorMessage = unwrappedErrorMessage.trimmingCharacters(in: .whitespacesAndNewlines)

        let errorDictionary = [EdgeConstants.JsonKeys.Response.Error.MESSAGE: unwrappedErrorMessage,
                               EdgeConstants.JsonKeys.Response.Error.NAMESPACE: DEFAULT_NAMESPACE]
        guard let json = try? JSONSerialization.data(withJSONObject: errorDictionary, options: []) else {
            Log.debug(label: LOG_TAG, "composeGenericErrorAsJson - Failed to serialize the error message.")
            return nil
        }
        guard let jsonString = String(data: json, encoding: .utf8) else {
            Log.debug(label: LOG_TAG, "composeGenericErrorAsJson - Failed to serialize the error message.")
            return nil
        }

        return jsonString
    }
}

extension String {
    /// Converts a String to Character. The `string` needs to have only one Character and it should not be empty.
    /// - Parameter string: String to be convert to Character
    /// - Returns: the result Character or nil if the conversion failed
    func convertToCharacter() -> Character? {
        guard self.count == 1 else {
            Log.trace(label: "convertToCharacter", "Unable to decode Character with multiple characters (\(self))")
            return nil
        }
        guard let character = self.first else {
            Log.trace(label: "convertToCharacter", "Unable to decode empty Character (\(self)")
            return nil
        }
        return character
    }
}

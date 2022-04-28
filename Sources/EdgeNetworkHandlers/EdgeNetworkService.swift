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

/// Edge Network request type:
///     - interact - makes request and expects a response
///     - consent - sets user consent and expects a response
enum EdgeRequestType: String {
    case interact
    case consent = "privacy/set-consent"
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
    private let SELF_TAG: String = "EdgeNetworkService"
    private let DEFAULT_GENERIC_ERROR_MESSAGE = "Request to Experience Edge failed with an unknown exception"
    private let DEFAULT_GENERIC_ERROR_TITLE = "Unexpected Error"
    private let recoverableNetworkErrorCodes: [Int] = [HttpResponseCodes.clientTimeout.rawValue,
                                                       HttpResponseCodes.tooManyRequests.rawValue,
                                                       HttpResponseCodes.badGateway.rawValue,
                                                       HttpResponseCodes.serviceUnavailable.rawValue,
                                                       HttpResponseCodes.gatewayTimeout.rawValue]
    private let waitTimeout: TimeInterval = max(EdgeConstants.NetworkKeys.DEFAULT_CONNECT_TIMEOUT, EdgeConstants.NetworkKeys.DEFAULT_READ_TIMEOUT) + 1
    private var defaultHeaders = [EdgeConstants.NetworkKeys.HEADER_KEY_ACCEPT: EdgeConstants.NetworkKeys.HEADER_VALUE_APPLICATION_JSON,
                                  EdgeConstants.NetworkKeys.HEADER_KEY_CONTENT_TYPE: EdgeConstants.NetworkKeys.HEADER_VALUE_APPLICATION_JSON]

    /// Builds the URL required for connections to Experience Edge
    /// - Parameters:
    ///   - endpoint: the endpoint for this URL
    ///   - configId: Edge configuration identifier
    ///   - requestId: batch request identifier
    /// - Returns: built URL or nil on error
    func buildUrl(endpoint: EdgeEndpoint, configId: String, requestId: String) -> URL? {
        guard let url = endpoint.url else { return nil }
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        urlComponents.queryItems = [
            URLQueryItem(name: EdgeConstants.NetworkKeys.REQUEST_PARAM_CONFIG_ID,
                         value: configId),
            URLQueryItem(name: EdgeConstants.NetworkKeys.REQUEST_PARAM_REQUEST_ID,
                         value: requestId)
        ]

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
                   requestBody: String?,
                   requestHeaders: [String: String]? = [:],
                   streaming: Streaming?,
                   responseCallback: ResponseCallback,
                   completion: @escaping (Bool, TimeInterval?) -> Void) {
        guard let payload = requestBody, !payload.isEmpty else {
            Log.warning(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Request body is nil/empty, dropping this request")
            responseCallback.onComplete()
            completion(true, nil)
            return
        }

        let headers = defaultHeaders.merging(requestHeaders ?? [:]) { _, new in new}

        let networkRequest: NetworkRequest =
            NetworkRequest(url: url,
                           httpMethod: HttpMethod.post,
                           connectPayload: payload,
                           httpHeaders: headers,
                           connectTimeout: EdgeConstants.NetworkKeys.DEFAULT_CONNECT_TIMEOUT,
                           readTimeout: EdgeConstants.NetworkKeys.DEFAULT_READ_TIMEOUT)
        Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Sending request to URL \(url.absoluteString) with headers: \(headers) and body: \n\(payload)")

        ServiceProvider.shared.networkService.connectAsync(networkRequest: networkRequest) { (connection: HttpConnection) in
            if connection.error != nil {
                // handle generic error
                self.handleError(connection: connection, responseCallback: responseCallback)
                responseCallback.onComplete()
                completion(true, nil) // don't retry
                return
            }

            guard let responseCode = connection.responseCode else {
                Log.warning(label: EdgeConstants.LOG_TAG, "\(self.SELF_TAG) - Connection to Experience Edge returned unknown error")
                self.handleError(connection: connection, responseCallback: responseCallback)
                responseCallback.onComplete()
                completion(true, nil) // failed, but unrecoverable, don't retry
                return
            }

            self.handleResponseWith(responseCode: responseCode,
                                    connection: connection,
                                    streaming: streaming,
                                    responseCallback: responseCallback,
                                    completion: completion)
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
            Log.trace(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - No content to handle")
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

    /// Handles the network response based on the response code
    /// - Parameters:
    ///   - responseCode: response code from the `HttpConnection`
    ///   - connection: `HttpConnection` containing the network response info
    ///   - streaming: `Streaming` settings if they were enabled for this response
    ///   - responseCallback: `ResponseCallback` to be invoked once the server response is received
    ///   - completion: a closure that is invoked with true if the hit should not be retried, false if the hit should be retried, along with the time interval that should elapse b
    private func handleResponseWith(responseCode: Int,
                                    connection: HttpConnection,
                                    streaming: Streaming?,
                                    responseCallback: ResponseCallback,
                                    completion: @escaping (Bool, TimeInterval?) -> Void) {

        switch responseCode {
        case HttpResponseCodes.ok.rawValue:
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Connection to Experience Edge was successful.")
            self.handleContent(connection: connection,
                               streaming: streaming,
                               responseCallback: responseCallback)
            responseCallback.onComplete()
            completion(true, nil) // successful request, return true
        case HttpResponseCodes.noContent.rawValue:
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Connection to Experience Edge was successful, no content returned.")
            responseCallback.onComplete()
            completion(true, nil) // successful request, return true
        case HttpResponseCodes.multiStatus.rawValue:
            Log.debug(label: EdgeConstants.LOG_TAG,
                      "\(SELF_TAG) - Connection to Experience Edge was successful, but encountered non-fatal errors/warnings. \(responseCode)")
            self.handleContent(connection: connection,
                               streaming: streaming,
                               responseCallback: responseCallback)
            responseCallback.onComplete()
            completion(true, nil) // non-fatal error, don't retry
        default:
            if self.recoverableNetworkErrorCodes.contains(responseCode) {
                Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Connection to Experience Edge returned recoverable error code \(responseCode)")
                let retryHeader = connection.responseHttpHeader(forKey: EdgeConstants.NetworkKeys.HEADER_KEY_RETRY_AFTER)
                var retryInterval = EdgeConstants.Defaults.RETRY_INTERVAL
                // Do not currently support HTTP-date only parsing Ints for now. Konductor will only send back Retry-After as Ints.
                if let retryHeader = retryHeader, let retryAfterInterval = TimeInterval(retryHeader) {
                    retryInterval = retryAfterInterval
                }
                completion(false, retryInterval) // failed, but recoverable so retry
            } else {
                Log.warning(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Connection to Experience Edge returned unrecoverable error code \(responseCode)")
                self.handleError(connection: connection, responseCallback: responseCallback)
                responseCallback.onComplete()
                completion(true, nil) // failed, but unrecoverable, don't retry
            }
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

        Log.trace(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Handle server response with streaming enabled")

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

        let eventError = EdgeEventError(title: DEFAULT_GENERIC_ERROR_TITLE, detail: unwrappedErrorMessage)

        guard let json = try? JSONEncoder().encode(eventError) else {
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Failed to serialize the error message.")
            return nil
        }
        guard let jsonString = String(data: json, encoding: .utf8) else {
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Failed to convert the error message to string.")
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
            Log.trace(label: EdgeConstants.LOG_TAG, "convertToCharacter - Unable to decode Character with multiple characters (\(self))")
            return nil
        }
        guard let character = self.first else {
            Log.trace(label: EdgeConstants.LOG_TAG, "convertToCharacter - Unable to decode empty Character (\(self)")
            return nil
        }
        return character
    }
}

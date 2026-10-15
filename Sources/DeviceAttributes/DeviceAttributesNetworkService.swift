//
// Copyright 2026 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPServices
import Foundation

/// Network sender for the `mobile/device-attributes` endpoint. Independent of `EdgeNetworkService`:
/// the response is plain (non-streamed) JSON and has no interact error/207 semantics.
class DeviceAttributesNetworkService {
    private let SELF_TAG = "DeviceAttributesNetworkService"

    /// Same recoverable set as `EdgeNetworkService`, so retry behavior matches the interact path.
    private let recoverableResponseCodes = Set(NetworkServiceConstants.RECOVERABLE_ERROR_CODES +
                                                [HttpResponseCodes.tooManyRequests.rawValue,
                                                 HttpResponseCodes.badGateway.rawValue,
                                                 HttpResponseCodes.insufficientStorage.rawValue])

    private let defaultHeaders = [EdgeConstants.NetworkKeys.HEADER_KEY_ACCEPT: EdgeConstants.NetworkKeys.HEADER_VALUE_APPLICATION_JSON,
                                  EdgeConstants.NetworkKeys.HEADER_KEY_CONTENT_TYPE: EdgeConstants.NetworkKeys.HEADER_VALUE_APPLICATION_JSON]

    /// Builds the device-attributes URL: `<endpoint>?configId=<datastreamId>&requestId=<requestId>`.
    func buildUrl(endpoint: EdgeEndpoint, datastreamId: String, requestId: String) -> URL? {
        guard let url = endpoint.url,
              var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        urlComponents.queryItems = [
            URLQueryItem(name: EdgeConstants.NetworkKeys.REQUEST_PARAM_CONFIG_ID, value: datastreamId),
            URLQueryItem(name: EdgeConstants.NetworkKeys.REQUEST_PARAM_REQUEST_ID, value: requestId)
        ]
        return urlComponents.url
    }

    /// Sends the device-attributes request and reports the classified outcome.
    /// - Parameters:
    ///   - url: request URL
    ///   - body: JSON request body
    ///   - headers: additional request headers, merged over the default JSON headers
    ///   - completion: invoked with the classified `DeviceAttributesNetworkResult`
    func send(url: URL, body: String, headers: [String: String], completion: @escaping (DeviceAttributesNetworkResult) -> Void) {
        let requestHeaders = defaultHeaders.merging(headers) { _, new in new }
        let networkRequest = NetworkRequest(url: url,
                                            httpMethod: .post,
                                            connectPayload: body,
                                            httpHeaders: requestHeaders,
                                            connectTimeout: EdgeConstants.NetworkKeys.DEFAULT_CONNECT_TIMEOUT,
                                            readTimeout: EdgeConstants.NetworkKeys.DEFAULT_READ_TIMEOUT)
        Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Sending device attributes request to URL \(url.absoluteString) with body: \(body)")

        ServiceProvider.shared.networkService.connectAsync(networkRequest: networkRequest) { connection in
            completion(self.classify(connection: connection, url: url))
        }
    }

    /// Classifies the `connection` into success, retry or failure.
    func classify(connection: HttpConnection, url: URL) -> DeviceAttributesNetworkResult {
        if let error = connection.error {
            if let urlError = error as? URLError, urlError.isRecoverable {
                let retryInterval = EdgeConstants.Defaults.RETRY_INTERVAL
                Log.debug(label: EdgeConstants.LOG_TAG,
                          "\(SELF_TAG) - Device attributes request with url \(url.absoluteString) failed with recoverable URL error " +
                          "(\(urlError.errorCode)). Will retry in \(retryInterval) seconds.")
                return .retry(interval: retryInterval)
            }
            Log.warning(label: EdgeConstants.LOG_TAG,
                        "\(SELF_TAG) - Device attributes request with url \(url.absoluteString) failed with unrecoverable error " +
                        "(\(error.localizedDescription)).")
            return .failed(httpStatus: connection.responseCode)
        }

        guard let responseCode = connection.responseCode else {
            Log.warning(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Device attributes request with url \(url.absoluteString) failed with unknown error.")
            return .failed(httpStatus: nil)
        }

        if EdgeConstants.DeviceAttributes.SUCCESS_RESPONSE_CODES.contains(responseCode) {
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Device attributes request was successful (\(responseCode)).")
            return .success(httpStatus: responseCode, body: connection.responseString)
        }

        if recoverableResponseCodes.contains(responseCode) {
            var retryInterval = EdgeConstants.Defaults.RETRY_INTERVAL
            // Only integer Retry-After values are supported, matching the interact path.
            if let retryHeader = connection.responseHttpHeader(forKey: EdgeConstants.NetworkKeys.HEADER_KEY_RETRY_AFTER),
               let retryAfter = TimeInterval(retryHeader), retryAfter > 0 {
                retryInterval = retryAfter
            }
            Log.debug(label: EdgeConstants.LOG_TAG,
                      "\(SELF_TAG) - Device attributes request returned recoverable code \(responseCode). Will retry in \(retryInterval) seconds.")
            return .retry(interval: retryInterval)
        }

        logUnrecoverableResponse(responseCode: responseCode, body: connection.responseString)
        return .failed(httpStatus: responseCode)
    }

    /// Logs an unrecoverable response, including the problem-JSON `title` and `report.errors` when present (e.g. HTTP 400).
    private func logUnrecoverableResponse(responseCode: Int, body: String?) {
        typealias Keys = EdgeConstants.DeviceAttributes.ResponseKeys
        var details = ""
        if let body = body,
           let json = try? JSONSerialization.jsonObject(with: Data(body.utf8)) as? [String: Any] {
            if let title = json[Keys.TITLE] as? String {
                details += " title: \(title)"
            }
            if let errors = (json[Keys.REPORT] as? [String: Any])?[Keys.ERRORS] {
                details += " errors: \(errors)"
            }
        }
        Log.warning(label: EdgeConstants.LOG_TAG,
                    "\(SELF_TAG) - Device attributes request returned unrecoverable code \(responseCode).\(details)")
    }
}

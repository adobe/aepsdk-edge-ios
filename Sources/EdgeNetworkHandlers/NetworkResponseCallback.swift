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

/// Response callback used for handling the responses from the Adobe Experience Edge network connections
class NetworkResponseCallback: ResponseCallback {
    private let requestId: String
    private let networkResponseHandler: NetworkResponseHandler

    /// Corresponding `requestId` for which the NetworkResponseCallback will be invoked
    /// - Parameter requestId: unique network request identifier
    /// - Parameter responseHandler: the `NetworkResponseHandler` instance used for processing the response
    init(requestId: String, responseHandler: NetworkResponseHandler) {
        self.requestId = requestId
        self.networkResponseHandler = responseHandler
    }

    /// Processes the success responses
    /// - Parameter jsonResponse: success response from the server, JSON formatted
    func onResponse(jsonResponse: String) {
        networkResponseHandler.processResponseOnSuccess(jsonResponse: jsonResponse, requestId: requestId)
    }

    /// Processes the error responses
    /// - Parameter jsonError: error response from the server or generic error if unknown, JSON formatted
    func onError(jsonError: String) {
        networkResponseHandler.processResponseOnError(jsonError: jsonError, requestId: requestId)
    }

    /// Removes waiting events for current `requestId` and unregisters their corresponding completion handlers
    func onComplete() {
        guard let removedWaitingEvents: [String] = self.networkResponseHandler.removeWaitingEvents(requestId: requestId) else { return }

        // unregister currently known completion handlers
        for eventId in removedWaitingEvents {
            CompletionHandlersManager.shared.unregisterCompletionHandler(forRequestEventId: eventId)
        }
    }
}

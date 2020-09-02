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

/// Use this class to register `ExperiencePlatformResponseHandler`(s) for a specific event identifier
/// and get notified once a response is received from the Experience Edge or when an error occurred. This class uses a `ThreadSafeDictionary` for the internal mapping.
class ResponseCallbackHandler {
    private let TAG = "ResponseCallbacksHandler"
    private var responseHandlers = ThreadSafeDictionary<String, ExperiencePlatformResponseHandler>(identifier: "com.adobe.experiencePlaftorm.responseHandlers")
    static let shared = ResponseCallbackHandler()

    /// Registers a `ExperiencePlatformResponseHandler` for the specified `requestEventId`. This handler will
    /// be invoked whenever a response event for the same requestEventId was seen.
    ///
    /// - Parameters:
    ///   - requestEventId: unique event identifier for which the response callback is registered; should not be empty
    ///   - responseHandler: the `ExperiencePlatformResponseHandler` that needs to be registered, should not be nil
    func registerResponseHandler(requestEventId: String, responseHandler: ExperiencePlatformResponseHandler?) {
        guard let unwrappedResponseHandler = responseHandler else { return }
        guard !requestEventId.isEmpty else {
            Log.warning(label: TAG, "Failed to register response handler because of empty request event id.")
            return
        }

        Log.trace(label: TAG, "Registering callback for Edge response with request event id \(requestEventId).")
        responseHandlers[requestEventId] = unwrappedResponseHandler
    }

    /// Unregisters a `ExperiencePlatformResponseHandler` for the specified `requestEventId`. After this operation,
    /// the associated response handler will not be invoked anymore for any Edge response events.
    /// - Parameter requestEventId: unique event identifier for experience platform events; should not be empty
    func unregisterResponseHandler(requestEventId: String) {
        guard !requestEventId.isEmpty else { return }

        if responseHandlers[requestEventId] != nil {
            responseHandlers[requestEventId] = nil
            Log.trace(label: TAG, "Removing callback for Edge response with request unique id \(requestEventId).")
        }
    }

    /// Invokes the response handler for the unique event identifier (if any callback was previously registered for this id).
    /// - Parameter eventData: data received from an ExEdge response event, containing the event handle payload and the request event identifier
    /// - Parameter requestEventId: the request event identifier to be called with the provided `eventData`
    func invokeResponseHandler(eventData: [String: Any], requestEventId: String?) {
        guard let unwrappedRequestEventId = requestEventId, !unwrappedRequestEventId.isEmpty else {
            return
        }

        guard let responseHandler = responseHandlers[unwrappedRequestEventId] else {
            Log.trace(label: TAG, "Unable to find response handler for requestEventId (\(unwrappedRequestEventId)), not invoked")
            return
        }

        Log.trace(label: TAG, "Invoking registered onResponse handler for requestEventId (\(unwrappedRequestEventId)) with data \(eventData)")
        responseHandler.onResponse(data: eventData)
    }
}

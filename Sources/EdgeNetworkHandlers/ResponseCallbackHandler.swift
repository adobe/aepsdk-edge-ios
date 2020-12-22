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

/// Use this class to register `EdgeResponseHandler`(s) for a specific event identifier
/// and get notified for each response handle/error received from the Experience Edge; there can be none, one or multiple such calls.
/// When using a completion handler, all the event handles and errors will be returned at once.
/// This class uses a `ThreadSafeDictionary` for the internal mapping.
class ResponseCallbackHandler {
    private let TAG = "ResponseCallbacksHandler"
    private var responseHandlers =
        ThreadSafeDictionary<String, EdgeResponseHandler>(identifier: "com.adobe.edge.responseHandlers")
    private var completionHandlers =
        ThreadSafeDictionary<String, (([EdgeEventHandle], [EdgeEventError]) -> Void)>(identifier: "com.adobe.edge.completionHandlers")

    // edge response handles for a event request id (key)
    private var edgeEventHandles =
        ThreadSafeDictionary<String, [EdgeEventHandle]>(identifier: "com.adobe.edge.edgeHandlesList")

    // edge errors for a event request id (key)
    private var edgeEventErrors =
        ThreadSafeDictionary<String, [EdgeEventError]>(identifier: "com.adobe.edge.edgeErrorsList")
    static let shared = ResponseCallbackHandler()

    /// Registers a `EdgeResponseHandler` for the specified `requestEventId`. This handler is
    /// invoked whenever a response event for the same `requestEventId` is returned by the server.
    ///
    /// - Parameters:
    ///   - requestEventId: unique event identifier for which the response callback is registered; should not be empty
    ///   - responseHandler: the `EdgeResponseHandler` that needs to be registered, should not be nil
    func registerResponseHandler(requestEventId: String, responseHandler: EdgeResponseHandler?) {
        guard let unwrappedResponseHandler = responseHandler else { return }
        guard !requestEventId.isEmpty else {
            Log.warning(label: TAG, "Failed to register response handler because of empty request event id.")
            return
        }

        Log.trace(label: TAG, "Registering callback for Edge response with request event id \(requestEventId).")
        responseHandlers[requestEventId] = unwrappedResponseHandler
    }

    /// Registers a completion handler for the specified `requestEventId`. This handler is invoked when the entire Edge response content has been
    /// handled entirely by the Edge extension, containing a list of `EdgeEventHandle` and a list of `EdgeEventError`. These lists can be empty or
    /// can contain one or multiple items based on the request and the server side response.
    ///
    /// - Parameters:
    ///   - requestEventId: unique event identifier for which the response callback is registered; should not be empty
    ///   - completionHandler: the completion handler that needs to be registered, should not be nil
    func registerCompletionHandler(requestEventId: String, completionHandler: (([EdgeEventHandle], [EdgeEventError]) -> Void)?) {
        guard let unwrappedCompletion = completionHandler else { return }
        guard !requestEventId.isEmpty else {
            Log.warning(label: TAG, "Failed to register completion handler because of empty request event id.")
            return
        }

        completionHandlers[requestEventId] = unwrappedCompletion
    }

    /// Calls onComplete and unregisters a `EdgeResponseHandler` for the specified `requestEventId`. After this operation,
    /// the associated response handler or completion handler is removed and no longer called.
    /// - Parameter requestEventId: unique event identifier for experience events; should not be empty
    func unregisterCallbacks(requestEventId: String) {
        guard !requestEventId.isEmpty else { return }
        if let responseHandler = responseHandlers[requestEventId] {
            responseHandler.onComplete()
            _ = responseHandlers.removeValue(forKey: requestEventId)
        }

        if let completionHandler = completionHandlers[requestEventId] {
            completionHandler(edgeEventHandles[requestEventId] ?? [], edgeEventErrors[requestEventId] ?? [])
            _ = completionHandlers.removeValue(forKey: requestEventId)
        }

        _ = edgeEventHandles.removeValue(forKey: requestEventId)
        _ = edgeEventErrors.removeValue(forKey: requestEventId)

        Log.trace(label: TAG, "Removing completion handlers for Edge response with request unique id \(requestEventId).")
    }

    /// Updates the list of `EdgeEventHandle`(s) for current `requestEventId` and calls onResponseUpdate if a `ResponseHandler` is registered.
    /// - Parameters:
    ///   - eventHandle: newly received event handle
    ///   - requestEventId: the request event identifier associated with this event handle
    func eventHandleReceived(_ eventHandle: EdgeEventHandle, requestEventId: String?) {
        guard let unwrappedRequestEventId = requestEventId, !unwrappedRequestEventId.isEmpty else { return }
        if edgeEventHandles[unwrappedRequestEventId] != nil {
            edgeEventHandles[unwrappedRequestEventId]?.append(eventHandle)
        } else {
            edgeEventHandles[unwrappedRequestEventId] = [eventHandle]
        }
        invokeResponseHandler(eventHandle: eventHandle, eventError: nil, requestEventId: unwrappedRequestEventId)
    }

    /// Updates the list of `EdgeEventError`(s) for current `requestEventId` and calls onErrorUpdate if a `ResponseHandler` is registered.
    /// - Parameters:
    ///   - eventError: newly received error/warning message
    ///   - requestEventId: the request event identifier associated with this event handle
    func eventErrorReceived(_ eventError: EdgeEventError, requestEventId: String?) {
        guard let unwrappedRequestEventId = requestEventId, !unwrappedRequestEventId.isEmpty else {
            return
        }
        if edgeEventErrors[unwrappedRequestEventId] != nil {
            edgeEventErrors[unwrappedRequestEventId]?.append(eventError)
        } else {
            edgeEventErrors[unwrappedRequestEventId] = [eventError]
        }
        invokeResponseHandler(eventHandle: nil, eventError: eventError, requestEventId: unwrappedRequestEventId)
    }

    /// Invokes the response handler for the unique event identifier (if any callback was previously registered for this id).
    /// - Parameter eventData: data received from the Edge response event, containing the event handle payload and the request event identifier
    /// - Parameter requestEventId: the request event identifier to be called with the provided `eventData`, should not be empty
    private func invokeResponseHandler(eventHandle: EdgeEventHandle?,
                                       eventError: EdgeEventError?,
                                       requestEventId: String) {
        guard let responseHandler = responseHandlers[requestEventId] else {
            Log.trace(label: TAG, "Unable to find response handler for requestEventId (\(requestEventId)), not invoked")
            return
        }

        if let handle = eventHandle {
            Log.trace(label: TAG, "Invoking onResponseUpdate handler for requestEventId (\(requestEventId))")
            responseHandler.onResponseUpdate(eventHandle: handle)
        }

        if let error = eventError {
            Log.trace(label: TAG, "Invoking onErrorUpdate handler for requestEventId (\(requestEventId))")
            responseHandler.onErrorUpdate(error: error)
        }
    }
}

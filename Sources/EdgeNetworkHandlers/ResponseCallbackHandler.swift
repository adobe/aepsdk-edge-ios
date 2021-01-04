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

/// When registering a completion handler for a request event, all the event handles will be returned at once when the entire streamed response was returned.
/// This class uses a `ThreadSafeDictionary` for the internal mapping.
class ResponseCallbackHandler {
    private let TAG = "ResponseCallbacksHandler"
    private var completionHandlers =
        ThreadSafeDictionary<String, (([EdgeEventHandle]) -> Void)>(identifier: "com.adobe.edge.completionHandlers")

    // edge response handles for a event request id (key)
    private var edgeEventHandles =
        ThreadSafeDictionary<String, [EdgeEventHandle]>(identifier: "com.adobe.edge.edgeHandlesList")

    static let shared = ResponseCallbackHandler()

    /// Registers a completion handler for the specified `requestEventId`. This handler is invoked when the Edge response content has been
    /// handled entirely by the Edge extension, containing a list of `EdgeEventHandle`(s). This list can be empty or can contain one or multiple items
    /// based on the request and the server side response.
    ///
    /// - Parameters:
    ///   - requestEventId: unique event identifier for which the response callback is registered; should not be empty
    ///   - completionHandler: the completion handler that needs to be registered, should not be nil
    func registerCompletionHandler(requestEventId: String, completion: (([EdgeEventHandle]) -> Void)?) {
        guard let unwrappedCompletion = completion else { return }
        guard !requestEventId.isEmpty else {
            Log.warning(label: TAG, "Failed to register completion handler because of empty request event id.")
            return
        }

        Log.trace(label: TAG, "Registering completion handler for Edge response with request event id \(requestEventId).")
        completionHandlers[requestEventId] = unwrappedCompletion
    }

    /// Calls the registered completion handler (if any) with the collected `EdgeEventHandle`(s). After this operation,
    /// the associated completion handler is removed and no longer called.
    /// - Parameter requestEventId: unique event identifier for experience events; should not be empty
    func unregisterCompletionHandler(requestEventId: String) {
        guard !requestEventId.isEmpty else { return }

        if let completionHandler = completionHandlers[requestEventId] {
            completionHandler(edgeEventHandles[requestEventId] ?? [])
            _ = completionHandlers.removeValue(forKey: requestEventId)
            Log.trace(label: TAG, "Removing completion handler for Edge response with request event id \(requestEventId).")
        }

        _ = edgeEventHandles.removeValue(forKey: requestEventId)
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
    }
}

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

import AEPServices
import Foundation

class CompletionHandlersManager {
    private let TAG = "CompletionHandlersManager"
    private var completionHandlers = [String: (([EdgeEventHandle]) -> Void)]()
    // edge response handles for a event request id (key)
    private var edgeEventHandles = [String: [EdgeEventHandle]]()

    static let shared = CompletionHandlersManager()
    private let queue = DispatchQueue(label: "com.adobe.edge.completionHandlersManager.queue")

    /// Registers a completion handler for the specified `requestEventId`. This handler is invoked when the Edge response content has been
    /// handled entirely by the Edge extension, containing a list of `EdgeEventHandle`(s). This list can be empty or can contain one or multiple items
    /// based on the request and the server side response.
    ///
    /// - Parameters:
    ///   - forRequestEventId: unique event identifier for which the completion handler is registered; should not be empty
    ///   - completionHandler: the completion handler that needs to be registered, should not be nil
    func registerCompletionHandler(forRequestEventId: String, completion: (([EdgeEventHandle]) -> Void)?) {
        guard let unwrappedCompletion = completion else { return }
        guard !forRequestEventId.isEmpty else {
            Log.warning(label: TAG, "Failed to register completion handler because of empty request event id.")
            return
        }

        queue.async { [weak self] in

            guard let self = self else { return }

            Log.trace(label: TAG, "Registering completion handler for Edge response with request event id \(forRequestEventId).")
            completionHandlers[forRequestEventId] = unwrappedCompletion
        }

    }

    /// Calls the registered completion handler (if any) with the collected `EdgeEventHandle`(s). After this operation,
    /// the associated completion handler is removed and no longer called.
    /// - Parameter forRequestEventId: unique event identifier for experience events; should not be empty
    func unregisterCompletionHandler(forRequestEventId: String) {
        guard !forRequestEventId.isEmpty else { return }

        queue.async { [weak self] in

            guard let self = self else { return }

            if let completionHandler = completionHandlers[forRequestEventId] {
                completionHandler(edgeEventHandles[forRequestEventId] ?? [])

                Log.trace(label: TAG, "Removing completion handler for Edge response with request event id \(forRequestEventId).")
                completionHandlers.removeValue(forKey: forRequestEventId)
            }

            edgeEventHandles.removeValue(forKey: forRequestEventId)
        }

    }

    /// Updates the list of `EdgeEventHandle`(s) for current `requestEventId`.
    /// - Parameters:
    ///   - forRequestEventId: the request event identifier associated with this event handle
    ///   - eventHandle: newly received event handle
    func eventHandleReceived(forRequestEventId: String?, _ eventHandle: EdgeEventHandle) {
        guard let unwrappedRequestEventId = forRequestEventId, !unwrappedRequestEventId.isEmpty else { return }

        queue.async {[weak self] in

            guard let self = self else { return }

            edgeEventHandles[unwrappedRequestEventId, default: []].append(eventHandle)
        }

    }
}

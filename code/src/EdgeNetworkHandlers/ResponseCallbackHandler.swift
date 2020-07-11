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

/// Use this class to register `ExperiencePlatformResponseHandler`(s) for a specific event identifier
/// and get notified once a response is received from the Experience Edge or when an error occurred. This class uses a `ThreadSafeDictionary` for the internal mapping.
class ResponseCallbackHandler {
    private let TAG = "ResponseCallbacksHandler"
    private var responseHandlers = ThreadSafeDictionary<String, ExperiencePlatformResponseHandler>(identifier: "com.adobe.experiencePlaftorm.responseHandlers")
    static let shared = ResponseCallbackHandler()
    
    /// Registers a `ExperiencePlatformResponseHandler` for the specified `uniqueEventId`. This handler will
    /// be invoked whenever a response event for the same uniqueEventId was seen.
    ///
    /// - Parameters:
    ///   - uniqueEventId: unique event identifier for which the response callback is registered; should not be empty
    ///   - responseHandler: the `ExperiencePlatformResponseHandler` that needs to be registered, should not be nil
    func registerResponseHandler(uniqueEventId: String, responseHandler: ExperiencePlatformResponseHandler?) {
        guard let unwrappedResponseHandler = responseHandler else { return }
        guard !uniqueEventId.isEmpty else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Failed to register response handler because of empty unique event id.")
            return
        }
        
        ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Registering callback for Data platform response with unique id \(uniqueEventId).")
        responseHandlers[uniqueEventId] = unwrappedResponseHandler
    }
    
    /// Unregisters a `ExperiencePlatformResponseHandler` for the specified `uniqueEventId`. After this operation,
    /// the associated response handler will not be invoked anymore for any ExEdge response events.
    /// - Parameter uniqueEventId: unique event identifier for data platform events; should not be empty
    func unregisterResponseHandler(uniqueEventId: String) {
        guard !uniqueEventId.isEmpty else { return }
        if responseHandlers.removeValue(forKey: uniqueEventId) != nil {
            ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Removing callback for Data platform response with unique id \(uniqueEventId).")
        }
    }
    
    /// Invokes the response handler for the unique event identifier (if any callback was previously registered for this id).
    /// - Parameter eventData: data received from an ExEdge response event, containing the event handle payload and the request event identifier
    func invokeResponseHandler(eventData: [String: Any]) {
        let requestEventId: String? = eventData[ExperiencePlatformConstants.EventDataKeys.requestEventId] as? String
        guard let unwrappedRequestEventId = requestEventId, !unwrappedRequestEventId.isEmpty else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Failed to invoke the response handler because of unspecified requestEventId, data received \(eventData)")
            return
        }
        
        guard let responseHandler = responseHandlers[unwrappedRequestEventId] else {
            ACPCore.log(ACPMobileLogLevel.verbose, tag: TAG, message: "Unable to find response handler for requestEventId (\(unwrappedRequestEventId)), not invoked")
            return
        }
        
        ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Invoking registered onResponse handler for requestEventId (\(unwrappedRequestEventId)) with data \(eventData)")
        responseHandler.onResponse(data: eventData)
        
    }
}

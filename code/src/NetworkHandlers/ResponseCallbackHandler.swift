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
/// and get notified once a response is received from the Experience Edge or when an error occurred.
class ResponseCallbackHandler {
    private let TAG = "ResponseCallbacksHandler"
    private var responseHandlers = ThreadSafeDictionary<String, ExperiencePlatformResponseHandler>(identifier: "com.adobe.experiencePlaftorm.responseHandlers")
    static let shared = ResponseCallbackHandler()
    
    func registerResponseHandler(uniqueEventId: String, responseHandler: ExperiencePlatformResponseHandler?) {
        guard let unwrappedResponseHandler = responseHandler else { return }
        guard !uniqueEventId.isEmpty else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Failed to register response handler because of empty unique event id.")
            return
        }
        
        ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Registering callback for Data platform response with unique id \(uniqueEventId).")
        responseHandlers[uniqueEventId] = unwrappedResponseHandler
    }
    
    func unregisterResponseHandler(uniqueEventId: String) {
        guard !uniqueEventId.isEmpty else { return }
        if responseHandlers.removeValue(forKey: uniqueEventId) != nil {
            ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Removing callback for Data platform response with unique id \(uniqueEventId).")
        }
    }
    
    func invokeResponseHandler(eventData: [String: Any]) {
        let requestEventId: String? = eventData[ExperiencePlatformConstants.EventDataKeys.requestEventId] as? String
        guard let unwrappedRequestEventId = requestEventId, !unwrappedRequestEventId.isEmpty else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Failed to invoke the response handler because of unspecified requestEventId, data received \(eventData)")
            return
        }
        
        guard let responseHandler = responseHandlers[unwrappedRequestEventId] else { return }
        
        ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Invoking registered onResponse handler for requestEventId (\(unwrappedRequestEventId)) with data \(eventData)")
        responseHandler.onResponse(data: eventData)
        
    }
}

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

class NetworkResponseHandler {
    private let LOG_TAG = "NetworkResponseHandler"
    
    func addWaitingEvents(requestId:String, batchedEvents: [ACPExtensionEvent]) {
        // TODO AMSDK-9842
    }
    
    func removeWaitingEvents(requestId: String) -> [String] {
        // TODO AMSDK-9842
        return []
    }
    
    func getWaitingEvents(requestId: String) -> [String] {
        // TODO AMSDK-9842
        return []
    }
    
    func processResponseOnSuccess(jsonResponse:String, requestId:String) {
        guard let data = jsonResponse.data(using: .utf8) else {
            return
        }
        
        if let edgeResponse = try? JSONDecoder().decode(EdgeResponse.self, from: data) {
            ACPCore.log(ACPMobileLogLevel.debug, tag:LOG_TAG, message:"processResponseOnSuccess - Received server response:\n \(jsonResponse), request id \(requestId)")
            
            // handle the event handles, errors and warnings coming from server
            dispatchEventHandles(handlesArray: edgeResponse.handle, requestId: requestId)
            dispatchEventErrors(errorsArray: edgeResponse.errors, requestId: requestId, isError: true)
            dispatchEventErrors(errorsArray: edgeResponse.warnings, requestId: requestId, isError: false)
        } else {
            ACPCore.log(ACPMobileLogLevel.warning, tag:LOG_TAG,
                    message:"processResponseOnSuccess - The conversion to JSON failed for server response: \(jsonResponse), request id \(requestId)")
        }
    }
    
    func processResponseOnError(jsonError:String, requestId:String) {
        // TODO AMSDK-9555, AMSDK-9842
    }
    
    private func dispatchEventHandles(handlesArray: [[String: AnyCodable]]?, requestId: String) {
        guard let unwrappedEventHandles = handlesArray, !unwrappedEventHandles.isEmpty else {
            ACPCore.log(ACPMobileLogLevel.debug, tag:LOG_TAG, message:"dispatchEventHandles - Received nil/empty event handle array, nothing to handle")
            return
        }
        
        ACPCore.log(ACPMobileLogLevel.verbose, tag:LOG_TAG, message:"dispatchEventHandles - Processing \(unwrappedEventHandles.count) event handle(s) for request id: \(requestId)")
        // TODO AMSDK-9555, AMSDK-9842
    }
    
    private func dispatchEventErrors(errorsArray : [[String: AnyCodable]]?, requestId: String, isError:Bool) {
        // TODO AMSDK-9555, AMSDK-9842
    }
}

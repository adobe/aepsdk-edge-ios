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

/// A `HitProcessing` which handles the processing of `EdgeHit`s
class EdgeHitProcessor: HitProcessing {
    private let LOG_TAG = "EdgeHitProcessor"
    private var networkService: EdgeNetworkService
    private var networkResponseHandler: NetworkResponseHandler
    private var getSharedState: (String, Event?) -> SharedStateResult?
    let retryInterval = Constants.NetworkKeys.RETRY_INTERVAL

    init(networkService: EdgeNetworkService, networkResponseHandler: NetworkResponseHandler, getSharedState: @escaping (String, Event?) -> SharedStateResult?) {
        self.networkService = networkService
        self.networkResponseHandler = networkResponseHandler
        self.getSharedState = getSharedState
    }

    func processHit(entity: DataEntity, completion: @escaping (Bool) -> Void) {
        guard let data = entity.data, let edgeHit = try? JSONDecoder().decode(EdgeHit.self, from: data) else {
            // can't convert data to hit, unrecoverable error, move to next hit
            Log.debug(label: LOG_TAG, "processHit - Failed to decode edge hit with id '\(entity.uniqueIdentifier)'.")
            completion(true)
            return
        }

        // get Assurance integration id and include it in to the requestHeaders
        var requestHeaders: [String: String] = [:]
        if let assuranceSharedState = getSharedState(Constants.SharedState.Assurance.STATE_OWNER_NAME, edgeHit.event)?.value {
            if let assuranceIntegrationId = assuranceSharedState[Constants.SharedState.Assurance.INTEGRATION_ID] as? String {
                requestHeaders[Constants.NetworkKeys.HEADER_KEY_AEP_VALIDATION_TOKEN] = assuranceIntegrationId
            }
        }

        guard let url = networkService.buildUrl(requestType: ExperienceEdgeRequestType.interact,
                                                     configId: edgeHit.configId,
                                                     requestId: edgeHit.requestId) else {
                                                        Log.debug(label: LOG_TAG,
                                                                  "handleExperienceEventRequest - Failed to build the URL, dropping current event '\(edgeHit.event.id.uuidString)'.")
                                                        completion(true)
                                                        return
        }

        let callback = NetworkResponseCallback(requestId: edgeHit.requestId, responseHandler: networkResponseHandler)
        networkService.doRequest(url: url,
                                 requestBody: edgeHit.request,
                                 requestHeaders: requestHeaders,
                                 responseCallback: callback,
                                 completion: completion)
    }

}

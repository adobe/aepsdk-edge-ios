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

/// A `HitProcessing` which handles the processing of `EdgeHit`s
class EdgeHitProcessor: HitProcessing {
    private let LOG_TAG = "EdgeHitProcessor"
    private var networkService: EdgeNetworkService
    private var networkResponseHandler: NetworkResponseHandler
    var retryInterval = TimeInterval(5)

    init(networkService: EdgeNetworkService, networkResponseHandler: NetworkResponseHandler) {
        self.networkService = networkService
        self.networkResponseHandler = networkResponseHandler
    }

    func processHit(entity: DataEntity, completion: @escaping (Bool) -> Void) {
        guard let data = entity.data, let edgeHit = try? JSONDecoder().decode(EdgeHit.self, from: data) else {
            // can't convert data to hit, unrecoverable error, move to next hit
            Log.debug(label: LOG_TAG, "processHit - Failed to decode edge hit '\(entity.uniqueIdentifier)'.")
            completion(true)
            return
        }

        let callback: ResponseCallback = NetworkResponseCallback(requestId: entity.uniqueIdentifier, responseHandler: networkResponseHandler)
        let hitCallback = EdgeHitResponseCallback(completion: completion, callback: callback)
        networkService.doRequest(url: edgeHit.url,
                                 requestBody: edgeHit.request,
                                 requestHeaders: edgeHit.headers,
                                 responseCallback: hitCallback,
                                 retryTimes: Constants.Defaults.NETWORK_REQUEST_MAX_RETRIES)
    }

}

/// A wrapper struct to handle the network service callback and pass it to the customer facing callback
private struct EdgeHitResponseCallback: ResponseCallback {
    private let LOG_TAG = "EdgeHitResponseCallback"
    let completion: (Bool) -> Void
    let callback: ResponseCallback

    func onResponse(jsonResponse: String) {
        callback.onResponse(jsonResponse: jsonResponse)
        completion(true)
    }

    func onError(jsonError: String) {
        guard let data = jsonError.data(using: .utf8) else { return }
        guard let edgeErrorResponse = try? JSONDecoder().decode(EdgeResponse.self, from: data) else {
            Log.warning(label: LOG_TAG, "onError - The conversion to JSON failed for server error response: \(jsonError).")
            return
        }

        callback.onError(jsonError: jsonError)
        let isRecoverable = edgeErrorResponse.errors?.contains(where: {$0.isRecoverable}) ?? false
        completion(!isRecoverable) // error, retry this hit if it is recoverable
    }

    func onComplete() {
        callback.onComplete()
    }

}

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
    private var entityRetryIntervalMapping = ThreadSafeDictionary<String, TimeInterval>()

    init(networkService: EdgeNetworkService,
         networkResponseHandler: NetworkResponseHandler) {
        self.networkService = networkService
        self.networkResponseHandler = networkResponseHandler
    }

    // MARK: HitProcessing

    func retryInterval(for entity: DataEntity) -> TimeInterval {
        return entityRetryIntervalMapping[entity.uniqueIdentifier] ?? EdgeConstants.Defaults.RETRY_INTERVAL
    }

    func processHit(entity: DataEntity, completion: @escaping (Bool) -> Void) {
        guard let data = entity.data else {
            // can't convert data to hit, unrecoverable error, move to next hit
            Log.debug(label: LOG_TAG, "processHit - data is empty for entity '\(entity.uniqueIdentifier), dropping hit.")
            completion(true)
            return
        }

        if let edgeHit = try? JSONDecoder().decode(ExperienceEventsEdgeHit.self, from: data) {
            // NOTE: the order of these events needs to be maintained as they were sent in the network request
            // otherwise the response callback cannot be matched
            networkResponseHandler.addWaitingEvents(requestId: edgeHit.requestId,
                                                    batchedEvents: edgeHit.listOfEvents ?? [])
            sendHit(entityId: entity.uniqueIdentifier, edgeHit: edgeHit, headers: edgeHit.headers, completion: completion)
        } else if let consentEdgeHit = try? JSONDecoder().decode(ConsentEdgeHit.self, from: data) {
            sendHit(entityId: entity.uniqueIdentifier, edgeHit: consentEdgeHit, headers: consentEdgeHit.headers, completion: completion)
        } else {
            // unknown hit type, move to next
            completion(true)
        }
    }

    /// Sends the `edgeHit` to the network service
    /// - Parameters:
    ///   - entityId: unique id of the `DataEntity`
    ///   - edgeHit: the hit to be sent
    ///   - headers: headers for the request
    ///   - completion: completion handler for the hit processor
    private func sendHit(entityId: String, edgeHit: EdgeHit, headers: [String: String], completion: @escaping (Bool) -> Void) {
        guard let url = networkService.buildUrl(requestType: edgeHit.getType(),
                                                configId: edgeHit.configId,
                                                requestId: edgeHit.requestId) else {
            Log.debug(label: LOG_TAG,
                      "sendHit - Failed to build the URL, dropping current request with request id '\(edgeHit.requestId)'.")
            completion(true)
            return
        }

        let callback = NetworkResponseCallback(requestId: edgeHit.requestId, responseHandler: networkResponseHandler)
        networkService.doRequest(url: url,
                                 requestBody: edgeHit.getPayload(),
                                 requestHeaders: headers,
                                 streaming: edgeHit.getStreamingSettings(),
                                 responseCallback: callback) { [weak self] success, retryInterval in
            // remove any retry interval if success, otherwise add to retry mapping
            self?.entityRetryIntervalMapping[entityId] = success ? nil : retryInterval
            completion(success)
        }
    }

}

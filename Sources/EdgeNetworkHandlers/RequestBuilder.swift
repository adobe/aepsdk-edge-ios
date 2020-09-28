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

class RequestBuilder {
    private let LOG_TAG = "RequestBuilder"

    /// Control character used before each response fragment. Response streaming is enabled when both `recordSeparator` and `lineFeed` are non nil.
    private var recordSeparator: String?

    /// Control character used at the end of each response fragment. Response streaming is enabled when both `recordSeparator` and `lineFeed` are non nil.
    private var lineFeed: String?

    /// The Experiece Cloud ID to be sent with this request
    var experienceCloudId: String?

    /// Data store manager for retrieving store response payloads for `StateMetadata`
    private let storeResponsePayloadManager: StoreResponsePayloadManager

    init() {
        storeResponsePayloadManager = StoreResponsePayloadManager(Constants.DataStoreKeys.STORE_NAME)
    }

    init(dataStoreName: String) {
        storeResponsePayloadManager = StoreResponsePayloadManager(dataStoreName)
    }

    /// Enables streaming of the Experience Edge Response.
    /// - Parameters:
    ///   - recordSeparator: the record separator used to delimit the start of a response chunk
    ///   - lineFeed: the line feed used to delimit the end of a response chunk
    func enableResponseStreaming(recordSeparator: String, lineFeed: String) {
        self.recordSeparator = recordSeparator
        self.lineFeed = lineFeed
    }

    /// Builds the request payload with all the provided parameters and events.
    /// - Parameter events: List of `Event` objects. Each event is expected to contain a serialized `ExperiencePlatformEvent`
    /// encoded in the `Event.data` property.
    /// - Returns: A `EdgeRequest` object or nil if the events list is empty
    func getRequestPayload(_ events: [Event]) -> EdgeRequest? {
        guard !events.isEmpty else { return nil }

        let streamingMetadata = Streaming(recordSeparator: recordSeparator, lineFeed: lineFeed)
        let konductorConfig = KonductorConfig(streaming: streamingMetadata)

        let storedPayloads = storeResponsePayloadManager.getActivePayloadList()
        let requestMetadata = RequestMetadata(konductorConfig: konductorConfig,
                                              state: storedPayloads.isEmpty ? nil : StateMetadata(payload: storedPayloads))

        let platformEvents = extractPlatformEvents(events)
        var contextData: RequestContextData?

        // set ECID if available
        if let ecid = experienceCloudId {
            var identityMap = IdentityMap()
            identityMap.addItem(namespace: Constants.JsonKeys.ECID, id: ecid)
            contextData = RequestContextData(identityMap: identityMap)
        }

        return EdgeRequest(meta: requestMetadata, xdm: contextData, events: platformEvents)
    }

    /// Extract the `ExperiencePlatformEvent` from each `Event` and return as a list of maps.
    /// The timestamp for each `Event` is set as the timestamp for its contained `ExperiencePlatformEvent`.
    /// The unique identifier for each `Event` is set as the event ID for its contained `ExperiencePlatformEvent`.
    ///
    /// - Parameter events: A list of `Event`s which contain an `ExperiencePlatformEvent` as event data.
    /// - Returns: A list of `ExperiencePlatformEvent`s as maps
    private func extractPlatformEvents(_ events: [Event]) -> [ [String: AnyCodable] ] {
        var platformEvents: [[String: AnyCodable]] = []

        for event in events {
            guard var eventData = event.data else {
                continue
            }

            if eventData[Constants.JsonKeys.XDM] == nil {
                eventData[Constants.JsonKeys.XDM] = [:]
            }

            if var xdm = eventData[Constants.JsonKeys.XDM] as? [String: Any] {
                xdm[Constants.JsonKeys.TIMESTAMP] = ISO8601DateFormatter().string(from: event.timestamp)
                xdm[Constants.JsonKeys.EVENT_ID] = event.id.uuidString
                eventData[Constants.JsonKeys.XDM] = xdm
            }

            // enable collect override if a valid dataset is provided
            if let datasetId = eventData[Constants.EventDataKeys.DATASET_ID] as? String {
                let trimmedDatasetId = datasetId.trimmingCharacters(in: CharacterSet.whitespaces)
                if !trimmedDatasetId.isEmpty {
                    eventData[Constants.JsonKeys.META] =
                        [Constants.JsonKeys.CollectMetadata.COLLECT:
                            [Constants.JsonKeys.CollectMetadata.DATASET_ID: trimmedDatasetId]]
                }
                eventData.removeValue(forKey: Constants.EventDataKeys.DATASET_ID)
            }

            guard let wrappedEventData = AnyCodable.from(dictionary: eventData) else {
                Log.debug(label: LOG_TAG, "Failed to add event data to ExperiencePlatformEvent - unable to convert to [String : AnyCodable]")
                continue
            }

            platformEvents.append(wrappedEventData)
        }

        return platformEvents
    }
}

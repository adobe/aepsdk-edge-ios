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
    private let TAG = "RequestBuilder"

    /// Control charactor used before each response fragment. Response streaming is enabled when both `recoredSeparator` and `lineFeed` are non nil.
    private var recordSeparator: String?

    /// Control character used at the end of each response fragment. Response streaming is enabled when both `recoredSeparator` and `lineFeed` are non nil.
    private var lineFeed: String?

    /// The Experiece Cloud ID to be sent with this request
    var experienceCloudId: String?

    /// Data store manager for retrieving store response payloads for `StateMetadata`
    private let storeResponsePayloadManager: StoreResponsePayloadManager

    init() {
        storeResponsePayloadManager = StoreResponsePayloadManager(ExperiencePlatformConstants.DataStoreKeys.storeName)
    }

    init(dataStoreName: String) {
        storeResponsePayloadManager = StoreResponsePayloadManager(dataStoreName)
    }

    /// Enables streaming of the Platform Edge Response.
    /// - Parameters:
    ///   - recordSeparator: the record separator used to delimit the start of a response chunk
    ///   - lineFeed: the line feed used to delimit the end of a response chunk
    func enableResponseStreaming(recordSeparator: String, lineFeed: String) {
        self.recordSeparator = recordSeparator
        self.lineFeed = lineFeed
    }

    /// Builds the request payload with all the provided parameters and events.
    /// - Parameter events: List of `ACPExtensionEvent` objects. Each event is expected to contain a serialized Experience Platform Event
    /// encoded in the `ACPExtensionEvent.eventData` property.
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
            identityMap.addItem(namespace: ExperiencePlatformConstants.JsonKeys.ECID, id: ecid)
            contextData = RequestContextData(identityMap: identityMap)
        }

        return EdgeRequest(meta: requestMetadata, xdm: contextData, events: platformEvents)
    }

    /// Extract the Experience Platform Event from each `ACPExtensionEvent` and return as a list of maps. The timestamp for each
    /// `ACPExtensionEvent` is set as the timestamp for its contained Experience Platform Event. The unique identifier for each
    /// `ACPExtensionEvent` is set as the event ID for its contained Experience Platform Event.
    ///
    /// - Parameter events: A list of `ACPExtensionEvent` which contain an Experience Platform Event as event data.
    /// - Returns: A list of Experience Platform Events as maps
    private func extractPlatformEvents(_ events: [Event]) -> [ [String: AnyCodable] ] {
        var platformEvents: [[String: AnyCodable]] = []

        for event in events {
            guard var eventData = event.data else {
                continue
            }

            if eventData[ExperiencePlatformConstants.JsonKeys.xdm] == nil {
                eventData[ExperiencePlatformConstants.JsonKeys.xdm] = [:]
            }

            if var xdm = eventData[ExperiencePlatformConstants.JsonKeys.xdm] as? [String: Any] {
                xdm[ExperiencePlatformConstants.JsonKeys.timestamp] = ISO8601DateFormatter().string(from: event.timestamp)
                xdm[ExperiencePlatformConstants.JsonKeys.eventId] = event.id.uuidString
                eventData[ExperiencePlatformConstants.JsonKeys.xdm] = xdm
            }

            // enable collect override if a valid dataset is provided
            if let datasetId = eventData[ExperiencePlatformConstants.EventDataKeys.datasetId] as? String {
                let trimmedDatasetId = datasetId.trimmingCharacters(in: CharacterSet.whitespaces)
                if !trimmedDatasetId.isEmpty {
                    eventData[ExperiencePlatformConstants.JsonKeys.meta] =
                        [ExperiencePlatformConstants.JsonKeys.CollectMetadata.collect: [ExperiencePlatformConstants.JsonKeys.CollectMetadata.datasetId: trimmedDatasetId]]
                }
                eventData.removeValue(forKey: ExperiencePlatformConstants.EventDataKeys.datasetId)
            }

            guard let wrappedEventData = AnyCodable.from(dictionary: eventData) else {
                Log.warning(label: TAG, "Failed to add EventData to platformEvents - unable to convert to [String : AnyCodable]")
                continue
            }
            
            platformEvents.append(wrappedEventData)
        }

        return platformEvents
    }
}

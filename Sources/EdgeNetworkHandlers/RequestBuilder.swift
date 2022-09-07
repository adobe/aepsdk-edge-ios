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
    private let SELF_TAG = "RequestBuilder"

    /// Control character used before each response fragment. Response streaming is enabled when both `recordSeparator` and `lineFeed` are non nil.
    private var recordSeparator: String?

    /// Control character used at the end of each response fragment. Response streaming is enabled when both `recordSeparator` and `lineFeed` are non nil.
    private var lineFeed: String?

    /// XDM payloads to be attached to the request
    var xdmPayloads: [String: AnyCodable] = [:]

    /// Data store manager for retrieving store response payloads for `StateMetadata`
    private let storeResponsePayloadManager: StoreResponsePayloadManager

    init() {
        storeResponsePayloadManager = StoreResponsePayloadManager(EdgeConstants.DataStoreKeys.STORE_NAME)
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
    /// - Parameter events: List of `Event` objects. Each event is expected to contain a serialized `ExperienceEvent`
    /// encoded in the `Event.data` property.
    /// - Returns: A `EdgeRequest` object or nil if the events list is empty
    func getPayloadWithExperienceEvents(_ events: [Event]) -> EdgeRequest? {
        guard !events.isEmpty else { return nil }

        let streamingMetadata = Streaming(recordSeparator: recordSeparator, lineFeed: lineFeed)
        let konductorConfig = KonductorConfig(streaming: streamingMetadata)

        let storedPayloads = storeResponsePayloadManager.getActivePayloadList()
        let requestMetadata = RequestMetadata(konductorConfig: konductorConfig,
                                              state: storedPayloads.isEmpty ? nil : StateMetadata(payload: storedPayloads))

        let experienceEvents = extractExperienceEvents(events)

        return EdgeRequest(meta: requestMetadata, xdm: xdmPayloads, events: experienceEvents)
    }

    /// Builds the request payload to update the consent.
    /// - Parameter event: The Consent Update event containing XDM formatted data
    /// - Returns: A `EdgeConsentUpdate` object or nil if the events list is empty
    func getConsentPayload(_ event: Event) -> EdgeConsentUpdate? {
        guard event.data != nil,
              let consents = event.data?[EdgeConstants.EventDataKeys.CONSENTS] as? [String: Any] else { return nil }

        // Add query with operation update to specify the consent update should be
        // executed as an incremental update and not enforce collect consent settings to be provided all the time
        var consentQueryOptions = [String: Any]()
        consentQueryOptions[EdgeConstants.JsonKeys.Query.OPERATION] = EdgeConstants.JsonValues.Query.OPERATION_UPDATE
        let query = QueryOptions(consent: AnyCodable.from(dictionary: consentQueryOptions))

        // set IdentityMap if available
        var identityMap = [String: AnyCodable]()
        if let identityMapDict = xdmPayloads[EdgeConstants.SharedState.Identity.IDENTITY_MAP] {
            identityMap = AnyCodable.from(dictionary: identityMapDict.dictionaryValue) ?? [:]
        }

        // set streaming metadata
        let streamingMetadata = Streaming(recordSeparator: recordSeparator, lineFeed: lineFeed)
        let konductorConfig = KonductorConfig(streaming: streamingMetadata)
        let requestMetadata = RequestMetadata(konductorConfig: konductorConfig, state: nil)

        return EdgeConsentUpdate(meta: requestMetadata,
                                 query: query,
                                 identityMap: identityMap,
                                 consent: [EdgeConsentPayload(standard: EdgeConstants.JsonValues.CONSENT_STANDARD,
                                                              version: EdgeConstants.JsonValues.CONSENT_VERSION,
                                                              value: AnyCodable.from(dictionary: consents))])
    }

    /// Extract the `ExperienceEvent` from each `Event` and return as a list of maps.
    /// The timestamp for each `Event` is set as the timestamp for its contained `ExperienceEvent`.
    /// The unique identifier for each `Event` is set as the event ID for its contained `ExperienceEvent`.
    ///
    /// - Parameter events: A list of `Event`s which contain an `ExperienceEvent` as event data.
    /// - Returns: A list of `ExperienceEvent`s as maps
    private func extractExperienceEvents(_ events: [Event]) -> [ [String: AnyCodable] ] {
        var experienceEvents: [[String: AnyCodable]] = []

        for event in events {
            guard var eventData = event.data else {
                continue
            }

            if eventData[EdgeConstants.JsonKeys.XDM] == nil {
                eventData[EdgeConstants.JsonKeys.XDM] = [:]
            }

            if var xdm = eventData[EdgeConstants.JsonKeys.XDM] as? [String: Any] {

                if xdm[EdgeConstants.JsonKeys.TIMESTAMP] == nil ||
                    (xdm[EdgeConstants.JsonKeys.TIMESTAMP] as? String)?.isEmpty ?? true {
                    // if no timestamp is provided in the xdm event payload, set the event timestamp
                    xdm[EdgeConstants.JsonKeys.TIMESTAMP] = event.timestamp.getISO8601UTCDateWithMilliseconds()
                }

                xdm[EdgeConstants.JsonKeys.EVENT_ID] = event.id.uuidString
                eventData[EdgeConstants.JsonKeys.XDM] = xdm
            }

            // enable collect override if a valid dataset is provided
            if let datasetId = eventData[EdgeConstants.EventDataKeys.DATASET_ID] as? String {
                let trimmedDatasetId = datasetId.trimmingCharacters(in: CharacterSet.whitespaces)
                if !trimmedDatasetId.isEmpty {
                    eventData[EdgeConstants.JsonKeys.META] =
                        [EdgeConstants.JsonKeys.CollectMetadata.COLLECT:
                            [EdgeConstants.JsonKeys.CollectMetadata.DATASET_ID: trimmedDatasetId]]
                }
                eventData.removeValue(forKey: EdgeConstants.EventDataKeys.DATASET_ID)
            }

            if eventData[EdgeConstants.EventDataKeys.Request.KEY] is [String: Any] {
                // Remove this request object as it is internal to the SDK
                // request object contains custom values to overwrite different request properties like path
                eventData.removeValue(forKey: EdgeConstants.EventDataKeys.Request.KEY)
            }

            guard let wrappedEventData = AnyCodable.from(dictionary: eventData) else {
                Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Failed to add ExperienceEvent data, unable to convert to [String:AnyCodable]")
                continue
            }

            experienceEvents.append(wrappedEventData)
        }

        return experienceEvents
    }
}

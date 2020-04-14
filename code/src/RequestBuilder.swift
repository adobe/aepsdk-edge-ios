//
// ADOBE CONFIDENTIAL
//
// Copyright 2020 Adobe
// All Rights Reserved.
//
// NOTICE: All information contained herein is, and remains
// the property of Adobe and its suppliers, if any. The intellectual
// and technical concepts contained herein are proprietary to Adobe
// and its suppliers and are protected by all applicable intellectual
// property laws, including trade secret and copyright laws.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from Adobe.
//


import Foundation
import ACPCore

class RequestBuilder {
    private let TAG = "RequestBuilder"
    
    /// Control charactor used before each response fragment. Response streaming is enabled when both `recoredSeparator` and `lineFeed` are non nil.
    var recordSeparator: String?
    
    /// Control character used at the end of each response fragment. Response streaming is enabled when both `recoredSeparator` and `lineFeed` are non nil.
    var lineFeed: String?
    
    /// The Experience Cloud Organization ID to be sent with this request
    var organizationId: String?
    
    /// The Experiece Cloud ID to be sent with this request
    var experienceCloudId: String?
    
    /// Data store manager for retrieving store response payloads for `StateMetadata`
    private let storeResponsePayloadManager: StoreResponsePayloadManager
    
    init() {
        let dataStore = NamedUserDefaultsStore(name: ExperiencePlatformConstants.DataStoreKeys.storeName)
        storeResponsePayloadManager = StoreResponsePayloadManager(dataStore)
    }
    
    /// Builds the request payload with all the provided parameters and events.
    /// - Parameter events: List of `ACPExtensionEvent` objects. Each event is expected to contain a serialized Experience Platform Event
    /// encoded in the `ACPExtensionEvent.eventData` property.
    /// - Returns: A `Data` object of the JSON encoded request.
    func getPayload(_ events: [ACPExtensionEvent]) -> Data? {
        if (events.isEmpty) {
            return nil
        }
        
        let streamingMetadata = Streaming(recordSeparator: recordSeparator, lineFeed: lineFeed)
        let konductorConfig = KonductorConfig(imsOrgId: organizationId, streaming: streamingMetadata)
        let stateMetadata = StateMetadata(payload: storeResponsePayloadManager.getActiveStores())
        let requestMetadata = RequestMetadata(konductorConfig: konductorConfig, state: stateMetadata)
        
        var request = EdgeRequest(meta: requestMetadata)
        request.events = extractPlatformEvents(events)
        
        // set ECID if available
        if let ecid = experienceCloudId {
            var identityMap = IdentityMap()
            identityMap.addItem(namespace: "ECID", id: ecid)
            request.xdm = RequestContext(identityMap: identityMap)
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        
        do {
            // TODO return EdgeRequest here instead of encoded JSON Data?
            return try encoder.encode(request)
        } catch {
            ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Failed to encode request to JSON with error '\(error.localizedDescription)'")
        }
        
        return nil
    }
    
    /// Extract the Experience Platform Event from each `ACPExtensionEvent` and return as a list of maps. The timestamp for each
    /// `ACPExtensionEvent` is set as the timestamp for its contained Experience Platform Event. The unique identifier for each
    /// `ACPExtensionEvent` is set as the event ID for its contained Experience Platform Event.
    ///
    /// - Parameter events: A list of `ACPExtensionEvent` which contain an Experience Platform Event as event data.
    /// - Returns: A list of Experience Platform Events as maps
    private func extractPlatformEvents(_ events: [ACPExtensionEvent]) -> [ [AnyHashable : AnyCodable] ] {
        var platformEvents: [[AnyHashable:AnyCodable]] = []
        
        for event in events {
            guard var eventData = event.eventData else {
                continue
            }
            
            if eventData["xdm"] == nil {
                eventData["xdm"] = [:]
            }
            
            if var xdm = eventData["xdm"] as? [String : Any] {
                let date = Date(timeIntervalSince1970: TimeInterval(event.eventTimestamp/1000))
                xdm["timestamp"] = ISO8601DateFormatter().string(from: date)
                xdm["eventId"] = event.eventUniqueIdentifier
                eventData["xdm"] = xdm
            }
            
            platformEvents.append(AnyCodable.from(dictionary: eventData))
            
        }
        
        return platformEvents
    }
    
}

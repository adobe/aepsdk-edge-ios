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

@objc(AEPMobileEdge)
public class Edge: NSObject, Extension {
    private let LOG_TAG = "Edge" // Tag for logging
    private var networkService: EdgeNetworkService = EdgeNetworkService()
    private var networkResponseHandler: NetworkResponseHandler?
    private var hitQueue: HitQueuing?
    private var currentPrivacyStatus: PrivacyStatus?

    // MARK: - Extension
    public let name = EdgeConstants.EXTENSION_NAME
    public let friendlyName = EdgeConstants.FRIENDLY_NAME
    public static let extensionVersion = EdgeConstants.EXTENSION_VERSION
    public let metadata: [String: String]? = nil
    public let runtime: ExtensionRuntime

    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()

        // set default on init for register/unregister use-case
        currentPrivacyStatus = EdgeConstants.DEFAULT_PRIVACY_STATUS
        networkResponseHandler = NetworkResponseHandler(getPrivacyStatus: getPrivacyStatus)
        setupHitQueue()
    }

    public func onRegistered() {
        registerListener(type: EventType.edge,
                         source: EventSource.requestContent,
                         listener: handleExperienceEventRequest)
        registerListener(type: EventType.configuration,
                         source: EventSource.responseContent,
                         listener: handleConfigurationResponse)
        registerListener(type: EventType.edge,
                         source: EdgeConstants.EventSource.CONSENT_UPDATE,
                         listener: handleConsentUpdate)
    }

    public func onUnregistered() {
        hitQueue?.close()
        print("Extension unregistered from MobileCore: \(EdgeConstants.FRIENDLY_NAME)")
    }

    public func readyForEvent(_ event: Event) -> Bool {
        if event.type == EventType.edge, (event.source == EventSource.requestContent || event.source == EdgeConstants.EventSource.CONSENT_UPDATE) {
            let configurationSharedState = getSharedState(extensionName: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                                          event: event)
            let identitySharedState = getSharedState(extensionName: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                                     event: event)

            return configurationSharedState?.status == .set && identitySharedState?.status == .set
        }

        return true
    }

    /// Handler for Experience Edge Request Content events.
    /// Valid Configuration and Identity shared states are required for processing the event (see `readyForEvent`). If a valid Configuration shared state is
    /// available, but no `edge.configId ` is found or `shouldIgnore` returns true, the event is dropped.
    ///
    /// - Parameter event: an event containing ExperienceEvent data for processing
    func handleExperienceEventRequest(_ event: Event) {
        guard !shouldIgnore(event: event) else { return }

        if event.data == nil {
            Log.trace(label: LOG_TAG, "Event with id \(event.id.uuidString) contained no data, ignoring.")
            return
        }

        Log.trace(label: LOG_TAG, "handleExperienceEventRequest - Queuing event with id \(event.id.uuidString).")

        guard let eventData = try? JSONEncoder().encode(event) else {
            Log.debug(label: LOG_TAG, "handleExperienceEventRequest - Failed to encode event with id: '\(event.id.uuidString)'.")
            return
        }

        let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: eventData)
        hitQueue?.queue(entity: entity)
    }

    /// Handles the configuration response event and the privacy status change
    /// - Parameter event: the configuration response event
    func handleConfigurationResponse(_ event: Event) {
        if let privacyStatusStr = event.data?[EdgeConstants.EventDataKeys.GLOBAL_PRIVACY] as? String {
            let privacyStatus = PrivacyStatus(rawValue: privacyStatusStr) ?? EdgeConstants.DEFAULT_PRIVACY_STATUS
            currentPrivacyStatus = privacyStatus
            hitQueue?.handlePrivacyChange(status: privacyStatus)
            if privacyStatus == .optedOut {
                let storeResponsePayloadManager = StoreResponsePayloadManager(EdgeConstants.DataStoreKeys.STORE_NAME)
                storeResponsePayloadManager.deleteAllStorePayloads()
                Log.debug(label: LOG_TAG, "Device has opted-out of tracking. Clearing the Edge queue.")
            }
        }
    }

    /// Handles the Consent Update event
    /// - Parameter event: current event to process
    func handleConsentUpdate(_ event: Event) {
        guard !shouldIgnore(event: event) else { return }

        guard let eventData = try? JSONEncoder().encode(event) else {
            Log.debug(label: LOG_TAG, "handleConsentUpdate - Failed to encode consent event with id: '\(event.id.uuidString)'.")
            return
        }

        let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: eventData)
        hitQueue?.queue(entity: entity)
    }

    /// Current privacy status set based on configuration update events
    /// - Returns: the current `PrivacyStatus` known by the Edge extension
    func getPrivacyStatus() -> PrivacyStatus {
        return currentPrivacyStatus ?? EdgeConstants.DEFAULT_PRIVACY_STATUS
    }

    /// Determines if the event should be ignored by the Edge extension. This method should be called after
    /// `readyForEvent` passed and a Configuration shared state is set.
    ///
    /// - Parameter event: the event to validate
    /// - Returns: true when Configuration shared state is nil or the new privacy status is opted out or collect consent is no
    private func shouldIgnore(event: Event) -> Bool {
        // Always ignore event when Privacy Status opted out
        if isPrivacyOptout(event) {
            return true
        }

        if event.source == EdgeConstants.EventSource.CONSENT_UPDATE {
            return false
        }

        let consentForEvent = getConsentForEvent(event) ?? EdgeConstants.Defaults.CONSENT
        return consentForEvent == ConsentStatus.no
    }

    /// Sets up the `PersistentHitQueue` to handle `EdgeHit`s
    private func setupHitQueue() {
        guard let dataQueue = ServiceProvider.shared.dataQueueService.getDataQueue(label: name) else {
            Log.error(label: "\(name):\(#function)", "Failed to create Data Queue, Edge could not be initialized")
            return
        }

        guard let networkResponseHandler = networkResponseHandler else {
            Log.warning(label: LOG_TAG, "Failed to create Data Queue, the NetworkResponseHandler is not initialized")
            return
        }

        let hitProcessor = EdgeHitProcessor(networkService: networkService,
                                            networkResponseHandler: networkResponseHandler,
                                            getSharedState: getSharedState(extensionName:event:),
                                            readyForEvent: readyForEvent(_:))
        hitQueue = PersistentHitQueue(dataQueue: dataQueue, processor: hitProcessor)
        hitQueue?.handlePrivacyChange(status: EdgeConstants.DEFAULT_PRIVACY_STATUS)
    }

    /// Retrieves the `ConsentStatus` from the Consent XDM Shared state for current `event`.
    /// - Returns: `ConsentStatus` value or nil if not found
    private func getConsentForEvent(_ event: Event) -> ConsentStatus? {
        guard let consentXDMSharedState = getXDMSharedState(extensionName: EdgeConstants.SharedState.Consent.XDM_SHARED_OWNER_NAME,
                                                            event: event)?.value else {
            Log.debug(label: LOG_TAG, "Consent XDM Shared state is unavailable for event '\(event.id)'.")
            return nil
        }

        guard let consents = consentXDMSharedState[EdgeConstants.SharedState.Consent.CONSENTS] as? [String: Any],
              let collectConsent = consents[EdgeConstants.SharedState.Consent.COLLECT] as? String else { return nil }
        return ConsentStatus(rawValue: collectConsent)
    }

    /// Retrieves the `PrivacyStatus` from the Configuration Shared state for current `event`. This method should be called after
    /// `readyForEvent` passed and a Configuration shared state is set.
    /// - Returns: `true` when privacy is optout  or the Configuration shared state is nil
    private func isPrivacyOptout(_ event: Event) -> Bool {
        guard let configSharedState = getSharedState(extensionName: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                                     event: event)?.value else {
            Log.debug(label: LOG_TAG, "Configuration is unavailable - unable to process event '\(event.id)'.")
            return true
        }

        let privacyStatusStr = configSharedState[EdgeConstants.EventDataKeys.GLOBAL_PRIVACY] as? String ?? ""
        let privacyStatus = PrivacyStatus(rawValue: privacyStatusStr) ?? EdgeConstants.DEFAULT_PRIVACY_STATUS

        return privacyStatus == .optedOut
    }
}

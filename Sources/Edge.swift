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
    private let SELF_TAG = "Edge"
    private var networkService: EdgeNetworkService = EdgeNetworkService()
    private var networkResponseHandler: NetworkResponseHandler?
    internal var state: EdgeState?

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
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: setLocationHint)
        if let hitQueue = setupHitQueue() {
            state = EdgeState(hitQueue: hitQueue, edgeProperties: EdgeProperties())
        }
    }

    public func onRegistered() {
        registerListener(type: EventType.edge,
                         source: EventSource.requestContent,
                         listener: handleExperienceEventRequest)
        registerListener(type: EventType.edge,
                         source: EventSource.requestIdentity,
                         listener: handleRequestLocationHint)
        registerListener(type: EventType.edge,
                         source: EventSource.updateIdentity,
                         listener: handleUpdateLocationHint)
        registerListener(type: EventType.edgeConsent,
                         source: EventSource.responseContent,
                         listener: handleConsentPreferencesUpdate)
        registerListener(type: EventType.edge,
                         source: EventSource.updateConsent,
                         listener: handleConsentUpdate)
        registerListener(type: EventType.genericIdentity,
                         source: EventSource.requestReset,
                         listener: handleIdentitiesReset)
    }

    public func onUnregistered() {
        state?.hitQueue.close()
        print("Extension unregistered from MobileCore: \(EdgeConstants.FRIENDLY_NAME)")
    }

    public func readyForEvent(_ event: Event) -> Bool {
        guard canProcessEvents(event: event) else { return false }

        if event.isExperienceEvent || event.isUpdateConsentEvent {
            let configurationSharedState = getSharedState(extensionName: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                                          event: event)
            let identitySharedState = getXDMSharedState(extensionName: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                                        event: event)

            return configurationSharedState?.status == .set && identitySharedState?.status == .set
        } else if event.isResetIdentitiesEvent {
            let configurationSharedState = getSharedState(extensionName: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                                          event: event)
            // use barrier to wait for EdgeIdentity to handle the reset
            let identitySharedState = getXDMSharedState(extensionName: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                                        event: event,
                                                        barrier: true)

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

        guard let data = event.data, !data.isEmpty else {
            Log.trace(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Event with id \(event.id.uuidString) contained no data, ignoring.")
            return
        }

        // get IdentityMap from Identity shared state, this should be resolved based on readyForEvent check
        guard let identityState =
                getXDMSharedState(extensionName: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                  event: event)?.value else {
            Log.warning(label: EdgeConstants.LOG_TAG,
                        "\(SELF_TAG) - Unable to process the event '\(event.id.uuidString)', " +
                            "Identity shared state is nil.")
            return // drop current event
        }

        let edgeEntity = EdgeDataEntity(event: event,
                                        identityMap: AnyCodable.from(dictionary: identityState) ?? [:])

        guard let entityData = try? JSONEncoder().encode(edgeEntity) else {
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Failed to encode EdgeDataEntity for event with id: '\(event.id.uuidString)'.")
            return
        }

        Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Queuing event with id \(event.id.uuidString).")
        let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: entityData)
        state?.hitQueue.queue(entity: entity)
    }

    /// Handles the `EventType.consent` -`EventSource.responseContent` event for the collect consent change
    /// - Parameter event: the consent preferences response event
    func handleConsentPreferencesUpdate(_ event: Event) {
        guard let data = event.data, !data.isEmpty else {
            Log.trace(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Consent preferences event \(event.id.uuidString) contained no data, ignoring.")
            return
        }

        state?.updateCurrentConsent(status: ConsentStatus.getCollectConsentOrDefault(eventData: data))
    }

    /// Handles the generic identities reset event
    /// - Parameter event: an `Event`
    func handleIdentitiesReset(_ event: Event) {
        let edgeEntity = EdgeDataEntity(event: event, identityMap: [:])

        guard let entityData = try? JSONEncoder().encode(edgeEntity) else {
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Failed to encode EdgeDataEntity for event with id: '\(event.id.uuidString)'.")
            return
        }

        let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: entityData)
        networkResponseHandler?.setLastReset(date: event.timestamp)
        state?.hitQueue.queue(entity: entity)
    }

    /// Handles the Consent Update event
    /// - Parameter event: current event to process
    func handleConsentUpdate(_ event: Event) {
        guard let data = event.data, !data.isEmpty else {
            Log.trace(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Consent update request event \(event.id.uuidString) contained no data, ignoring.")
            return
        }

        // get IdentityMap from Identity shared state, this should be resolved based on readyForEvent check
        guard let identityState =
                getXDMSharedState(extensionName: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                  event: event)?.value else {
            Log.warning(label: EdgeConstants.LOG_TAG,
                        "\(SELF_TAG) - Unable to process the event '\(event.id.uuidString)', " +
                            "Identity shared state is nil.")
            return // drop current event
        }

        let edgeEntity = EdgeDataEntity(event: event,
                                        identityMap: AnyCodable.from(dictionary: identityState) ?? [:])

        guard let entityData = try? JSONEncoder().encode(edgeEntity) else {
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Failed to encode EdgeDataEntity for event with id: '\(event.id.uuidString)'.")
            return
        }

        let entity = DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: event.timestamp, data: entityData)
        state?.hitQueue.queue(entity: entity)
    }

    func handleRequestLocationHint(_ event: Event) {
        var data: [String: Any] = [:]
        if let hint = getLocationHint() {
            data[EdgeConstants.EventDataKeys.LOCATION_HINT] = hint
        }

        let responseEvent = event.createResponseEvent(name: "Edge Location Hint Response",
                                                      type: EventType.edge,
                                                      source: EventSource.responseIdentity,
                                                      data: data)
        dispatch(event: responseEvent)
    }

    func handleUpdateLocationHint(_ event: Event) {
        guard let data = event.data, !data.isEmpty else {
            Log.trace(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Location Hint update request event \(event.id.uuidString) contained no data, ignoring.")
            return
        }

        guard let hint = data[EdgeConstants.EventDataKeys.LOCATION_HINT] as? String else {
            Log.trace(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Location Hint update request event \(event.id.uuidString) does not contain 'locationHint' string, ignoring.")
            return
        }

        setLocationHint(hint, ttlSeconds: EdgeConstants.Defaults.LOCATION_HINT_TTL_SEC)
    }

    /// Determines if the event should be ignored by the Edge extension. This method should be called after
    /// `readyForEvent` passed.
    ///
    /// - Parameter event: the event to validate
    /// - Returns: true when collect consent is no, false otherwise
    private func shouldIgnore(event: Event) -> Bool {
        let consentForEvent = getConsentForEvent(event)
        if consentForEvent == ConsentStatus.no {
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Ignoring event with id \(event.id.uuidString) due to collect consent setting (n).")
            return true
        }

        return false
    }

    /// Determines if `Edge` is ready to handle events, if the bootup can be executed successfully
    /// - Parameter event: An `Event`
    /// - Returns: true if events can be processed at the moment, false otherwise
    private func canProcessEvents(event: Event) -> Bool {
        guard let state = state else { return false }
        state.bootupIfNeeded(event: event,
                             getSharedState: getSharedState(extensionName:event:barrier:),
                             createSharedState: createSharedState(data:event:))
        return true
    }

    /// Sets up the `PersistentHitQueue` to handle `EdgeHit`s
    private func setupHitQueue() -> HitQueuing? {
        guard let dataQueue = ServiceProvider.shared.dataQueueService.getDataQueue(label: name) else {
            Log.error(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Failed to create DataQueue, Edge could not be initialized")
            return nil
        }

        guard let networkResponseHandler = networkResponseHandler else {
            Log.warning(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Failed to create DataQueue, the NetworkResponseHandler is not initialized")
            return nil
        }

        let hitProcessor = EdgeHitProcessor(networkService: networkService,
                                            networkResponseHandler: networkResponseHandler,
                                            getSharedState: getSharedState(extensionName:event:),
                                            getXDMSharedState: getXDMSharedState(extensionName:event:barrier:),
                                            readyForEvent: readyForEvent(_:),
                                            getImplementationDetails: getImplementationDetails,
                                            getLocationHint: getLocationHint)
        return PersistentHitQueue(dataQueue: dataQueue, processor: hitProcessor)
    }

    /// Retrieves the `ConsentStatus` from the Consent XDM Shared state for current `event`.
    /// - Returns: `ConsentStatus` value from shared state or, if not found, current consent value
    private func getConsentForEvent(_ event: Event) -> ConsentStatus? {
        guard let consentXDMSharedState = getXDMSharedState(extensionName: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME,
                                                            event: event)?.value else {
            Log.debug(label: EdgeConstants.LOG_TAG, "\(SELF_TAG) - Consent XDM Shared state is unavailable for event '\(event.id)', using current consent.")
            return state?.currentCollectConsent
        }

        return ConsentStatus.getCollectConsentOrDefault(eventData: consentXDMSharedState)
    }

    /// Returns current `ImplementationDetails` for this session.
    /// - Returns: the `ImplementationDetails` for this session or nil if not yet set
    private func getImplementationDetails() -> [String: Any]? {
        return state?.implementationDetails
    }

    /// Set the location hint for the Edge Network. The new location hint and expiry date (calculated from the ttlSeconds) are updated in memory and in
    /// persistent storage. If the new location hint is different from the previous, then a shared state is also created with the new hint.
    /// An empty `hint` value will clear the location hint in memory, persistent storage, and create a new shared state if a previous location hint was set.
    /// - Parameters:
    ///   - hint: the new EdgeNetwork location hint to set
    ///   - ttlSeconds: the time-to-live for the location hint
    private func setLocationHint(_ hint: String, ttlSeconds: TimeInterval) {
        guard let state = state else { return }
        if !hint.isEmpty {
            state.setLocationHint(hint: hint, ttlSeconds: ttlSeconds, createSharedState: createSharedState(data:event:))
        } else {
            state.clearLocationHint(createSharedState: createSharedState(data:event:))
        }
    }

    /// Get the Edge Network location hint.
    /// - Returns: the Edge Network location hint or nil if no location hint is set or the location hint expired.
    private func getLocationHint() -> String? {
        return state?.getLocationHint()
    }

}

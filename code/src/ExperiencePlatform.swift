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

@objc(AEPMobileExperiencePlatform)
public class ExperiencePlatform: NSObject, Extension {
    // Tag for logging
    private let TAG = "ExperiencePlatformInternal"
    private var experiencePlatformNetworkService: ExperiencePlatformNetworkService = ExperiencePlatformNetworkService()
    private var networkResponseHandler: NetworkResponseHandler = NetworkResponseHandler()

    // MARK: - Extension

    public var name = ExperiencePlatformConstants.extensionName
    public var friendlyName = ExperiencePlatformConstants.friendlyName
    public static var extensionVersion = ExperiencePlatformConstants.extensionVersion
    public var metadata: [String: String]?
    public var runtime: ExtensionRuntime

    public required init(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()
    }

    public func onRegistered() {
        registerListener(type: ExperiencePlatformConstants.eventTypeExperiencePlatform,
                         source: EventSource.requestContent,
                         listener: handleExperienceEventRequest)
    }

    public func onUnregistered() {
        print("Extension unregistered from MobileCore: \(ExperiencePlatformConstants.friendlyName)")
    }

    public func readyForEvent(_ event: Event) -> Bool {
        if event.type == ExperiencePlatformConstants.eventTypeExperiencePlatform, event.source == EventSource.requestContent {
            let configurationSharedState = getSharedState(extensionName: ExperiencePlatformConstants.SharedState.Configuration.stateOwner,
                                                          event: event)
            let identitySharedState = getSharedState(extensionName: ExperiencePlatformConstants.SharedState.Identity.stateOwner,
                                                     event: event)
            return configurationSharedState?.status == .set && identitySharedState?.status == .set
        }

        return true
    }

    /// Handler for Experience Platform Request Content events.
    /// Valid Configuration and Identity shared states are required for processing the event (see `readyForEvent`). If a valid Configuration shared state is
    /// available, but no `experiencePlatform.configId ` is found, the event is dropped.
    ///
    /// - Parameter event: an event containing ExperiencePlatformEvent data for processing
    func handleExperienceEventRequest(_ event: Event) {
        if event.data == nil {
            Log.trace(label: TAG, "Event with id \(event.id.uuidString) contained no data, ignoring.")
            return
        }

        Log.trace(label: TAG, "handleExperienceEventRequest - Processing event with id \(event.id.uuidString).")

        // fetch config shared state, this should be resolved based on readyForEvent check
        guard let configSharedState = getSharedState(extensionName: ExperiencePlatformConstants.SharedState.Configuration.stateOwner,
                                                     event: event)?.value else {
                                                        Log.warning(label: TAG,
                                                                    "handleExperienceEventRequest - Unable to process the event '\(event.id.uuidString)', Configuration shared state was nil.")
                                                        return // drop current event
        }

        guard let configId = configSharedState[ExperiencePlatformConstants.SharedState.Configuration.experiencePlatformConfigId] as? String, !configId.isEmpty else {
            Log.warning(label: TAG,
                        "handleExperienceEventRequest - Unable to process the event '\(event.id.uuidString)' because of invalid experiencePlatform.configId in configuration.")
            return // drop current event
        }

        // Build Request object
        let requestBuilder = RequestBuilder()
        requestBuilder.enableResponseStreaming(recordSeparator: ExperiencePlatformConstants.Defaults.requestConfigRecordSeparator,
                                               lineFeed: ExperiencePlatformConstants.Defaults.requestConfigLineFeed)

        // get ECID from Identity shared state, this should be resolved based on readyForEvent check
        guard let identityState = getSharedState(extensionName: ExperiencePlatformConstants.SharedState.Identity.stateOwner,
                                                 event: event)?.value else {
                                                    Log.warning(label: TAG, "handleExperienceEventRequest - Unable to process the event '\(event.id.uuidString)', Identity shared state was nil.")
                                                    return // drop current event
        }

        if let ecid = identityState[ExperiencePlatformConstants.SharedState.Identity.ecid] as? String {
            requestBuilder.experienceCloudId = ecid
        } else {
            // This is not expected to happen. Continue without ECID
            Log.warning(label: TAG, "handleExperienceEventRequest - An unexpected error has occurred, ECID is null.")
        }

        // get Griffon integration id and include it in to the requestHeaders
        var requestHeaders: [String: String] = [:]
        if let griffonSharedState = getSharedState(extensionName: ExperiencePlatformConstants.SharedState.Griffon.stateOwner, event: event)?.value {
            if let griffonIntegrationId = griffonSharedState[ExperiencePlatformConstants.SharedState.Griffon.integrationId] as? String {
                requestHeaders[ExperiencePlatformConstants.NetworkKeys.headerKeyAEPValidationToken] = griffonIntegrationId
            }
        }

        // Build and send the network request to Konductor
        let listOfEvents: [Event] = [event]
        if let requestPayload = requestBuilder.getRequestPayload(listOfEvents) {
            let requestId: String = UUID.init().uuidString

            // NOTE: the order of these events need to be maintained as they were sent in the network request
            // otherwise the response callback cannot be matched
            networkResponseHandler.addWaitingEvents(requestId: requestId,
                                                    batchedEvents: listOfEvents)
            guard let url: URL = experiencePlatformNetworkService.buildUrl(requestType: ExperienceEdgeRequestType.interact,
                                                                           configId: configId,
                                                                           requestId: requestId) else {
                Log.debug(label: TAG, "handleExperienceEventRequest - Failed to build the URL, dropping current event '\(event.id.uuidString)'.")
                return
            }

            let callback: ResponseCallback = NetworkResponseCallback(requestId: requestId, responseHandler: networkResponseHandler)
            experiencePlatformNetworkService.doRequest(url: url,
                                                       requestBody: requestPayload,
                                                       requestHeaders: requestHeaders,
                                                       responseCallback: callback,
                                                       retryTimes: ExperiencePlatformConstants.Defaults.networkRequestMaxRetries)
        }

        Log.trace(label: TAG, "handleExperienceEventRequest - Finished processing and sending events to Edge.")
    }
}

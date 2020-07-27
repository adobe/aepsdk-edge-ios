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

import ACPCore
import XCTest

/// Extension used to 'fake' an Identity extension and allows tests to clear and set the Identity shared state. Use it along with `FunctionalTestBase`
/// Cannot be used along with another Identity Extension which is registered with ACPCore.
class FakeIdentityExtension: ACPExtension {
    private static let logTag = "FakeIdentityExtension"

    private static let eventType = "com.adobe.fakeidentity"
    private static let eventSetState = "com.adobe.request.setstate"
    private static let eventClearState = "com.adobe.request.clearstate"
    private static let eventResponse = "com.adobe.response"

    override init() {
        super.init()

        try? api.registerListener(FakeIdentityListener.self,
                                  eventType: FakeIdentityExtension.eventType,
                                  eventSource: FakeIdentityExtension.eventSetState)

        try? api.registerListener(FakeIdentityListener.self,
                                  eventType: FakeIdentityExtension.eventType,
                                  eventSource: FakeIdentityExtension.eventClearState)
    }

    override func name() -> String? {
        "com.adobe.module.identity"
    }

    override func version() -> String? {
        "1.0.0"
    }

    override func onUnregister() {
        super.onUnregister()

        // if the shared states are not used in the next registration they can be cleared in this method
        try? api.clearSharedEventStates()
    }

    /// Clear the shared state for this `FakeIdentityExtension`.
    /// Calls `ACPExtensionApi.clearSharedEventState()` to perform the opteration.
    /// This is a synchronous call, which waits for a response from the extension before returning.
    public static func clearSharedState() {
        guard let event = try? ACPExtensionEvent(name: "Set Fake Identity State",
                                                 type: FakeIdentityExtension.eventType,
                                                 source: FakeIdentityExtension.eventClearState,
                                                 data: nil) else {
                                                    ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "setSharedState failed to create request event.")
                                                    return
        }

        let latch = CountDownLatch(1)
        try? ACPCore.dispatchEvent(withResponseCallback: event) { _ in
            latch.countDown()
        }

        _ = latch.await(timeout: 5)
    }

    /// Set a new shared state for this `FakeIdentityExtension`. Setting a shared state will trigger a Hub Shared State event
    /// from the EventHub just like any other extension.
    /// Calls `ACPExtensionApi.setSharedEventState` to perform the operation.
    /// This is a synchronous call, which waits for a response from the extension before returning.
    /// - Parameter state: the state to set
    public static func setSharedState(state: [AnyHashable: Any]) {

        guard let event = try? ACPExtensionEvent(name: "Set Fake Identity State",
                                                 type: FakeIdentityExtension.eventType,
                                                 source: FakeIdentityExtension.eventSetState,
                                                 data: state) else {
                                                    ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "setSharedState failed to create request event.")
                                                    return
        }

        let latch = CountDownLatch(1)
        try? ACPCore.dispatchEvent(withResponseCallback: event) { _ in
            latch.countDown()
        }

        _ = latch.await(timeout: 5)
    }

    // MARK: Event Processors

    /// Processes events received from the event listener. If the event is handled, a paired response event is dispatched to notify the caller
    /// the event was processed.
    /// - Parameter event: an event to process
    func processRequest(_ event: ACPExtensionEvent) {
        var doDispatch = false

        if event.eventSource == FakeIdentityExtension.eventClearState {
            try? api.clearSharedEventStates()
            doDispatch = true
        } else if event.eventSource == FakeIdentityExtension.eventSetState {
            guard let eventData = event.eventData, !eventData.isEmpty  else { return }
            try? api.setSharedEventState(eventData, event: event)
            doDispatch = true
        }

        if doDispatch {
            guard let responseEvent = try? ACPExtensionEvent(name: "FakeIdentity Response",
                                                             type: FakeIdentityExtension.eventType,
                                                             source: FakeIdentityExtension.eventResponse,
                                                             data: nil) else {
                                                                ACPCore.log(ACPMobileLogLevel.debug, tag: FakeIdentityExtension.logTag, message: "ProcessSharedStateRequest failed to create response event.")
                                                                return
            }

            // dispatch paired response event with shared state data
            guard let _ = try? ACPCore.dispatchResponseEvent(responseEvent, request: event) else {
                ACPCore.log(ACPMobileLogLevel.debug, tag: FakeIdentityExtension.logTag, message: "ProcessSharedStateRequest failed to dispatch response event.")
                return
            }
        }
    }
}

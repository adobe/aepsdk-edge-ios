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

/// Instrumented extension that registers a wildcard listener for intercepting events in current session. Use it along with `FunctionalTestBase`
class FakeIdentityExtension: ACPExtension {
    private static let logTag = "FakeIdentityExtension"

    private static let eventType = "com.adobe.fakeidentity"
    private static let eventSetState = "com.adobe.request.setstate"
    private static let eventClearState = "com.adobe.request.clearstate"
    private static let eventResponse = "com.adobe.response"

    override init() {
        super.init()

        try? api.registerWildcardListener(FakeIdentityListener.self)
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

    /// Process `getSharedStateFor` requests
    /// - Parameter event: event sent from `getSharedStateFor` which specifies the shared state `stateowner` to retrieve
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

    func unregisterExtension() {
        ACPCore.log(ACPMobileLogLevel.debug, tag: FakeIdentityExtension.logTag, message: "Unregistering the Instrumented extension from the Event Hub")
        self.api.unregisterExtension()
    }
}

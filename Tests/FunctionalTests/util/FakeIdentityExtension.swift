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
import XCTest

/// Extension used to 'fake' an Identity extension and allows tests to clear and set the Identity shared state. Use it along with `TestBase`
/// Cannot be used along with another Identity Extension which is registered with ACPCore.
class FakeIdentityExtension: NSObject, Extension {
    private static let logTag = "FakeIdentityExtension"

    private static let eventType = "com.adobe.fakeidentity"
    private static let eventSetState = "com.adobe.request.setstate"
    private static let eventSetXDMState = "com.adobe.request.setxdmstate"
    private static let eventClearState = "com.adobe.request.clearstate"
    private static let eventResponse = "com.adobe.response"

    var name: String = "com.adobe.edge.identity"

    var friendlyName: String = "Identity"

    static var extensionVersion: String = "1.0.0"

    var metadata: [String: String]?

    var runtime: ExtensionRuntime

    func onRegistered() {
        registerListener(type: FakeIdentityExtension.eventType, source: FakeIdentityExtension.eventSetState, listener: processRequest)
        registerListener(type: FakeIdentityExtension.eventType, source: FakeIdentityExtension.eventClearState, listener: processRequest)
        registerListener(type: FakeIdentityExtension.eventType, source: FakeIdentityExtension.eventSetXDMState, listener: processRequest)
    }

    func onUnregistered() {}

    required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
    }

    public func readyForEvent(_ event: Event) -> Bool {
        return true
    }

    /// Clear the shared state for this `FakeIdentityExtension`.
    /// Calls `ACPExtensionApi.clearSharedEventState()` to perform the opteration.
    /// This is a synchronous call, which waits for a response from the extension before returning.
    public static func clearSharedState() {
        let event = Event(name: "Set Fake Identity State",
                          type: FakeIdentityExtension.eventType,
                          source: FakeIdentityExtension.eventClearState,
                          data: nil)

        let latch = CountDownLatch(1)
        MobileCore.dispatch(event: event, responseCallback: { _ in
            latch.countDown()
        })

        _ = latch.await(timeout: 5)
    }

    /// Set a new shared state for this `FakeIdentityExtension`. Setting a shared state will trigger a Hub Shared State event
    /// from the EventHub just like any other extension.
    /// Calls `ACPExtensionApi.setSharedEventState` to perform the operation.
    /// This is a synchronous call, which waits for a response from the extension before returning.
    /// - Parameter state: the state to set
    public static func setSharedState(state: [String: Any]) {

        let event = Event(name: "Set Fake Identity State",
                          type: FakeIdentityExtension.eventType,
                          source: FakeIdentityExtension.eventSetState,
                          data: state)

        let latch = CountDownLatch(1)
        MobileCore.dispatch(event: event, responseCallback: { _ in
            latch.countDown()
        })

        _ = latch.await(timeout: 5)
    }

    /// Set a new XDM shared state for this `FakeIdentityExtension`. Setting an XDM shared state will trigger a Hub Shared State event
    /// from the EventHub just like any other extension.
    /// Calls `ACPExtensionApi.setSharedEventState` to perform the operation.
    /// This is a synchronous call, which waits for a response from the extension before returning.
    /// - Parameter state: the state to set
    public static func setXDMSharedState(state: [String: Any]) {

        let event = Event(name: "Set Fake Identity XDM State",
                          type: FakeIdentityExtension.eventType,
                          source: FakeIdentityExtension.eventSetXDMState,
                          data: state)

        let latch = CountDownLatch(1)
        MobileCore.dispatch(event: event, responseCallback: { _ in
            latch.countDown()
        })

        _ = latch.await(timeout: 5)
    }

    // MARK: Event Processors

    /// Processes events received from the event listener. If the event is handled, a paired response event is dispatched to notify the caller
    /// the event was processed.
    /// - Parameter event: an event to process
    func processRequest(_ event: Event) {
        var doDispatch = false

        if event.source == FakeIdentityExtension.eventClearState {
            // TODO: not supported anymore https://github.com/adobe/aepsdk-core-ios/issues/289
            // try? api.clearSharedEventStates()
            doDispatch = true
        } else if event.source == FakeIdentityExtension.eventSetState {
            guard let eventData = event.data, !eventData.isEmpty  else { return }
            runtime.createSharedState(data: eventData, event: event)
            doDispatch = true
        } else if event.source == FakeIdentityExtension.eventSetXDMState {
            guard let eventData = event.data, !eventData.isEmpty  else { return }
            runtime.createXDMSharedState(data: eventData, event: event)
            doDispatch = true
        }

        if doDispatch {
            let responseEvent = event.createResponseEvent(name: "FakeIdentity Response",
                                                          type: FakeIdentityExtension.eventType,
                                                          source: FakeIdentityExtension.eventResponse,
                                                          data: nil)

            // dispatch paired response event with shared state data
            MobileCore.dispatch(event: responseEvent)
        }
    }
}

//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@testable import AEPCore
import Foundation

/// Testable implementation for `ExtensionRuntime`
///
/// Enable easy setup for the input and verification of the output of an extension
/// See also AEPCore/Mocks
public class TestableExtensionRuntime: ExtensionRuntime {
    public var listeners: [String: EventListener] = [:]
    public var dispatchedEvents: [Event] = []
    public var createdSharedStates: [[String: Any]?] = []
    public var createdXdmSharedStates: [[String: Any]?] = []
    public var mockedSharedStates: [String: SharedStateResult] = [:]
    public var mockedXdmSharedStates: [String: SharedStateResult] = [:]

    public init() {}

    // MARK: - ExtensionRuntime methods implementation
    public func unregisterExtension() {
        // no-op
    }

    public func registerListener(type: String, source: String, listener: @escaping EventListener) {
        listeners["\(type)-\(source)"] = listener
    }

    public func dispatch(event: Event) {
        dispatchedEvents += [event]
    }

    public func createSharedState(data: [String: Any], event _: Event?) {
        createdSharedStates += [data]
    }

    public func createPendingSharedState(event _: Event?) -> SharedStateResolver {
        return { data in
            self.createdSharedStates += [data]
        }
    }

    public func getSharedState(extensionName: String, event: Event?, barrier: Bool) -> SharedStateResult? {
        // if there is an shared state setup for the specific (extension, event id) pair, return it. Otherwise, return the shared state that is setup for the extension.
        if let id = event?.id {
            return mockedSharedStates["\(extensionName)-\(id)"] ?? mockedSharedStates["\(extensionName)"]
        }
        return mockedSharedStates["\(extensionName)"]
    }

    public func createXDMSharedState(data: [String: Any], event: Event?) {
        createdXdmSharedStates += [data]
    }

    public func createPendingXDMSharedState(event: Event?) -> SharedStateResolver {
        return { data in
            self.createdXdmSharedStates += [data]
        }
    }

    public func getXDMSharedState(extensionName: String, event: Event?, barrier: Bool) -> SharedStateResult? {
        // if there is an shared state setup for the specific (extension, event id) pair, return it. Otherwise, return the shared state that is setup for the extension.
        if let id = event?.id {
            return mockedXdmSharedStates["\(extensionName)-\(id)"] ?? mockedXdmSharedStates["\(extensionName)"]
        }
        return mockedXdmSharedStates["\(extensionName)"]
    }

    public func startEvents() {}

    public func stopEvents() {}

    // MARK: - Helper methods
    /// Simulate the events that are being sent to event hub, if there is a listener registered for that type of event, that listener will receive the event
    /// - Parameters:
    ///   - events: the sequence of the events
    public func simulateComingEvents(_ events: Event...) {
        for event in events {
            listeners["\(event.type)-\(event.source)"]?(event)
            listeners["\(EventType.wildcard)-\(EventSource.wildcard)"]?(event)
        }
    }

    /// Get the listener that is registered for the specific event source and type
    /// - Parameters:
    ///   - type: event type
    ///   - source: event source
    public func getListener(type: String, source: String) -> EventListener? {
        return listeners["\(type)-\(source)"]
    }

    /// Simulate the shared state of an extension for a matching event
    /// - Parameters:
    ///   - pair: the (extension, event) pair
    ///   - data: the shared state tuple (value, status)
    public func simulateSharedState(for pair: (extensionName: String, event: Event), data: (value: [String: Any]?, status: SharedStateStatus)) {
        mockedSharedStates["\(pair.extensionName)-\(pair.event.id)"] = SharedStateResult(status: data.status, value: data.value)
    }

    /// Simulate the shared state of an certain extension ignoring the event id
    /// - Parameters:
    ///   - extensionName: extension name
    ///   - data: the shared state tuple (value, status)
    public func simulateSharedState(for extensionName: String, data: (value: [String: Any]?, status: SharedStateStatus)) {
        mockedSharedStates["\(extensionName)"] = SharedStateResult(status: data.status, value: data.value)
    }

    /// Simulate the XDM shared state of an extension for a matching event
    /// - Parameters:
    ///   - pair: the (extension, event) pair
    ///   - data: the shared state tuple (value, status)
    public func simulateXDMSharedState(for pair: (extensionName: String, event: Event), data: (value: [String: Any]?, status: SharedStateStatus)) {
        mockedXdmSharedStates["\(pair.extensionName)-\(pair.event.id)"] = SharedStateResult(status: data.status, value: data.value)
    }

    /// Simulate the XDM shared state of an certain extension ignoring the event id
    /// - Parameters:
    ///   - extensionName: extension name
    ///   - data: the shared state tuple (value, status)
    public func simulateXDMSharedState(for extensionName: String, data: (value: [String: Any]?, status: SharedStateStatus)) {
        mockedXdmSharedStates["\(extensionName)"] = SharedStateResult(status: data.status, value: data.value)
    }

    /// clear the events and shared states that have been created by the current extension
    public func resetDispatchedEventAndCreatedSharedStates() {
        dispatchedEvents = []
        createdSharedStates = []
        createdXdmSharedStates = []
    }
}

/// Convenience properties for `TestableExtensionRuntime`
extension TestableExtensionRuntime {

    /// First dispatched event
    public var firstEvent: Event? {
        dispatchedEvents[0]
    }

    /// Second dispatched event
    public var secondEvent: Event? {
        dispatchedEvents[1]
    }

    /// Third dispatched event
    public var thirdEvent: Event? {
        dispatchedEvents[2]
    }

    /// First created shared state
    public var firstSharedState: [String: Any]? {
        createdSharedStates[0]
    }

    /// Second created shared state
    public var secondSharedState: [String: Any]? {
        createdSharedStates[1]
    }

    /// Third created shared state
    public var thirdSharedState: [String: Any]? {
        createdSharedStates[2]
    }
}

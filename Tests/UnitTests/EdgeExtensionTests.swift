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
@testable import AEPEdge
@testable import AEPServices
import XCTest

class EdgeExtensionTests: XCTestCase {
    let experienceEvent = Event(name: "Experience event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["data": "example"]])
    var mockRuntime: TestableExtensionRuntime!
    var edge: Edge!
    var mockDataQueue: MockDataQueue!
    var mockHitProcessor: MockHitProcessor!

    #if os(iOS)
    private let EXPECTED_BASE_PATH = "https://ns.adobe.com/experience/mobilesdk/ios"
    #elseif os(tvOS)
    private let EXPECTED_BASE_PATH = "https://ns.adobe.com/experience/mobilesdk/tvos"
    #endif

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        mockRuntime = TestableExtensionRuntime()
        mockDataQueue = MockDataQueue()
        mockHitProcessor = MockHitProcessor()

        edge = Edge(runtime: mockRuntime)
        edge.state = EdgeState(hitQueue: PersistentHitQueue(dataQueue: mockDataQueue, processor: mockHitProcessor),
                               edgeProperties: EdgeProperties())
        edge.onRegistered()
    }

    override func tearDown() {
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    // MARK: Bootup scenarios
    func testBootup_hubSharedState_consentNotRegistered_setsConsentYes() {
        // consent extension not present in hub shared state
        let hubSharedState: [String: Any] = [
            "extensions": [
                "com.adobe.edge": [
                    "version": "1.1.0",
                    "friendlyName": "AEPEdge"
                ]
            ]]
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Hub.SHARED_OWNER_NAME, data: (hubSharedState, .set))

        // dummy event to invoke readyForEvent
        _ = edge.readyForEvent(Event(name: "Dummy event", type: EventType.custom, source: EventSource.none, data: nil))

        // verify
        XCTAssertEqual(ConsentStatus.yes, edge.state?.currentCollectConsent)
    }

    func testBootup_hubSharedState_consentRegistered_keepsPending() {
        let hubSharedState: [String: Any] = [
            "extensions": [
                "com.adobe.edge": [
                    "version": "1.1.0",
                    "friendlyName": "AEPEdge"
                ],
                "com.adobe.edge.consent": [
                    "version": "1.0.0",
                    "friendlyName": "Consent"
                ]
            ]]
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Hub.SHARED_OWNER_NAME, data: (hubSharedState, .set))

        // dummy event to invoke readyForEvent
        _ = edge.readyForEvent(Event(name: "Dummy event", type: EventType.custom, source: EventSource.none, data: nil))

        // verify
        XCTAssertEqual(ConsentStatus.pending, edge.state?.currentCollectConsent)
    }

    func testBootup_executesOnlyOnce() {
        var consentXDMSharedState = ["consents": ["collect": ["val": "y"]]]
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME, data: (consentXDMSharedState, .set))

        // dummy event to invoke readyForEvent
        _ = edge.readyForEvent(Event(name: "Dummy event", type: EventType.custom, source: EventSource.none, data: nil))
        XCTAssertTrue(edge.state?.hasBooted ?? false)

        consentXDMSharedState = ["consents": ["collect": ["val": "p"]]]
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME, data: (consentXDMSharedState, .set))
        _ = edge.readyForEvent(Event(name: "Dummy event", type: EventType.custom, source: EventSource.none, data: nil))

        // verify
        XCTAssertEqual(ConsentStatus.yes, edge.state?.currentCollectConsent)
    }

    func testBootup_hubSharedState_setsImplementationDetails() {
        let hubSharedState: [String: Any] = [
            "wrapper": ["type": "R"],
            "version": "3.0.0"
        ]
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Hub.SHARED_OWNER_NAME, data: (hubSharedState, .set))

        // dummy event to invoke readyForEvent
        _ = edge.readyForEvent(Event(name: "Dummy event", type: EventType.custom, source: EventSource.none, data: nil))

        // verify
        let actualDetails = edge.state?.implementationDetails ?? [:]
        XCTAssertTrue(!actualDetails.isEmpty)

        let expectedDetails: [String: Any] = [
            "version": "3.0.0+\(EdgeConstants.EXTENSION_VERSION)",
            "environment": "app",
            "name": "\(EXPECTED_BASE_PATH)/reactnative"
        ]

        XCTAssertTrue(expectedDetails == actualDetails)
    }

    // MARK: Consent update request
    func testHandleConsentUpdate_nilEmptyData_doesNotQueue() {
        mockRuntime.simulateComingEvents(
            Event(name: "Consent nil data", type: EventType.edge, source: EventSource.updateConsent, data: nil),
            Event(name: "Consent empty data", type: EventType.edge, source: EventSource.updateConsent, data: [:])
        )

        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testHandleConsentUpdate_noIdentitySharedState_doesNotQueue() {
        mockRuntime.simulateComingEvents(Event(name: "Consent update", type: EventType.edge, source: EventSource.updateConsent, data: ["consents": ["collect": ["val": "y"]]]))

        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testHandleConsentUpdate_validData_queues() {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        mockRuntime.simulateComingEvents(Event(name: "Consent update", type: EventType.edge, source: EventSource.updateConsent, data: ["consents": ["collect": ["val": "y"]]]))

        XCTAssertEqual(1, mockDataQueue.count())
    }

    // MARK: Consent preferences update
    func testHandlePreferencesUpdate_nilEmptyData_keepsPendingConsent() {
        mockRuntime.simulateComingEvents(
            Event(name: "Consent nil data", type: EventType.edgeConsent, source: EventSource.responseContent, data: nil),
            Event(name: "Consent empty data", type: EventType.edgeConsent, source: EventSource.responseContent, data: [:])
        )

        XCTAssertEqual(ConsentStatus.pending, edge.state?.currentCollectConsent)
    }

    func testHandlePreferencesUpdate_validData() {
        mockRuntime.simulateComingEvents(Event(name: "Consent update", type: EventType.edgeConsent, source: EventSource.responseContent, data: ["consents": ["collect": ["val": "y"]]]))

        XCTAssertEqual(ConsentStatus.yes, edge.state?.currentCollectConsent)
    }

    // MARK: Experience event
    func testHandleExperienceEventRequest_noIdentitySharedState_doesNotQueue() {
        edge.state?.updateCurrentConsent(status: ConsentStatus.yes)
        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testHandleExperienceEventRequest_validData_consentYes_queues() {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        edge.state?.updateCurrentConsent(status: ConsentStatus.yes)
        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(1, mockDataQueue.count())
    }

    func testHandleExperienceEventRequest_validData_consentPending_queues() {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        edge.state?.updateCurrentConsent(status: ConsentStatus.pending)
        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(1, mockDataQueue.count())
    }

    func testHandleExperienceEventRequest_validData_consentNo_dropsEvent() {
        edge.state?.updateCurrentConsent(status: ConsentStatus.no)
        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testHandleExperienceEventRequest_nilEmptyData_ignoresEvent() {
        mockRuntime.simulateComingEvents(
            Event(name: "Experience event nil data", type: EventType.edge, source: EventSource.requestContent, data: nil),
            Event(name: "Experience event empty data", type: EventType.edge, source: EventSource.requestContent, data: [:])
        )

        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testHandleExperienceEventRequest_consentXDMSharedStateNo_dropsEvent() {
        edge.state?.updateCurrentConsent(status: ConsentStatus.yes)
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME, data: (["consents": ["collect": ["val": "n"]]], .set))
        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testHandleExperienceEventRequest_consentXDMSharedStateInvalid_usesDefaultPending() {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        edge.state?.updateCurrentConsent(status: ConsentStatus.no)
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME, data: (["consents": ["invalid": "data"]], .set))
        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(1, mockDataQueue.count())
    }

    func testHandleExperienceEventRequest_consentXDMSharedStateInvalid_usesCurrentConsent() {
        edge.state?.updateCurrentConsent(status: ConsentStatus.no)
        // no consent shared state for current event
        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(0, mockDataQueue.count())
    }

    // MARK: Identities reset event tests

    func testHandleIdentitiesReset() {
        let event = Event(name: "Reset Event",
                          type: EventType.genericIdentity,
                          source: EventSource.requestReset,
                          data: nil)

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockDataQueue.count())
    }
}

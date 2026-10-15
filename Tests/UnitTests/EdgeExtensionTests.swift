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
import AEPTestUtils
import XCTest

class EdgeExtensionTests: XCTestCase, AnyCodableAsserts {
    let experienceEvent = Event(name: "Experience event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["data": "example"]])
    var mockRuntime: TestableExtensionRuntime!
    var edge: Edge!
    var mockDataQueue: MockDataQueue!
    var mockBypassConsentDataQueue: MockDataQueue!
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
        mockBypassConsentDataQueue = MockDataQueue()
        mockHitProcessor = MockHitProcessor()

        edge = Edge(runtime: mockRuntime)
        edge.state = EdgeState(hitQueue: PersistentHitQueue(dataQueue: mockDataQueue, processor: mockHitProcessor),
                               bypassConsentHitQueue: PersistentHitQueue(dataQueue: mockBypassConsentDataQueue, processor: mockHitProcessor),
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
        let actualDetails = edge.state?.implementationDetails

        let expectedDetailsJSON = #"""
            {
            "version": "3.0.0+\#(EdgeConstants.EXTENSION_VERSION)",
            "environment": "app",
            "name": "\#(EXPECTED_BASE_PATH)/reactnative"
            }
        """#

        assertEqual(expected: expectedDetailsJSON, actual: actualDetails)
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
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "12345-example"], .set))
        mockRuntime.simulateComingEvents(Event(name: "Consent update", type: EventType.edge, source: EventSource.updateConsent, data: ["consents": ["collect": ["val": "y"]]]))

        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testHandleConsentUpdate_noConfigurationSharedState_doesNotQueue() {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        mockRuntime.simulateComingEvents(Event(name: "Consent update", type: EventType.edge, source: EventSource.updateConsent, data: ["consents": ["collect": ["val": "y"]]]))

        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testHandleConsentUpdate_ConfigurationSharedStateWithoutConfigId_doesNotQueue() {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([:], .set))
        mockRuntime.simulateComingEvents(Event(name: "Consent update", type: EventType.edge, source: EventSource.updateConsent, data: ["consents": ["collect": ["val": "y"]]]))

        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testHandleConsentUpdate_validData_queues() {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "12345-example"], .set))
        mockRuntime.simulateComingEvents(Event(name: "Consent update", type: EventType.edge, source: EventSource.updateConsent, data: ["consents": ["collect": ["val": "y"]]]))

        XCTAssertEqual(1, mockDataQueue.count())
    }

    func testHandleConsentUpdate_queuedDataEntityContainsConfiguration() {
        let configuration = [
            "edge.configId": "12345-example",
            "edge.domain": "edge.com",
            "edge.environment": "dev",
            "experience.orgId": "12345-org"
        ]

        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: (configuration, .set))
        mockRuntime.simulateComingEvents(Event(name: "Consent update", type: EventType.edge, source: EventSource.updateConsent, data: ["consents": ["collect": ["val": "y"]]]))

        XCTAssertEqual(1, mockDataQueue.count())
        guard let dataEntity = mockDataQueue.peek() else {
            XCTFail("DataEntity was not in MockDataQueue as expected!")
            return
        }

        guard let data = dataEntity.data, let edgeDataEntity = try? JSONDecoder().decode(EdgeDataEntity.self, from: data) else {
            XCTFail("Unable to decode EdgeEntity from DataEntity!")
            return
        }

        // Verify EdgeDataEntity only contains config ID, domain, and environment
        let expectedConfigJSON = """
            {
              "edge.configId": "12345-example",
              "edge.domain": "edge.com",
              "edge.environment": "dev"
            }
        """

        assertEqual(expected: expectedConfigJSON, actual: edgeDataEntity.configuration)
    }

    func testHandleConsentUpdate_queuedDataEntityContainsIdentityMap() {
        let identityMap: [String: AnyCodable] =
            [
                "ECID": [
                    ["id": "12345-ecid", "authenticatedState": "ambiguous", "primary": false]
                ]
            ]

        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: (identityMap, .set))
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "12345-example"], .set))
        mockRuntime.simulateComingEvents(Event(name: "Consent update", type: EventType.edge, source: EventSource.updateConsent, data: ["consents": ["collect": ["val": "y"]]]))

        XCTAssertEqual(1, mockDataQueue.count())
        guard let dataEntity = mockDataQueue.peek() else {
            XCTFail("DataEntity was not in MockDataQueue as expected!")
            return
        }

        guard let data = dataEntity.data, let edgeDataEntity = try? JSONDecoder().decode(EdgeDataEntity.self, from: data) else {
            XCTFail("Unable to decode EdgeEntity from DataEntity!")
            return
        }

        // Verify EdgeDataEntity contains identity map
        assertEqual(expected: identityMap, actual: edgeDataEntity.identityMap)
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
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "12345-example"], .set))
        edge.state?.updateCurrentConsent(status: ConsentStatus.yes)
        // UpdateCurrentConsent will enabled hit queue, suspend to capture hit in queue
        edge.state?.hitQueue.suspend()

        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testHandleExperienceEventRequest_noConfigurationSharedState_doesNotQueue() {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        edge.state?.updateCurrentConsent(status: ConsentStatus.yes)
        // UpdateCurrentConsent will enabled hit queue, suspend to capture hit in queue
        edge.state?.hitQueue.suspend()

        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testHandleExperienceEventRequest_ConfigurationSharedStateWithoutConfigId_doesNotQueue() {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([:], .set))
        edge.state?.updateCurrentConsent(status: ConsentStatus.yes)
        // UpdateCurrentConsent will enabled hit queue, suspend to capture hit in queue
        edge.state?.hitQueue.suspend()

        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testHandleExperienceEventRequest_validData_consentYes_queues() {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "12345-example"], .set))
        edge.state?.updateCurrentConsent(status: ConsentStatus.yes)
        // UpdateCurrentConsent will enabled hit queue, suspend to capture hit in queue
        edge.state?.hitQueue.suspend()

        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(1, mockDataQueue.count())
    }

    func testHandleExperienceEventRequest_validData_consentPending_queues() {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "12345-example"], .set))
        edge.state?.updateCurrentConsent(status: ConsentStatus.pending)

        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(1, mockDataQueue.count())
    }

    func testHandleExperienceEventRequest_validData_consentNo_dropsEvent() {
        edge.state?.updateCurrentConsent(status: ConsentStatus.no)
        // UpdateCurrentConsent will enabled hit queue, suspend to capture hit in queue
        edge.state?.hitQueue.suspend()

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
        // UpdateCurrentConsent will enabled hit queue, suspend to capture hit in queue
        edge.state?.hitQueue.suspend()

        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME, data: (["consents": ["collect": ["val": "n"]]], .set))
        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testHandleExperienceEventRequest_consentXDMSharedStateInvalid_usesDefaultPending() {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "12345-example"], .set))
        edge.state?.updateCurrentConsent(status: ConsentStatus.no)
        // UpdateCurrentConsent will enabled hit queue, suspend to capture hit in queue
        edge.state?.hitQueue.suspend()

        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME, data: (["consents": ["invalid": "data"]], .set))
        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(1, mockDataQueue.count())
    }

    func testHandleExperienceEventRequest_queuedDataEntityContainsConfiguration() {
        let configuration = [
            "edge.configId": "12345-example",
            "edge.domain": "edge.com",
            "edge.environment": "dev",
            "experience.orgId": "12345-org"
        ]

        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: (configuration, .set))
        edge.state?.updateCurrentConsent(status: ConsentStatus.yes)
        // UpdateCurrentConsent will enabled hit queue, suspend to capture hit in queue
        edge.state?.hitQueue.suspend()

        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(1, mockDataQueue.count())
        guard let dataEntity = mockDataQueue.peek() else {
            XCTFail("DataEntity was not in MockDataQueue as expected!")
            return
        }

        guard let data = dataEntity.data, let edgeDataEntity = try? JSONDecoder().decode(EdgeDataEntity.self, from: data) else {
            XCTFail("Unable to decode EdgeEntity from DataEntity!")
            return
        }

        // Verify EdgeDataEntity only contains config ID, domain, and environment
        let expectedConfigJSON = """
            {
              "edge.configId": "12345-example",
              "edge.domain": "edge.com",
              "edge.environment": "dev"
            }
        """

        assertEqual(expected: expectedConfigJSON, actual: edgeDataEntity.configuration)
    }

    func testHandleExperienceEventRequest_queuedDataEntityContainsIdentityMap() {
        let identityMap: [String: AnyCodable] =
            [
                "ECID": [
                    ["id": "12345-ecid", "authenticatedState": "ambiguous", "primary": false]
                ]
            ]

        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: (identityMap, .set))
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "12345-example"], .set))
        edge.state?.updateCurrentConsent(status: ConsentStatus.yes)
        // UpdateCurrentConsent will enabled hit queue, suspend to capture hit in queue
        edge.state?.hitQueue.suspend()

        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(1, mockDataQueue.count())
        guard let dataEntity = mockDataQueue.peek() else {
            XCTFail("DataEntity was not in MockDataQueue as expected!")
            return
        }

        guard let data = dataEntity.data, let edgeDataEntity = try? JSONDecoder().decode(EdgeDataEntity.self, from: data) else {
            XCTFail("Unable to decode EdgeEntity from DataEntity!")
            return
        }

        // Verify EdgeDataEntity contains identity map
        XCTAssertEqual(1, edgeDataEntity.identityMap.count)
        assertEqual(expected: identityMap, actual: edgeDataEntity.identityMap)
    }

    func testHandleExperienceEventRequest_consentXDMSharedStateInvalid_usesCurrentConsent() {
        edge.state?.updateCurrentConsent(status: ConsentStatus.no)
        // UpdateCurrentConsent will enabled hit queue, suspend to capture hit in queue
        edge.state?.hitQueue.suspend()

        // no consent shared state for current event
        mockRuntime.simulateComingEvents(experienceEvent)

        XCTAssertEqual(0, mockDataQueue.count())
    }

    // MARK: Bypass consent event tests

    /// `isBypassConsentEvent` must be true only for the dedicated `edgeBypassConsent` type paired with `requestContent`.
    func testIsBypassConsentEvent_trueOnlyForBypassConsentTypeAndRequestContentSource() {
        let bypassEvent = Event(name: "bypass",
                                type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                                source: EventSource.requestContent,
                                data: nil)
        XCTAssertTrue(bypassEvent.isBypassConsentEvent)

        // Correct type but wrong source
        let wrongSource = Event(name: "wrong source",
                                type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                                source: EventSource.responseContent,
                                data: nil)
        XCTAssertFalse(wrongSource.isBypassConsentEvent)

        // Correct source but wrong type (standard experience event)
        let experience = Event(name: "experience",
                               type: EventType.edge,
                               source: EventSource.requestContent,
                               data: nil)
        XCTAssertFalse(experience.isBypassConsentEvent)
        XCTAssertTrue(experience.isExperienceEvent)
    }

    /// A bypass-consent event must be queued on the dedicated bypass-consent queue (not the primary queue)
    /// and must not be gated by collect consent = no.
    func testHandleBypassConsentRequest_queuesOnBypassConsentQueue_notPrimaryQueue_regardlessOfCollectConsentNo() {
        // Configuration and Identity shared states required for readyForEvent to pass
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: ([:], .set))
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "12345-example"], .set))
        // Collect consent = no: bypass-consent events must NOT be gated by it
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME,
                                           data: (["consents": ["collect": ["val": "n"]]], .set))
        edge.state?.updateCurrentConsent(status: ConsentStatus.no)

        // Suspend both queues so the queued hit is captured before being processed/dequeued
        edge.state?.hitQueue.suspend()
        edge.state?.bypassConsentHitQueue?.suspend()

        let bypassEvent = Event(name: "Bypass consent event",
                                type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                                source: EventSource.requestContent,
                                data: ["app": ["identifier": "com.example.app"]])
        mockRuntime.simulateComingEvents(bypassEvent)

        // Verify queued on the bypass-consent queue only
        XCTAssertEqual(1, mockBypassConsentDataQueue.count())
        XCTAssertEqual(0, mockDataQueue.count())
    }

    // MARK: Identities reset event tests

    func testHandleIdentitiesResetClearsBypassHitsAndPreservesPrimaryHits() throws {
        let state = try XCTUnwrap(edge.state)
        let bypassQueue = try XCTUnwrap(state.bypassConsentHitQueue)
        state.hitQueue.suspend()
        bypassQueue.suspend()
        let primaryEntity = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: Data())
        let bypassEntity = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: Data())
        XCTAssertTrue(state.hitQueue.queue(entity: primaryEntity))
        XCTAssertTrue(bypassQueue.queue(entity: bypassEntity))
        XCTAssertEqual(1, mockDataQueue.count())
        XCTAssertEqual(1, mockBypassConsentDataQueue.count())

        let reset = Event(name: "Reset Event", type: EventType.genericIdentity, source: EventSource.requestReset, data: nil)
        edge.handleIdentitiesReset(reset)

        XCTAssertEqual(0, mockBypassConsentDataQueue.count())
        XCTAssertEqual(2, mockDataQueue.count())
        XCTAssertEqual(primaryEntity.uniqueIdentifier, mockDataQueue.peek()?.uniqueIdentifier)
        XCTAssertFalse(mockRuntime.dispatchedEvents.contains { $0.type == EdgeConstants.EventType.EDGE_BYPASS_CONSENT })
    }

    func testBypassQueueAcceptsNewIdentityRequestsAfterReset() throws {
        let state = try XCTUnwrap(edge.state)
        let bypassQueue = try XCTUnwrap(state.bypassConsentHitQueue)
        state.hitQueue.suspend()
        bypassQueue.suspend()
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: (["edge.configId": "config"], .set))
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: (["identityMap": ["ECID": [["id": "old-ecid"]]]], .set))
        let oldRequest = Event(name: "device attributes", type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                               source: EventSource.requestContent, data: ["timezone": "Europe/London"])
        edge.handleBypassConsentRequest(oldRequest)
        XCTAssertEqual(1, mockBypassConsentDataQueue.count())

        let reset = Event(name: "Reset Event", type: EventType.genericIdentity, source: EventSource.requestReset, data: nil)
        edge.handleIdentitiesReset(reset)
        XCTAssertEqual(0, mockBypassConsentDataQueue.count())

        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: (["identityMap": ["ECID": [["id": "new-ecid"]]]], .set))
        let newRequest = Event(name: "device attributes", type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                               source: EventSource.requestContent, data: ["timezone": "Asia/Kolkata"])
        edge.handleBypassConsentRequest(newRequest)

        XCTAssertEqual(1, mockBypassConsentDataQueue.count())
        XCTAssertEqual(1, mockDataQueue.count())
        let entity = try XCTUnwrap(mockBypassConsentDataQueue.peek())
        XCTAssertEqual(newRequest.id.uuidString, entity.uniqueIdentifier)
        let data = try XCTUnwrap(entity.data)
        let decoded = try JSONDecoder().decode(EdgeDataEntity.self, from: data)
        let expectedIdentity = #"{"identityMap":{"ECID":[{"id":"new-ecid"}]}}"#
        assertExactMatch(expected: expectedIdentity, actual: decoded.identityMap)
    }

    func testHandleIdentitiesResetWithoutBypassQueuePreservesPrimaryResetFlow() throws {
        let primaryQueue = try XCTUnwrap(edge.state?.hitQueue)
        edge.state = EdgeState(hitQueue: primaryQueue, bypassConsentHitQueue: nil, edgeProperties: EdgeProperties())
        primaryQueue.suspend()
        let primaryEntity = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: Data())
        XCTAssertTrue(primaryQueue.queue(entity: primaryEntity))

        let reset = Event(name: "Reset Event", type: EventType.genericIdentity, source: EventSource.requestReset, data: nil)
        edge.handleIdentitiesReset(reset)

        XCTAssertNil(edge.state?.bypassConsentHitQueue)
        XCTAssertEqual(2, mockDataQueue.count())
        XCTAssertEqual(primaryEntity.uniqueIdentifier, mockDataQueue.peek()?.uniqueIdentifier)
    }

    func testHandleIdentitiesReset() {
        let event = Event(name: "Reset Event",
                          type: EventType.genericIdentity,
                          source: EventSource.requestReset,
                          data: nil)

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockDataQueue.count())
    }
}

extension EdgeExtensionTests {
    private final class SelectiveDataQueueService: NSObject, DataQueuing {
        let primary: DataQueue?
        init(primary: DataQueue?) {
            self.primary = primary
        }
        func getDataQueue(label: String) -> DataQueue? {
            return label == EdgeConstants.EXTENSION_NAME ? primary : nil
        }
        func getDataQueue(label: String, config: DataQueueConfig) -> DataQueue? {
            return getDataQueue(label: label)
        }
    }

    func testBypassQueueCreationFailurePreservesOrdinaryStartupAndQueuing() throws {
        let configuredEdge = Edge(runtime: mockRuntime, dataQueueService: SelectiveDataQueueService(primary: mockDataQueue))
        defer { configuredEdge.onUnregistered() }
        let state = try XCTUnwrap(configuredEdge.state)
        XCTAssertTrue(state.hitQueue is EdgeBatchingHitQueue)
        XCTAssertNil(state.bypassConsentHitQueue)
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: (["edge.configId": "config"], .set))
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME, data: ([:], .set))
        XCTAssertTrue(configuredEdge.readyForEvent(experienceEvent))
        XCTAssertTrue(state.hasBooted)
        XCTAssertEqual(.yes, state.currentCollectConsent)
        state.hitQueue.suspend()
        configuredEdge.handleExperienceEventRequest(experienceEvent)
        XCTAssertEqual(1, mockDataQueue.count())

        let request = Event(name: "device attributes",
                            type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                            source: EventSource.requestContent,
                            data: ["timezone": "Europe/London"])
        XCTAssertTrue(configuredEdge.readyForEvent(request))
        configuredEdge.handleBypassConsentRequest(request)
        let result = try XCTUnwrap(mockRuntime.dispatchedEvents.last)
        XCTAssertEqual(request.id, result.parentID)
        XCTAssertEqual("failed", result.data?["status"] as? String)
        XCTAssertEqual("queueUnavailable", result.data?["reason"] as? String)
        XCTAssertEqual(1, mockDataQueue.count())
    }

    func testPrimaryQueueCreationFailureStillPreventsOrdinaryStartup() {
        let configuredEdge = Edge(runtime: mockRuntime, dataQueueService: SelectiveDataQueueService(primary: nil))
        XCTAssertNil(configuredEdge.state)
        XCTAssertFalse(configuredEdge.readyForEvent(experienceEvent))
    }

    private final class RejectingHitQueue: HitQueuing {
        let processor: HitProcessing = MockHitProcessor()
        private(set) var enqueueAttempts = 0
        func queue(entity: DataEntity) -> Bool {
            enqueueAttempts += 1
            return false
        }
        func beginProcessing() {}
        func suspend() {}
        func clear() {}
        func count() -> Int { return 0 }
        func close() {}
    }

    private final class RecordingHitQueue: HitQueuing {
        let processor: HitProcessing = MockHitProcessor()
        private(set) var entities: [DataEntity] = []
        func queue(entity: DataEntity) -> Bool {
            entities.append(entity)
            return true
        }
        func beginProcessing() {}
        func suspend() {}
        func clear() { entities.removeAll() }
        func count() -> Int { return entities.count }
        func close() {}
    }

    func testBypassFailedEnqueueProducesCorrelatedFailure() throws {
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: (["edge.configId": "config"], .set))
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME, data: ([:], .set))
        let primary = try XCTUnwrap(edge.state?.hitQueue)
        let rejectingQueue = RejectingHitQueue()
        edge.state = EdgeState(hitQueue: primary, bypassConsentHitQueue: rejectingQueue, edgeProperties: EdgeProperties())
        let request = Event(name: "device attributes",
                            type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                            source: EventSource.requestContent,
                            data: ["timezone": "Europe/London"])
        mockRuntime.simulateComingEvents(request)
        XCTAssertEqual(1, rejectingQueue.enqueueAttempts)
        try assertBypassResult(for: request, status: "failed", reason: "queueUnavailable")
    }

    func testOrdinaryFailedEnqueueDoesNotProduceBypassResult() throws {
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: (["edge.configId": "config"], .set))
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME, data: ([:], .set))
        let bypassQueue = try XCTUnwrap(edge.state?.bypassConsentHitQueue)
        let rejectingQueue = RejectingHitQueue()
        edge.state = EdgeState(hitQueue: rejectingQueue, bypassConsentHitQueue: bypassQueue, edgeProperties: EdgeProperties())
        mockRuntime.simulateComingEvents(experienceEvent)
        XCTAssertEqual(1, rejectingQueue.enqueueAttempts)
        XCTAssertFalse(mockRuntime.dispatchedEvents.contains { $0.type == EdgeConstants.EventType.EDGE_BYPASS_CONSENT })
    }

    func testMissingStateReadinessExceptionAppliesOnlyToBypass() {
        edge.state = nil
        let request = Event(name: "device attributes",
                            type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                            source: EventSource.requestContent,
                            data: ["timezone": "Europe/London"])
        XCTAssertTrue(edge.readyForEvent(request))
        XCTAssertFalse(edge.readyForEvent(experienceEvent))
    }

    func testDecodeFailureNotificationIsWiredOnlyToBypassQueue() throws {
        EventHub.reset()
        EventHub.shared.start()
        let configuredEdge = Edge(runtime: mockRuntime)
        defer {
            configuredEdge.onUnregistered()
            EventHub.reset()
        }
        let state = try XCTUnwrap(configuredEdge.state)
        let bypassQueue = try XCTUnwrap(state.bypassConsentHitQueue)
        XCTAssertTrue(state.hitQueue is EdgeBatchingHitQueue)
        XCTAssertTrue(bypassQueue is BypassConsentHitQueue)
        let corruptedData: [Data?] = [nil, Data("{".utf8), Data("{}".utf8)]
        let requestIds = corruptedData.map { _ in UUID().uuidString }
        let result = expectation(description: "Only corrupted bypass hits produce terminal drops")
        result.expectedFulfillmentCount = corruptedData.count
        result.assertForOverFulfill = true
        MobileCore.registerEventListener(type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT, source: EventSource.responseContent) { event in
            XCTAssertNil(event.parentID)
            XCTAssertNil(event.responseID)
            XCTAssertEqual("dropped", event.data?["status"] as? String)
            XCTAssertEqual("invalidPayload", event.data?["reason"] as? String)
            XCTAssertTrue(requestIds.contains(event.data?["requestEventId"] as? String ?? ""))
            result.fulfill()
        }
        for (index, data) in corruptedData.enumerated() {
            let ordinary = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: data)
            state.hitQueue.processor.processHit(entity: ordinary) { finished in XCTAssertTrue(finished) }
            let bypass = DataEntity(uniqueIdentifier: requestIds[index], timestamp: Date(), data: data)
            bypassQueue.processor.processHit(entity: bypass) { finished in XCTAssertTrue(finished) }
        }
        wait(for: [result], timeout: 2)
    }

    private func assertBypassResult(for request: Event, status: String, reason: String,
                                    file: StaticString = #filePath, line: UInt = #line) throws {
        let results = mockRuntime.dispatchedEvents.filter {
            $0.type == EdgeConstants.EventType.EDGE_BYPASS_CONSENT && $0.source == EventSource.responseContent
        }
        XCTAssertEqual(1, results.count, file: file, line: line)
        let result = try XCTUnwrap(results.first, file: file, line: line)
        XCTAssertEqual(request.id, result.parentID, file: file, line: line)
        XCTAssertNil(result.responseID, file: file, line: line)
        XCTAssertEqual(status, result.data?["status"] as? String, file: file, line: line)
        XCTAssertEqual(reason, result.data?["reason"] as? String, file: file, line: line)
        XCTAssertTrue(mockBypassConsentDataQueue.count() == 0, file: file, line: line)
        XCTAssertTrue(mockDataQueue.count() == 0, file: file, line: line)
    }

    func testBypassResultsReachDedicatedListenersAndRetainRequestCorrelation() {
        typealias Status = EdgeConstants.BypassResult.Status
        let request = Event(name: "device attributes", type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                            source: EventSource.requestContent, data: ["timezone": "Europe/London"])
        let listener = EventListenerContainer(listener: { _ in }, type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                                              source: EventSource.responseContent, triggerEventId: nil, timeoutTask: nil)
        for (status, expectedStatus) in [(Status.SUCCESS, "success"), (Status.FAILED, "failed"), (Status.DROPPED, "dropped")] {
            let result = request.createBypassResult(status: status)
            XCTAssertTrue(listener.shouldNotify(result))
            XCTAssertEqual("Edge bypass result", result.name)
            XCTAssertEqual("com.adobe.eventType.edgeBypassConsent", result.type)
            XCTAssertEqual("com.adobe.eventSource.responseContent", result.source)
            XCTAssertEqual(request.id, result.parentID)
            XCTAssertNil(result.responseID)
            XCTAssertEqual(["status": expectedStatus] as NSDictionary, result.data as NSDictionary?)
        }
        let result = request.createBypassResult(status: Status.FAILED, reason: EdgeConstants.BypassResult.Reason.NETWORK, httpStatus: 404)
        XCTAssertEqual(["status": "failed", "reason": "network", "httpStatus": 404] as NSDictionary, result.data as NSDictionary?)
    }

    func testBypassResultConstantsPreserveWireValues() {
        typealias Keys = EdgeConstants.EventDataKeys.BypassResult
        typealias Status = EdgeConstants.BypassResult.Status
        typealias Reason = EdgeConstants.BypassResult.Reason

        XCTAssertEqual(["status", "reason", "httpStatus", "requestEventId"],
                       [Keys.STATUS, Keys.REASON, Keys.HTTP_STATUS, Keys.REQUEST_EVENT_ID])
        XCTAssertEqual(["success", "failed", "dropped"], [Status.SUCCESS, Status.FAILED, Status.DROPPED])
        XCTAssertEqual(["missingConfig", "invalidPayload", "queueUnavailable", "network"],
                       [Reason.MISSING_CONFIG, Reason.INVALID_PAYLOAD, Reason.QUEUE_UNAVAILABLE, Reason.NETWORK])
        XCTAssertEqual("Edge bypass result", EdgeConstants.EventName.BYPASS_RESULT)
    }

    func testBypassDecodeDropPreservesUnchainedWireContract() {
        let requestId = UUID().uuidString
        let result = Event.createBypassDropResult(requestEventId: requestId)

        XCTAssertEqual("Edge bypass result", result.name)
        XCTAssertEqual("com.adobe.eventType.edgeBypassConsent", result.type)
        XCTAssertEqual("com.adobe.eventSource.responseContent", result.source)
        XCTAssertNil(result.parentID)
        XCTAssertNil(result.responseID)
        XCTAssertEqual(["status": "dropped", "reason": "invalidPayload", "requestEventId": requestId] as NSDictionary,
                       result.data as NSDictionary?)
    }

    func testBypassRequestUsesDedicatedQueueForEveryCollectConsent() throws {
        let primaryQueue = RecordingHitQueue()
        let bypassQueue = RecordingHitQueue()
        edge.state?.hitQueue.close()
        edge.state?.bypassConsentHitQueue?.close()
        edge.state = EdgeState(hitQueue: primaryQueue, bypassConsentHitQueue: bypassQueue, edgeProperties: EdgeProperties())
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME, data: ([:], .set))
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: (["edge.configId": "config", "edge.batching": ["enabled": true, "maxBatchSize": 10]], .set))
        XCTAssertTrue(edge.readyForEvent(experienceEvent))
        for (index, consent) in [ConsentStatus.no, .pending, .yes].enumerated() {
            edge.state?.updateCurrentConsent(status: consent)
            XCTAssertEqual(consent, edge.state?.currentCollectConsent)
            let request = Event(name: "device attributes", type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                                source: EventSource.requestContent, data: ["timezone": "Europe/London"])
            mockRuntime.simulateComingEvents(request)
            XCTAssertEqual(index + 1, bypassQueue.count())
            XCTAssertEqual(request.id.uuidString, bypassQueue.entities.last?.uniqueIdentifier)
            let data = try XCTUnwrap(bypassQueue.entities.last?.data)
            let persisted = try JSONDecoder().decode(EdgeDataEntity.self, from: data)
            XCTAssertNil(persisted.configuration["edge.batching"])
            XCTAssertEqual(0, primaryQueue.count())
        }
        XCTAssertNotNil(mockRuntime.getListener(type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT, source: EventSource.requestContent))
    }

    func testBypassMissingQueueProducesCorrelatedFailure() throws {
        edge.state = nil
        let request = Event(name: "device attributes", type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                            source: EventSource.requestContent, data: ["timezone": "Europe/London"])
        mockRuntime.simulateComingEvents(request)
        try assertBypassResult(for: request, status: "failed", reason: "queueUnavailable")
    }

    func testBypassEmptyPayloadProducesCorrelatedDrop() throws {
        for data in [nil, [:]] as [[String: Any]?] {
            mockRuntime.resetDispatchedEventAndCreatedSharedStates()
            let request = Event(name: "device attributes", type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                                source: EventSource.requestContent, data: data)
            mockRuntime.simulateComingEvents(request)
            try assertBypassResult(for: request, status: "dropped", reason: "invalidPayload")
        }
    }

    func testBypassMissingConfigurationProducesCorrelatedDrop() throws {
        let configurations: [[String: Any]] = [[:], ["edge.configId": ""]]
        for config in configurations {
            mockRuntime.resetDispatchedEventAndCreatedSharedStates()
            mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME, data: (config, .set))
            let request = Event(name: "device attributes", type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                                source: EventSource.requestContent, data: ["timezone": "Europe/London"])
            mockRuntime.simulateComingEvents(request)
            try assertBypassResult(for: request, status: "dropped", reason: "missingConfig")
        }
    }

    func testBypassMissingIdentityProducesCorrelatedDrop() throws {
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: (["edge.configId": "config"], .set))
        let request = Event(name: "device attributes", type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                            source: EventSource.requestContent, data: ["timezone": "Europe/London"])
        mockRuntime.simulateComingEvents(request)
        try assertBypassResult(for: request, status: "dropped", reason: "invalidPayload")
    }

    func testBypassUnencodablePayloadProducesCorrelatedDrop() throws {
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: (["edge.configId": "config"], .set))
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME, data: ([:], .set))
        let request = Event(name: "device attributes", type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                            source: EventSource.requestContent, data: ["invalid": Double.nan])
        mockRuntime.simulateComingEvents(request)
        try assertBypassResult(for: request, status: "dropped", reason: "invalidPayload")
    }
}

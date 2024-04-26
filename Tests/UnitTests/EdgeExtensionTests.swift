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

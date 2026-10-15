//
// Copyright 2026 Adobe. All rights reserved.
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

class DeviceAttributesEdgeExtensionTests: XCTestCase, AnyCodableAsserts {
    private let experienceEvent = Event(name: "Experience event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["data": "example"]])
    private var mockRuntime: TestableExtensionRuntime!
    private var edge: Edge!
    private var mockDataQueue: MockDataQueue!
    private var mockBypassDataQueue: MockDataQueue!

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        mockRuntime = TestableExtensionRuntime()
        mockDataQueue = MockDataQueue()
        mockBypassDataQueue = MockDataQueue()

        edge = Edge(runtime: mockRuntime)
        edge.state = EdgeState(hitQueue: PersistentHitQueue(dataQueue: mockDataQueue, processor: MockHitProcessor()),
                               bypassConsentHitQueue: PersistentHitQueue(dataQueue: mockBypassDataQueue, processor: MockHitProcessor()),
                               edgeProperties: EdgeProperties())
        edge.onRegistered()
    }

    override func tearDown() {
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    // MARK: Helpers

    private final class BypassDataQueueService: NSObject, DataQueuing {
        let bypassQueue: DataQueue?
        private(set) var requestedLabels: [String] = []

        init(bypassQueue: DataQueue?) {
            self.bypassQueue = bypassQueue
        }

        func getDataQueue(label: String) -> DataQueue? {
            requestedLabels.append(label)
            return label == "com.adobe.edge.bypassConsent" ? bypassQueue : nil
        }

        func getDataQueue(label: String, config: DataQueueConfig) -> DataQueue? {
            return getDataQueue(label: label)
        }
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
        private(set) var beginProcessingCount = 0
        private(set) var clearCount = 0
        func queue(entity: DataEntity) -> Bool {
            entities.append(entity)
            return true
        }
        func beginProcessing() { beginProcessingCount += 1 }
        func suspend() {}
        func clear() {
            clearCount += 1
            entities.removeAll()
        }
        func count() -> Int { return entities.count }
        func close() {}
    }

    private func makeRequest(data: [String: Any]? = ["timezone": "Europe/London"]) -> Event {
        return Event(name: "device attributes",
                     type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                     source: EventSource.requestContent,
                     data: data)
    }

    private func simulateConfigAndIdentity(identity: [String: Any] = [:]) {
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "config"], .set))
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME, data: (identity, .set))
    }

    private func bypassResults() -> [Event] {
        return mockRuntime.dispatchedEvents.filter {
            $0.type == EdgeConstants.EventType.EDGE_BYPASS_CONSENT && $0.source == EventSource.responseContent
        }
    }

    private func assertBypassResult(for request: Event, status: String, reason: String,
                                    file: StaticString = #filePath, line: UInt = #line) throws {
        let results = bypassResults()
        XCTAssertEqual(1, results.count, file: file, line: line)
        let result = try XCTUnwrap(results.first, file: file, line: line)
        XCTAssertEqual(request.id, result.parentID, file: file, line: line)
        XCTAssertNil(result.responseID, file: file, line: line)
        XCTAssertEqual(status, result.data?["status"] as? String, file: file, line: line)
        XCTAssertEqual(reason, result.data?["reason"] as? String, file: file, line: line)
        XCTAssertEqual(0, mockBypassDataQueue.count(), file: file, line: line)
        XCTAssertEqual(0, mockDataQueue.count(), file: file, line: line)
    }

    // MARK: Event classification and wiring

    func testIsBypassConsentEvent_trueOnlyForBypassConsentTypeAndRequestContentSource() {
        XCTAssertTrue(makeRequest().isBypassConsentEvent)

        let wrongSource = Event(name: "wrong source", type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT, source: EventSource.responseContent, data: nil)
        XCTAssertFalse(wrongSource.isBypassConsentEvent)

        XCTAssertFalse(experienceEvent.isBypassConsentEvent)
        XCTAssertTrue(experienceEvent.isExperienceEvent)
    }

    func testOnRegistered_registersBypassListener() {
        XCTAssertNotNil(mockRuntime.getListener(type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT, source: EventSource.requestContent))
    }

    func testInit_createsBypassQueueWithDedicatedLabel() throws {
        let service = BypassDataQueueService(bypassQueue: MockDataQueue())
        let configuredEdge = Edge(runtime: mockRuntime, bypassConsentDataQueueService: service)
        defer { configuredEdge.onUnregistered() }

        XCTAssertEqual(["com.adobe.edge.bypassConsent"], service.requestedLabels)
        let bypassQueue = try XCTUnwrap(configuredEdge.state?.bypassConsentHitQueue as? PersistentHitQueue)
        XCTAssertTrue(bypassQueue.processor is DeviceAttributesHitProcessor)
        XCTAssertTrue(configuredEdge.state?.hitQueue is EdgeBatchingHitQueue)
    }

    // MARK: Queueing

    func testHandleBypassConsentRequest_queuesOnBypassQueueOnly_regardlessOfCollectConsentNo() throws {
        simulateConfigAndIdentity(identity: ["identityMap": ["ECID": [["id": "ecid"]]]])
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME,
                                           data: (["consents": ["collect": ["val": "n"]]], .set))
        edge.state?.updateCurrentConsent(status: ConsentStatus.no)
        edge.state?.hitQueue.suspend()
        edge.state?.bypassConsentHitQueue?.suspend()

        let request = makeRequest(data: ["app": ["identifier": "com.example.app"]])
        mockRuntime.simulateComingEvents(request)

        XCTAssertEqual(1, mockBypassDataQueue.count())
        XCTAssertEqual(0, mockDataQueue.count())
        XCTAssertTrue(bypassResults().isEmpty)

        let entity = try XCTUnwrap(mockBypassDataQueue.peek())
        XCTAssertEqual(request.id.uuidString, entity.uniqueIdentifier)
        XCTAssertEqual(request.timestamp, entity.timestamp)
        let decoded = try JSONDecoder().decode(EdgeDataEntity.self, from: try XCTUnwrap(entity.data))
        XCTAssertEqual(request.id, decoded.event.id)
        assertExactMatch(expected: #"{"edge.configId":"config"}"#, actual: decoded.configuration)
        assertExactMatch(expected: #"{"identityMap":{"ECID":[{"id":"ecid"}]}}"#, actual: decoded.identityMap)
    }

    func testBypassRequestUsesDedicatedQueueForEveryCollectConsent() {
        let primaryQueue = RecordingHitQueue()
        let bypassQueue = RecordingHitQueue()
        edge.state = EdgeState(hitQueue: primaryQueue, bypassConsentHitQueue: bypassQueue, edgeProperties: EdgeProperties())
        simulateConfigAndIdentity()
        XCTAssertTrue(edge.readyForEvent(experienceEvent))

        for (index, consent) in [ConsentStatus.no, .pending, .yes].enumerated() {
            edge.state?.updateCurrentConsent(status: consent)
            let request = makeRequest()
            XCTAssertTrue(edge.readyForEvent(request))
            mockRuntime.simulateComingEvents(request)
            XCTAssertEqual(index + 1, bypassQueue.count())
            XCTAssertEqual(request.id.uuidString, bypassQueue.entities.last?.uniqueIdentifier)
            XCTAssertEqual(0, primaryQueue.count())
        }
        XCTAssertEqual(0, bypassQueue.clearCount)
        XCTAssertTrue(bypassResults().isEmpty)
    }

    // MARK: Readiness and bootup

    func testReadyForEvent_bypassRequiresConfigurationAndIdentity() {
        let request = makeRequest()
        XCTAssertFalse(edge.readyForEvent(request))

        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "config"], .set))
        XCTAssertFalse(edge.readyForEvent(request))

        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME, data: ([:], .set))
        XCTAssertTrue(edge.readyForEvent(request))
    }

    func testReadyForEvent_bootsStateAndStartsBypassQueueOnce() {
        let bypassQueue = RecordingHitQueue()
        edge.state = EdgeState(hitQueue: RecordingHitQueue(), bypassConsentHitQueue: bypassQueue, edgeProperties: EdgeProperties())
        XCTAssertEqual(0, bypassQueue.beginProcessingCount)

        simulateConfigAndIdentity()
        XCTAssertTrue(edge.readyForEvent(makeRequest()))
        XCTAssertTrue(edge.readyForEvent(experienceEvent))

        XCTAssertEqual(true, edge.state?.hasBooted)
        XCTAssertEqual(1, bypassQueue.beginProcessingCount)
    }

    func testMissingStateReadinessExceptionAppliesOnlyToBypass() {
        edge.state = nil
        XCTAssertTrue(edge.readyForEvent(makeRequest()))
        XCTAssertFalse(edge.readyForEvent(experienceEvent))
    }

    // MARK: Identity reset

    func testHandleIdentitiesReset_doesNotTouchBypassQueue() throws {
        let primaryQueue = RecordingHitQueue()
        let bypassQueue = RecordingHitQueue()
        edge.state = EdgeState(hitQueue: primaryQueue, bypassConsentHitQueue: bypassQueue, edgeProperties: EdgeProperties())
        let bypassEntity = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: Data())
        XCTAssertTrue(bypassQueue.queue(entity: bypassEntity))

        let reset = Event(name: "Reset Event", type: EventType.genericIdentity, source: EventSource.requestReset, data: nil)
        mockRuntime.simulateComingEvents(reset)

        XCTAssertEqual(0, bypassQueue.clearCount)
        XCTAssertEqual([bypassEntity.uniqueIdentifier], bypassQueue.entities.map { $0.uniqueIdentifier })
        XCTAssertEqual(1, primaryQueue.count())
        let resetEntity = try XCTUnwrap(primaryQueue.entities.first)
        XCTAssertEqual(reset.id.uuidString, resetEntity.uniqueIdentifier)
        XCTAssertTrue(bypassResults().isEmpty)
    }

    func testBypassQueueAcceptsNewIdentityRequestsAfterReset() throws {
        edge.state?.hitQueue.suspend()
        edge.state?.bypassConsentHitQueue?.suspend()
        simulateConfigAndIdentity(identity: ["identityMap": ["ECID": [["id": "old-ecid"]]]])
        edge.handleBypassConsentRequest(makeRequest())

        let reset = Event(name: "Reset Event", type: EventType.genericIdentity, source: EventSource.requestReset, data: nil)
        edge.handleIdentitiesReset(reset)
        XCTAssertEqual(1, mockBypassDataQueue.count())
        XCTAssertEqual(1, mockDataQueue.count())

        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: (["identityMap": ["ECID": [["id": "new-ecid"]]]], .set))
        let newRequest = makeRequest(data: ["timezone": "Asia/Kolkata"])
        edge.handleBypassConsentRequest(newRequest)

        XCTAssertEqual(2, mockBypassDataQueue.count())
        XCTAssertEqual(1, mockDataQueue.count())
        _ = mockBypassDataQueue.remove()
        let entity = try XCTUnwrap(mockBypassDataQueue.peek())
        XCTAssertEqual(newRequest.id.uuidString, entity.uniqueIdentifier)
        let decoded = try JSONDecoder().decode(EdgeDataEntity.self, from: try XCTUnwrap(entity.data))
        assertExactMatch(expected: #"{"identityMap":{"ECID":[{"id":"new-ecid"}]}}"#, actual: decoded.identityMap)
    }

    // MARK: Failure and drop results

    func testBypassQueueCreationFailurePreservesOrdinaryQueueing() throws {
        let configuredEdge = Edge(runtime: mockRuntime, bypassConsentDataQueueService: BypassDataQueueService(bypassQueue: nil))
        defer { configuredEdge.onUnregistered() }
        let state = try XCTUnwrap(configuredEdge.state)
        XCTAssertNil(state.bypassConsentHitQueue)
        XCTAssertTrue(state.hitQueue is EdgeBatchingHitQueue)

        let request = makeRequest()
        XCTAssertTrue(configuredEdge.readyForEvent(request))
        configuredEdge.handleBypassConsentRequest(request)

        try assertBypassResult(for: request, status: "failed", reason: "queueUnavailable")
    }

    func testBypassMissingQueueProducesCorrelatedFailure() throws {
        edge.state = nil
        let request = makeRequest()
        mockRuntime.simulateComingEvents(request)
        try assertBypassResult(for: request, status: "failed", reason: "queueUnavailable")
    }

    func testBypassFailedEnqueueProducesCorrelatedFailure() throws {
        simulateConfigAndIdentity()
        let primary = try XCTUnwrap(edge.state?.hitQueue)
        let rejectingQueue = RejectingHitQueue()
        edge.state = EdgeState(hitQueue: primary, bypassConsentHitQueue: rejectingQueue, edgeProperties: EdgeProperties())
        let request = makeRequest()
        mockRuntime.simulateComingEvents(request)
        XCTAssertEqual(1, rejectingQueue.enqueueAttempts)
        try assertBypassResult(for: request, status: "failed", reason: "queueUnavailable")
    }

    func testOrdinaryFailedEnqueueDoesNotProduceBypassResult() throws {
        simulateConfigAndIdentity()
        let bypassQueue = try XCTUnwrap(edge.state?.bypassConsentHitQueue)
        let rejectingQueue = RejectingHitQueue()
        edge.state = EdgeState(hitQueue: rejectingQueue, bypassConsentHitQueue: bypassQueue, edgeProperties: EdgeProperties())
        mockRuntime.simulateComingEvents(experienceEvent)
        XCTAssertEqual(1, rejectingQueue.enqueueAttempts)
        XCTAssertTrue(bypassResults().isEmpty)
    }

    func testBypassEmptyPayloadProducesCorrelatedDrop() throws {
        simulateConfigAndIdentity()
        for data in [nil, [:]] as [[String: Any]?] {
            mockRuntime.resetDispatchedEventAndCreatedSharedStates()
            let request = makeRequest(data: data)
            mockRuntime.simulateComingEvents(request)
            try assertBypassResult(for: request, status: "dropped", reason: "invalidPayload")
        }
    }

    func testBypassMissingConfigurationProducesCorrelatedDrop() throws {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME, data: ([:], .set))
        let configurations: [[String: Any]] = [[:], [EdgeConstants.SharedState.Configuration.CONFIG_ID: ""]]
        for config in configurations {
            mockRuntime.resetDispatchedEventAndCreatedSharedStates()
            mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME, data: (config, .set))
            let request = makeRequest()
            mockRuntime.simulateComingEvents(request)
            try assertBypassResult(for: request, status: "dropped", reason: "missingConfig")
        }
    }

    func testBypassMissingIdentityProducesCorrelatedDrop() throws {
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "config"], .set))
        let request = makeRequest()
        mockRuntime.simulateComingEvents(request)
        try assertBypassResult(for: request, status: "dropped", reason: "invalidPayload")
    }

    func testBypassUnencodablePayloadProducesCorrelatedDrop() throws {
        simulateConfigAndIdentity()
        let request = makeRequest(data: ["invalid": Double.nan])
        mockRuntime.simulateComingEvents(request)
        try assertBypassResult(for: request, status: "dropped", reason: "invalidPayload")
    }

    // MARK: Decode failure

    func testDecodeFailure_producesUnchainedDropOnlyForBypassQueue() throws {
        let configuredEdge = Edge(runtime: mockRuntime, bypassConsentDataQueueService: BypassDataQueueService(bypassQueue: MockDataQueue()))
        defer { configuredEdge.onUnregistered() }
        let state = try XCTUnwrap(configuredEdge.state)
        let bypassQueue = try XCTUnwrap(state.bypassConsentHitQueue)
        let corruptedData: [Data?] = [nil, Data("{".utf8), Data("{}".utf8)]
        var requestIds: [String] = []

        for data in corruptedData {
            let ordinary = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: data)
            state.hitQueue.processor.processHit(entity: ordinary) { finished in XCTAssertTrue(finished) }
            let bypass = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: data)
            requestIds.append(bypass.uniqueIdentifier)
            bypassQueue.processor.processHit(entity: bypass) { finished in XCTAssertTrue(finished) }
        }

        let results = bypassResults()
        XCTAssertEqual(corruptedData.count, results.count)
        XCTAssertEqual(results.count, mockRuntime.dispatchedEvents.count)
        for (result, requestId) in zip(results, requestIds) {
            XCTAssertNil(result.parentID)
            XCTAssertNil(result.responseID)
            XCTAssertEqual(["status": "dropped", "reason": "invalidPayload", "requestEventId": requestId] as NSDictionary,
                           result.data as NSDictionary?)
        }
    }

    // MARK: Result event contract

    func testBypassResultsRetainRequestCorrelation() {
        typealias Status = EdgeConstants.BypassResult.Status
        let request = makeRequest()
        let listener = EventListenerContainer(listener: { _ in }, type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                                              source: EventSource.responseContent, triggerEventId: nil, timeoutTask: nil)
        for (status, expectedStatus) in [(Status.SUCCESS, "success"), (Status.FAILED, "failed"), (Status.DROPPED, "dropped")] {
            let result = request.createBypassResult(status: status)
            XCTAssertTrue(listener.shouldNotify(result))
            XCTAssertEqual("Device Attributes Response", result.name)
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

        XCTAssertEqual("com.adobe.eventType.edgeBypassConsent", EdgeConstants.EventType.EDGE_BYPASS_CONSENT)
        XCTAssertEqual(["status", "reason", "httpStatus", "requestEventId"],
                       [Keys.STATUS, Keys.REASON, Keys.HTTP_STATUS, Keys.REQUEST_EVENT_ID])
        XCTAssertEqual(["success", "failed", "dropped"], [Status.SUCCESS, Status.FAILED, Status.DROPPED])
        XCTAssertEqual(["missingConfig", "invalidPayload", "queueUnavailable", "network"],
                       [Reason.MISSING_CONFIG, Reason.INVALID_PAYLOAD, Reason.QUEUE_UNAVAILABLE, Reason.NETWORK])
        XCTAssertEqual("Device Attributes Response", EdgeConstants.EventName.BYPASS_RESULT)
    }

    func testBypassDecodeDropPreservesUnchainedWireContract() {
        let requestId = UUID().uuidString
        let result = Event.createBypassDropResult(requestEventId: requestId)

        XCTAssertEqual("Device Attributes Response", result.name)
        XCTAssertEqual("com.adobe.eventType.edgeBypassConsent", result.type)
        XCTAssertEqual("com.adobe.eventSource.responseContent", result.source)
        XCTAssertNil(result.parentID)
        XCTAssertNil(result.responseID)
        XCTAssertEqual(["status": "dropped", "reason": "invalidPayload", "requestEventId": requestId] as NSDictionary,
                       result.data as NSDictionary?)
    }
}

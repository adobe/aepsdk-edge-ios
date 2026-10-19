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
    private var mockDeviceAttributesDataQueue: MockDataQueue!

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        mockRuntime = TestableExtensionRuntime()
        mockDataQueue = MockDataQueue()
        mockDeviceAttributesDataQueue = MockDataQueue()

        edge = Edge(runtime: mockRuntime)
        edge.state = EdgeState(hitQueue: PersistentHitQueue(dataQueue: mockDataQueue, processor: MockHitProcessor()),
                               deviceAttributesHitQueue: PersistentHitQueue(dataQueue: mockDeviceAttributesDataQueue, processor: MockHitProcessor()),
                               edgeProperties: EdgeProperties())
        edge.onRegistered()
    }

    override func tearDown() {
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    // MARK: Helpers

    private final class DeviceAttributesDataQueueService: NSObject, DataQueuing {
        let deviceAttributesQueue: DataQueue?
        private(set) var requestedLabels: [String] = []

        init(deviceAttributesQueue: DataQueue?) {
            self.deviceAttributesQueue = deviceAttributesQueue
        }

        func getDataQueue(label: String) -> DataQueue? {
            requestedLabels.append(label)
            return label == "com.adobe.edge.deviceAttributes" ? deviceAttributesQueue : nil
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

    /// Records requests and replies synchronously with `response`.
    private final class RecordingNetworking: Networking {
        let response: HttpConnection
        private(set) var requests: [NetworkRequest] = []
        init(response: HttpConnection) {
            self.response = response
        }
        func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {
            requests.append(networkRequest)
            completionHandler?(response)
        }
    }

    private func makeRequest(data: [String: Any]? = ["timezone": "Europe/London"]) -> Event {
        return Event(name: "device attributes",
                     type: EdgeConstants.DeviceAttributes.EVENT_TYPE,
                     source: EventSource.requestContent,
                     data: data)
    }

    private func simulateConfigAndIdentity(identity: [String: Any] = [:]) {
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "config"], .set))
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME, data: (identity, .set))
    }

    private func deviceAttributesResponses() -> [Event] {
        return mockRuntime.dispatchedEvents.filter {
            $0.type == EdgeConstants.DeviceAttributes.EVENT_TYPE && $0.source == EventSource.responseContent
        }
    }

    private func assertDeviceAttributesResponse(for request: Event, status: String, reason: String,
                                    file: StaticString = #filePath, line: UInt = #line) throws {
        let results = deviceAttributesResponses()
        XCTAssertEqual(1, results.count, file: file, line: line)
        let result = try XCTUnwrap(results.first, file: file, line: line)
        XCTAssertEqual(request.id, result.parentID, file: file, line: line)
        XCTAssertNil(result.responseID, file: file, line: line)
        XCTAssertEqual(status, result.data?["status"] as? String, file: file, line: line)
        XCTAssertEqual(reason, result.data?["reason"] as? String, file: file, line: line)
        XCTAssertEqual(0, mockDeviceAttributesDataQueue.count(), file: file, line: line)
        XCTAssertEqual(0, mockDataQueue.count(), file: file, line: line)
    }

    // MARK: Event classification and wiring

    func testIsDeviceAttributesRequestEvent_trueOnlyForDeviceAttributesTypeAndRequestContentSource() {
        XCTAssertTrue(makeRequest().isDeviceAttributesRequestEvent)

        let wrongSource = Event(name: "wrong source", type: EdgeConstants.DeviceAttributes.EVENT_TYPE, source: EventSource.responseContent, data: nil)
        XCTAssertFalse(wrongSource.isDeviceAttributesRequestEvent)

        XCTAssertFalse(experienceEvent.isDeviceAttributesRequestEvent)
        XCTAssertTrue(experienceEvent.isExperienceEvent)
    }

    func testOnRegistered_registersDeviceAttributesListener() {
        XCTAssertNotNil(mockRuntime.getListener(type: EdgeConstants.DeviceAttributes.EVENT_TYPE, source: EventSource.requestContent))
    }

    func testSetupDeviceAttributesHitQueue_usesDedicatedLabelAndProcessor() throws {
        let service = DeviceAttributesDataQueueService(deviceAttributesQueue: MockDataQueue())
        let deviceAttributesQueue = try XCTUnwrap(edge.setupDeviceAttributesHitQueue(dataQueueService: service) as? PersistentHitQueue)

        XCTAssertEqual(["com.adobe.edge.deviceAttributes"], service.requestedLabels)
        XCTAssertTrue(deviceAttributesQueue.processor is DeviceAttributesHitProcessor)
    }

    func testInit_createsPrimaryAndDeviceAttributesQueues() throws {
        let state = try XCTUnwrap(Edge(runtime: mockRuntime).state)

        XCTAssertTrue(state.hitQueue is EdgeBatchingHitQueue)
        let deviceAttributesQueue = try XCTUnwrap(state.deviceAttributesHitQueue as? PersistentHitQueue)
        XCTAssertTrue(deviceAttributesQueue.processor is DeviceAttributesHitProcessor)
    }

    // MARK: Queueing

    func testHandleDeviceAttributesRequest_queuesOnDeviceAttributesQueueOnly_regardlessOfCollectConsentNo() throws {
        simulateConfigAndIdentity(identity: ["identityMap": ["ECID": [["id": "ecid"]]]])
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME,
                                           data: (["consents": ["collect": ["val": "n"]]], .set))
        edge.state?.updateCurrentConsent(status: ConsentStatus.no)
        edge.state?.hitQueue.suspend()
        edge.state?.deviceAttributesHitQueue?.suspend()

        let request = makeRequest(data: ["app": ["identifier": "com.example.app"]])
        mockRuntime.simulateComingEvents(request)

        XCTAssertEqual(1, mockDeviceAttributesDataQueue.count())
        XCTAssertEqual(0, mockDataQueue.count())
        XCTAssertTrue(deviceAttributesResponses().isEmpty)

        let entity = try XCTUnwrap(mockDeviceAttributesDataQueue.peek())
        XCTAssertEqual(request.id.uuidString, entity.uniqueIdentifier)
        XCTAssertEqual(request.timestamp, entity.timestamp)
        let decoded = try JSONDecoder().decode(EdgeDataEntity.self, from: try XCTUnwrap(entity.data))
        XCTAssertEqual(request.id, decoded.event.id)
        assertExactMatch(expected: #"{"edge.configId":"config"}"#, actual: decoded.configuration)
        assertExactMatch(expected: #"{"identityMap":{"ECID":[{"id":"ecid"}]}}"#, actual: decoded.identityMap)
    }

    func testDeviceAttributesRequestUsesDedicatedQueueForEveryCollectConsent() {
        let primaryQueue = RecordingHitQueue()
        let deviceAttributesQueue = RecordingHitQueue()
        edge.state = EdgeState(hitQueue: primaryQueue, deviceAttributesHitQueue: deviceAttributesQueue, edgeProperties: EdgeProperties())
        simulateConfigAndIdentity()
        XCTAssertTrue(edge.readyForEvent(experienceEvent))

        for (index, consent) in [ConsentStatus.no, .pending, .yes].enumerated() {
            edge.state?.updateCurrentConsent(status: consent)
            let request = makeRequest()
            XCTAssertTrue(edge.readyForEvent(request))
            mockRuntime.simulateComingEvents(request)
            XCTAssertEqual(index + 1, deviceAttributesQueue.count())
            XCTAssertEqual(request.id.uuidString, deviceAttributesQueue.entities.last?.uniqueIdentifier)
            XCTAssertEqual(0, primaryQueue.count())
        }
        XCTAssertEqual(0, deviceAttributesQueue.clearCount)
        XCTAssertTrue(deviceAttributesResponses().isEmpty)
    }

    // MARK: Readiness and bootup

    func testReadyForEvent_deviceAttributesRequiresConfigurationAndIdentity() {
        let request = makeRequest()
        XCTAssertFalse(edge.readyForEvent(request))

        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "config"], .set))
        XCTAssertFalse(edge.readyForEvent(request))

        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME, data: ([:], .set))
        XCTAssertTrue(edge.readyForEvent(request))
    }

    func testReadyForEvent_bootsStateAndStartsDeviceAttributesQueueOnce() {
        let deviceAttributesQueue = RecordingHitQueue()
        edge.state = EdgeState(hitQueue: RecordingHitQueue(), deviceAttributesHitQueue: deviceAttributesQueue, edgeProperties: EdgeProperties())
        XCTAssertEqual(0, deviceAttributesQueue.beginProcessingCount)

        simulateConfigAndIdentity()
        XCTAssertTrue(edge.readyForEvent(makeRequest()))
        XCTAssertTrue(edge.readyForEvent(experienceEvent))

        XCTAssertEqual(true, edge.state?.hasBooted)
        XCTAssertEqual(1, deviceAttributesQueue.beginProcessingCount)
    }

    func testReadyForEvent_missingState_blocksDeviceAttributesLikeOtherEvents() {
        simulateConfigAndIdentity()
        edge.state = nil
        XCTAssertFalse(edge.readyForEvent(makeRequest()))
        XCTAssertFalse(edge.readyForEvent(experienceEvent))
    }

    // MARK: Identity reset

    func testHandleIdentitiesReset_doesNotTouchDeviceAttributesQueue() throws {
        let primaryQueue = RecordingHitQueue()
        let deviceAttributesQueue = RecordingHitQueue()
        edge.state = EdgeState(hitQueue: primaryQueue, deviceAttributesHitQueue: deviceAttributesQueue, edgeProperties: EdgeProperties())
        let deviceAttributesEntity = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: Data())
        XCTAssertTrue(deviceAttributesQueue.queue(entity: deviceAttributesEntity))

        let reset = Event(name: "Reset Event", type: EventType.genericIdentity, source: EventSource.requestReset, data: nil)
        mockRuntime.simulateComingEvents(reset)

        XCTAssertEqual(0, deviceAttributesQueue.clearCount)
        XCTAssertEqual([deviceAttributesEntity.uniqueIdentifier], deviceAttributesQueue.entities.map { $0.uniqueIdentifier })
        XCTAssertEqual(1, primaryQueue.count())
        let resetEntity = try XCTUnwrap(primaryQueue.entities.first)
        XCTAssertEqual(reset.id.uuidString, resetEntity.uniqueIdentifier)
        XCTAssertTrue(deviceAttributesResponses().isEmpty)
    }

    func testDeviceAttributesQueueAcceptsNewIdentityRequestsAfterReset() throws {
        edge.state?.hitQueue.suspend()
        edge.state?.deviceAttributesHitQueue?.suspend()
        simulateConfigAndIdentity(identity: ["identityMap": ["ECID": [["id": "old-ecid"]]]])
        edge.handleDeviceAttributesRequest(makeRequest())

        let reset = Event(name: "Reset Event", type: EventType.genericIdentity, source: EventSource.requestReset, data: nil)
        edge.handleIdentitiesReset(reset)
        XCTAssertEqual(1, mockDeviceAttributesDataQueue.count())
        XCTAssertEqual(1, mockDataQueue.count())

        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME,
                                           data: (["identityMap": ["ECID": [["id": "new-ecid"]]]], .set))
        let newRequest = makeRequest(data: ["timezone": "Asia/Kolkata"])
        edge.handleDeviceAttributesRequest(newRequest)

        XCTAssertEqual(2, mockDeviceAttributesDataQueue.count())
        XCTAssertEqual(1, mockDataQueue.count())
        _ = mockDeviceAttributesDataQueue.remove()
        let entity = try XCTUnwrap(mockDeviceAttributesDataQueue.peek())
        XCTAssertEqual(newRequest.id.uuidString, entity.uniqueIdentifier)
        let decoded = try JSONDecoder().decode(EdgeDataEntity.self, from: try XCTUnwrap(entity.data))
        assertExactMatch(expected: #"{"identityMap":{"ECID":[{"id":"new-ecid"}]}}"#, actual: decoded.identityMap)
    }

    // MARK: Failed and dropped responses

    func testDeviceAttributesQueueCreationFailurePreservesOrdinaryQueueing() throws {
        let failingService = DeviceAttributesDataQueueService(deviceAttributesQueue: nil)
        XCTAssertNil(edge.setupDeviceAttributesHitQueue(dataQueueService: failingService))
        let primaryQueue = RecordingHitQueue()
        edge.state = EdgeState(hitQueue: primaryQueue,
                               deviceAttributesHitQueue: edge.setupDeviceAttributesHitQueue(dataQueueService: failingService),
                               edgeProperties: EdgeProperties())

        let request = makeRequest()
        simulateConfigAndIdentity()
        XCTAssertTrue(edge.readyForEvent(request))
        edge.handleDeviceAttributesRequest(request)
        edge.handleExperienceEventRequest(experienceEvent)

        XCTAssertEqual(1, primaryQueue.count())
        try assertDeviceAttributesResponse(for: request, status: "failed", reason: "queueUnavailable")
    }

    func testDeviceAttributesMissingQueueProducesCorrelatedFailure() throws {
        edge.state = nil
        let request = makeRequest()
        mockRuntime.simulateComingEvents(request)
        try assertDeviceAttributesResponse(for: request, status: "failed", reason: "queueUnavailable")
    }

    func testDeviceAttributesFailedEnqueueProducesCorrelatedFailure() throws {
        simulateConfigAndIdentity()
        let primary = try XCTUnwrap(edge.state?.hitQueue)
        let rejectingQueue = RejectingHitQueue()
        edge.state = EdgeState(hitQueue: primary, deviceAttributesHitQueue: rejectingQueue, edgeProperties: EdgeProperties())
        let request = makeRequest()
        mockRuntime.simulateComingEvents(request)
        XCTAssertEqual(1, rejectingQueue.enqueueAttempts)
        try assertDeviceAttributesResponse(for: request, status: "failed", reason: "queueUnavailable")
    }

    func testOrdinaryFailedEnqueueDoesNotProduceDeviceAttributesResponse() throws {
        simulateConfigAndIdentity()
        let deviceAttributesQueue = try XCTUnwrap(edge.state?.deviceAttributesHitQueue)
        let rejectingQueue = RejectingHitQueue()
        edge.state = EdgeState(hitQueue: rejectingQueue, deviceAttributesHitQueue: deviceAttributesQueue, edgeProperties: EdgeProperties())
        mockRuntime.simulateComingEvents(experienceEvent)
        XCTAssertEqual(1, rejectingQueue.enqueueAttempts)
        XCTAssertTrue(deviceAttributesResponses().isEmpty)
    }

    func testDeviceAttributesEmptyPayloadProducesCorrelatedDrop() throws {
        simulateConfigAndIdentity()
        for data in [nil, [:]] as [[String: Any]?] {
            mockRuntime.resetDispatchedEventAndCreatedSharedStates()
            let request = makeRequest(data: data)
            mockRuntime.simulateComingEvents(request)
            try assertDeviceAttributesResponse(for: request, status: "dropped", reason: "invalidPayload")
        }
    }

    func testDeviceAttributesMissingConfigurationProducesCorrelatedDrop() throws {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Identity.STATE_OWNER_NAME, data: ([:], .set))
        let configurations: [[String: Any]] = [[:], [EdgeConstants.SharedState.Configuration.CONFIG_ID: ""]]
        for config in configurations {
            mockRuntime.resetDispatchedEventAndCreatedSharedStates()
            mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME, data: (config, .set))
            let request = makeRequest()
            mockRuntime.simulateComingEvents(request)
            try assertDeviceAttributesResponse(for: request, status: "dropped", reason: "missingConfig")
        }
    }

    func testDeviceAttributesMissingIdentityProducesCorrelatedDrop() throws {
        mockRuntime.simulateSharedState(for: EdgeConstants.SharedState.Configuration.STATE_OWNER_NAME,
                                        data: ([EdgeConstants.SharedState.Configuration.CONFIG_ID: "config"], .set))
        let request = makeRequest()
        mockRuntime.simulateComingEvents(request)
        try assertDeviceAttributesResponse(for: request, status: "dropped", reason: "invalidPayload")
    }

    func testDeviceAttributesUnencodablePayloadProducesCorrelatedDrop() throws {
        simulateConfigAndIdentity()
        let request = makeRequest(data: ["invalid": Double.nan])
        mockRuntime.simulateComingEvents(request)
        try assertDeviceAttributesResponse(for: request, status: "dropped", reason: "invalidPayload")
    }

    // MARK: Decode failure

    func testDecodeFailure_producesUnchainedDropOnlyForDeviceAttributesQueue() throws {
        let primaryProcessor = try XCTUnwrap(Edge(runtime: mockRuntime).state?.hitQueue.processor)
        let deviceAttributesQueue = try XCTUnwrap(edge.setupDeviceAttributesHitQueue(dataQueueService: DeviceAttributesDataQueueService(deviceAttributesQueue: MockDataQueue())))
        let corruptedData: [Data?] = [nil, Data("{".utf8), Data("{}".utf8)]
        var requestIds: [String] = []

        for data in corruptedData {
            let ordinary = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: data)
            primaryProcessor.processHit(entity: ordinary) { finished in XCTAssertTrue(finished) }
            let deviceAttributesEntity = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: data)
            requestIds.append(deviceAttributesEntity.uniqueIdentifier)
            deviceAttributesQueue.processor.processHit(entity: deviceAttributesEntity) { finished in XCTAssertTrue(finished) }
        }

        let results = deviceAttributesResponses()
        XCTAssertEqual(corruptedData.count, results.count)
        XCTAssertEqual(results.count, mockRuntime.dispatchedEvents.count)
        for (result, requestId) in zip(results, requestIds) {
            XCTAssertNil(result.parentID)
            XCTAssertNil(result.responseID)
            XCTAssertEqual(["status": "dropped", "reason": "invalidPayload", "requestEventId": requestId] as NSDictionary,
                           result.data as NSDictionary?)
        }
    }

    // MARK: Device attributes response handles

    func testDeviceAttributesHit_responseDoesNotUpdateEdgeLocationHintOrStore() throws {
        let identity: [String: Any] = ["identityMap": ["ECID": [["id": "ecid", "authenticatedState": "ambiguous", "primary": false]]]]
        simulateConfigAndIdentity(identity: identity)
        let state = try XCTUnwrap(edge.state)
        state.setLocationHint(hint: "va6", ttlSeconds: 1800, createSharedState: { _, _ in })
        XCTAssertEqual("va6", state.getLocationHint())
        let edgeStore = StoreResponsePayloadManager(EdgeConstants.DataStoreKeys.STORE_NAME)
        edgeStore.saveStorePayloads([StoreResponsePayload(payload: StorePayload(key: "kndctr_cookie", value: "edge-value", maxAge: 1800))])

        let responseBody = #"""
        {"requestId": "id", "handle": [
          {"type": "locationHint:result", "payload": [{"scope": "EdgeNetwork", "hint": "or2", "ttlSeconds": 1800}]},
          {"type": "state:store", "payload": [{"key": "kndctr_new", "value": "new-value", "maxAge": 1800}]}
        ]}
        """#
        let url = URL(string: "https://edge.adobedc.net/ee/v1/mobile/device-attributes")!
        let networking = RecordingNetworking(response: HttpConnection(data: responseBody.data(using: .utf8),
                                                                      response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil),
                                                                      error: nil))
        let previousNetworkService = ServiceProvider.shared.networkService
        ServiceProvider.shared.networkService = networking
        defer { ServiceProvider.shared.networkService = previousNetworkService }

        let queue = try XCTUnwrap(edge.setupDeviceAttributesHitQueue(dataQueueService: DeviceAttributesDataQueueService(deviceAttributesQueue: MockDataQueue())))
        let request = makeRequest()
        let edgeEntity = EdgeDataEntity(event: request,
                                        configuration: AnyCodable.from(dictionary: [EdgeConstants.SharedState.Configuration.CONFIG_ID: "config"]) ?? [:],
                                        identityMap: AnyCodable.from(dictionary: identity) ?? [:])
        let entity = DataEntity(uniqueIdentifier: request.id.uuidString, timestamp: Date(), data: try JSONEncoder().encode(edgeEntity))
        let sharedStateCount = mockRuntime.createdSharedStates.count
        var finished: Bool?
        queue.processor.processHit(entity: entity) { finished = $0 }
        XCTAssertEqual(true, finished)

        // The request still uses the current Edge location hint
        XCTAssertEqual("/ee/va6/v1/mobile/device-attributes", try XCTUnwrap(networking.requests.first).url.path)

        // The response handles change neither the Edge location hint nor the Edge store
        XCTAssertEqual("va6", state.getLocationHint())
        XCTAssertEqual(["kndctr_cookie"], edgeStore.getActivePayloadList().map { $0.key })
        XCTAssertEqual("edge-value", edgeStore.getActivePayloadList().first?.value)
        XCTAssertEqual(sharedStateCount, mockRuntime.createdSharedStates.count)
        let results = deviceAttributesResponses()
        XCTAssertEqual(1, results.count)
        XCTAssertEqual(request.id, results.first?.parentID)
        XCTAssertEqual(["status": "success", "httpStatus": 200] as NSDictionary, results.first?.data as NSDictionary?)
        XCTAssertEqual(results.count, mockRuntime.dispatchedEvents.count)
    }

    // MARK: Response event contract

    func testDeviceAttributesResponsesRetainRequestCorrelation() {
        typealias Status = EdgeConstants.DeviceAttributes.Status
        let request = makeRequest()
        let listener = EventListenerContainer(listener: { _ in }, type: EdgeConstants.DeviceAttributes.EVENT_TYPE,
                                              source: EventSource.responseContent, triggerEventId: nil, timeoutTask: nil)
        for (status, expectedStatus) in [(Status.SUCCESS, "success"), (Status.FAILED, "failed"), (Status.DROPPED, "dropped")] {
            let result = request.createDeviceAttributesResponse(status: status)
            XCTAssertTrue(listener.shouldNotify(result))
            XCTAssertEqual("Device Attributes Response", result.name)
            XCTAssertEqual("com.adobe.eventType.edgeBypassConsent", result.type)
            XCTAssertEqual("com.adobe.eventSource.responseContent", result.source)
            XCTAssertEqual(request.id, result.parentID)
            XCTAssertNil(result.responseID)
            XCTAssertEqual(["status": expectedStatus] as NSDictionary, result.data as NSDictionary?)
        }
        let result = request.createDeviceAttributesResponse(status: Status.FAILED, reason: EdgeConstants.DeviceAttributes.Reason.NETWORK, httpStatus: 404)
        XCTAssertEqual(["status": "failed", "reason": "network", "httpStatus": 404] as NSDictionary, result.data as NSDictionary?)
    }

    func testDeviceAttributesResponseConstantsPreserveWireValues() {
        typealias Keys = EdgeConstants.DeviceAttributes.EventDataKeys
        typealias Status = EdgeConstants.DeviceAttributes.Status
        typealias Reason = EdgeConstants.DeviceAttributes.Reason

        XCTAssertEqual("com.adobe.eventType.edgeBypassConsent", EdgeConstants.DeviceAttributes.EVENT_TYPE)
        XCTAssertEqual(["status", "reason", "httpStatus", "requestEventId"],
                       [Keys.STATUS, Keys.REASON, Keys.HTTP_STATUS, Keys.REQUEST_EVENT_ID])
        XCTAssertEqual(["success", "failed", "dropped"], [Status.SUCCESS, Status.FAILED, Status.DROPPED])
        XCTAssertEqual(["missingConfig", "invalidPayload", "queueUnavailable", "network", "identityChanged"],
                       [Reason.MISSING_CONFIG, Reason.INVALID_PAYLOAD, Reason.QUEUE_UNAVAILABLE, Reason.NETWORK, Reason.IDENTITY_CHANGED])
        XCTAssertEqual("Device Attributes Response", EdgeConstants.DeviceAttributes.EVENT_NAME_RESPONSE)
    }

    func testDeviceAttributesDecodeDropPreservesUnchainedWireContract() {
        let requestId = UUID().uuidString
        let result = Event.createDeviceAttributesDroppedResponse(requestEventId: requestId)

        XCTAssertEqual("Device Attributes Response", result.name)
        XCTAssertEqual("com.adobe.eventType.edgeBypassConsent", result.type)
        XCTAssertEqual("com.adobe.eventSource.responseContent", result.source)
        XCTAssertNil(result.parentID)
        XCTAssertNil(result.responseID)
        XCTAssertEqual(["status": "dropped", "reason": "invalidPayload", "requestEventId": requestId] as NSDictionary,
                       result.data as NSDictionary?)
    }
}

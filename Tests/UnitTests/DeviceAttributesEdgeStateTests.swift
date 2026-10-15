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
import AEPServices
import AEPTestUtils
import XCTest

class DeviceAttributesEdgeStateTests: XCTestCase {
    private final class RecordingHitQueue: HitQueuing {
        enum Operation: Equatable {
            case beginProcessing
            case suspend
            case clear
            case close
        }

        let processor: HitProcessing = MockHitProcessor()
        private(set) var operations: [Operation] = []
        private var entities: [DataEntity] = []
        var onBeginProcessing: (() -> Void)?

        func queue(entity: DataEntity) -> Bool {
            entities.append(entity)
            return true
        }

        func beginProcessing() {
            operations.append(.beginProcessing)
            onBeginProcessing?()
        }
        func suspend() { operations.append(.suspend) }
        func clear() {
            operations.append(.clear)
            entities.removeAll()
        }
        func count() -> Int { return entities.count }
        func close() { operations.append(.close) }
    }

    private let bootEvent = Event(name: "Experience event", type: EventType.edge, source: EventSource.requestContent, data: nil)

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
    }

    func testInit_doesNotStartDeviceAttributesQueue() {
        let primaryQueue = RecordingHitQueue()
        let deviceAttributesQueue = RecordingHitQueue()

        let state = EdgeState(hitQueue: primaryQueue, deviceAttributesHitQueue: deviceAttributesQueue, edgeProperties: EdgeProperties())

        XCTAssertEqual(.pending, state.currentCollectConsent)
        XCTAssertEqual([.suspend], primaryQueue.operations)
        XCTAssertEqual([], deviceAttributesQueue.operations)
    }

    func testBootup_startsDeviceAttributesQueueOnceAfterImplementationDetailsAndPropertiesAreLoaded() {
        let deviceAttributesQueue = RecordingHitQueue()
        let state = EdgeState(hitQueue: RecordingHitQueue(), deviceAttributesHitQueue: deviceAttributesQueue, edgeProperties: EdgeProperties())
        var implementationDetailsAtStart: [String: Any]?
        var sharedStateCreatedAtStart = false
        var sharedStateCreated = false
        deviceAttributesQueue.onBeginProcessing = {
            implementationDetailsAtStart = state.implementationDetails
            sharedStateCreatedAtStart = sharedStateCreated
        }
        let hubState: [String: Any] = ["wrapper": ["type": "N"], "version": "5.0.0"]

        for _ in 0..<2 {
            state.bootupIfNeeded(event: bootEvent,
                                 getSharedState: { name, _, _ in
                                     name == EdgeConstants.SharedState.Hub.SHARED_OWNER_NAME ? SharedStateResult(status: .set, value: hubState) : nil
                                 },
                                 createSharedState: { _, _ in sharedStateCreated = true })
        }

        XCTAssertTrue(state.hasBooted)
        XCTAssertEqual([.beginProcessing], deviceAttributesQueue.operations)
        XCTAssertNotNil(implementationDetailsAtStart)
        XCTAssertTrue(sharedStateCreatedAtStart)
    }

    func testCollectConsentChanges_doNotAffectDeviceAttributesQueue() {
        let primaryQueue = RecordingHitQueue()
        let deviceAttributesQueue = RecordingHitQueue()
        let state = EdgeState(hitQueue: primaryQueue, deviceAttributesHitQueue: deviceAttributesQueue, edgeProperties: EdgeProperties())
        state.bootupIfNeeded(event: bootEvent, getSharedState: { _, _, _ in nil }, createSharedState: { _, _ in })
        let entity = DataEntity(uniqueIdentifier: UUID().uuidString, timestamp: Date(), data: Data())
        XCTAssertTrue(deviceAttributesQueue.queue(entity: entity))

        for status in [ConsentStatus.pending, .no, .yes] {
            state.updateCurrentConsent(status: status)
        }

        XCTAssertEqual(.yes, state.currentCollectConsent)
        XCTAssertEqual([.beginProcessing], deviceAttributesQueue.operations)
        XCTAssertEqual(1, deviceAttributesQueue.count())
        XCTAssertTrue(primaryQueue.operations.contains(.clear))
    }

    func testMissingDeviceAttributesQueue_doesNotChangePrimaryConsentLifecycle() {
        let primaryQueue = RecordingHitQueue()
        let state = EdgeState(hitQueue: primaryQueue, deviceAttributesHitQueue: nil, edgeProperties: EdgeProperties())

        state.updateCurrentConsent(status: .yes)
        state.updateCurrentConsent(status: .pending)
        state.updateCurrentConsent(status: .no)

        XCTAssertNil(state.deviceAttributesHitQueue)
        XCTAssertEqual(.no, state.currentCollectConsent)
        XCTAssertEqual([.suspend, .beginProcessing, .suspend, .clear, .beginProcessing], primaryQueue.operations)
    }
}

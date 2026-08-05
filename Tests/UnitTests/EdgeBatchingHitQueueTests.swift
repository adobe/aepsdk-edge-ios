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

/// Tests for `EdgeBatchingHitQueue` — window-size selection based on the `edge.batching.enabled`
/// flag snapshotted on the head entity, and queue peek/remove behavior driven by `BatchOutcome`.
class EdgeBatchingHitQueueTests: XCTestCase {
    private var mockDataQueue: MockDataQueue!
    private var mockProcessor: MockBatchProcessor!
    private var hitQueue: EdgeBatchingHitQueue!

    override func setUp() {
        mockDataQueue = MockDataQueue()
        mockProcessor = MockBatchProcessor(networkService: EdgeNetworkService(),
                                           networkResponseHandler: NetworkResponseHandler(updateLocationHint: { (_: String?, _: TimeInterval?) -> Void in }),
                                           sharedStateReader: SharedStateReader(getSharedState: { _, _, _ in nil }),
                                           readyForEvent: { _ in true },
                                           getImplementationDetails: { nil },
                                           getLocationHint: { nil })
        hitQueue = EdgeBatchingHitQueue(dataQueue: mockDataQueue, processor: mockProcessor)
    }

    override func tearDown() {
        hitQueue.close()
    }

    // MARK: - Effective batch-size selection

    func testEffectiveBatchSize_batchingDisabled_processesOneAtATime() {
        for entity in buildEntities(count: 3, batchingEnabled: false) {
            _ = mockDataQueue.add(dataEntity: entity)
        }
        mockProcessor.outcomeProvider = { entities in .done(resolvedCount: entities.count) }

        hitQueue.beginProcessing()
        waitUntilQueueEmpty()

        XCTAssertEqual(3, mockProcessor.processBatchCalls.count)
        for call in mockProcessor.processBatchCalls {
            XCTAssertEqual(1, call.count)
        }
        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testEffectiveBatchSize_batchingEnabled_peeksFullDepth() {
        for entity in buildEntities(count: 5, batchingEnabled: true) {
            _ = mockDataQueue.add(dataEntity: entity)
        }
        mockProcessor.outcomeProvider = { entities in .done(resolvedCount: entities.count) }

        hitQueue.beginProcessing()
        waitUntilQueueEmpty()

        XCTAssertEqual(1, mockProcessor.processBatchCalls.count)
        XCTAssertEqual(5, mockProcessor.processBatchCalls[0].count)
    }

    func testEffectiveBatchSize_batchingEnabled_queueLargerThanMax_capsAtMax() {
        let total = EdgeConstants.Defaults.MAX_BATCH_SIZE + 3
        for entity in buildEntities(count: total, batchingEnabled: true) {
            _ = mockDataQueue.add(dataEntity: entity)
        }
        mockProcessor.outcomeProvider = { entities in .done(resolvedCount: entities.count) }

        hitQueue.beginProcessing()
        waitUntilQueueEmpty()

        XCTAssertEqual(2, mockProcessor.processBatchCalls.count)
        XCTAssertEqual(EdgeConstants.Defaults.MAX_BATCH_SIZE, mockProcessor.processBatchCalls[0].count)
        XCTAssertEqual(3, mockProcessor.processBatchCalls[1].count)
    }

    // MARK: - BatchOutcome-driven queue advancement

    /// Regression guard for the event-loss bug: when `processBatch` resolves fewer entities than the
    /// peeked window (truncation), the queue must remove only the resolved prefix, leaving the rest to
    /// be re-peeked (and genuinely processed) on the next cycle — not silently dropped.
    func testDoneOutcome_truncatedResolvedCount_removesOnlyResolvedPrefix_thenReprocessesRemainder() {
        for entity in buildEntities(count: 3, batchingEnabled: true) {
            _ = mockDataQueue.add(dataEntity: entity)
        }

        var callCount = 0
        mockProcessor.outcomeProvider = { entities in
            callCount += 1
            if callCount == 1 {
                // Simulate truncation: only the first of the 3 peeked entities was actually resolved.
                return .done(resolvedCount: 1)
            }
            return .done(resolvedCount: entities.count)
        }

        hitQueue.beginProcessing()
        waitUntilQueueEmpty()

        XCTAssertEqual(2, mockProcessor.processBatchCalls.count)
        // First cycle peeked the full window of 3, even though only 1 was resolved.
        XCTAssertEqual(3, mockProcessor.processBatchCalls[0].count)
        // Second cycle re-peeked exactly the 2 entities left behind — proving they were not lost.
        XCTAssertEqual(2, mockProcessor.processBatchCalls[1].count)
        XCTAssertEqual(0, mockDataQueue.count())
    }

    func testRetryBatchOutcome_doesNotRemoveEntities() {
        for entity in buildEntities(count: 1, batchingEnabled: false) {
            _ = mockDataQueue.add(dataEntity: entity)
        }
        mockProcessor.outcomeProvider = { _ in .retryBatch(retryInterval: 30) }

        let expectation = XCTestExpectation(description: "processBatch invoked at least once")
        mockProcessor.onEachCall = { expectation.fulfill() }

        hitQueue.beginProcessing()
        wait(for: [expectation], timeout: 2)

        // Nothing removed — entity stays for retry.
        XCTAssertEqual(1, mockDataQueue.count())
    }

    func testPartialRemoveOutcome_removesResolvedHeadCount_thenReprocessesRemainder() {
        for entity in buildEntities(count: 3, batchingEnabled: true) {
            _ = mockDataQueue.add(dataEntity: entity)
        }

        var callCount = 0
        mockProcessor.outcomeProvider = { entities in
            callCount += 1
            if callCount == 1 {
                return .partialRemove(resolvedHeadCount: 2, retryInterval: 0.05)
            }
            return .done(resolvedCount: entities.count)
        }

        hitQueue.beginProcessing()
        waitUntilQueueEmpty()

        XCTAssertEqual(2, mockProcessor.processBatchCalls.count)
        XCTAssertEqual(3, mockProcessor.processBatchCalls[0].count)
        XCTAssertEqual(1, mockProcessor.processBatchCalls[1].count)
        XCTAssertEqual(0, mockDataQueue.count())
    }

    // MARK: - Suspend

    func testSuspend_stopsProcessing() {
        hitQueue.suspend()
        for entity in buildEntities(count: 1, batchingEnabled: false) {
            hitQueue.queue(entity: entity)
        }

        let expectation = XCTestExpectation(description: "Wait to confirm no processing occurs")
        mockProcessor.onEachCall = { XCTFail("processBatch should not be called while suspended") }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { expectation.fulfill() }
        wait(for: [expectation], timeout: 1)

        XCTAssertEqual(0, mockProcessor.processBatchCalls.count)
    }

    // MARK: - Helpers

    /// Polls `mockDataQueue.count()` until it reaches 0, tolerating the fact that `EdgeBatchingHitQueue`
    /// performs its `remove(n:)` calls asynchronously on its own internal serial queue (so a synchronous
    /// check immediately after a `processBatch` completion can race ahead of the actual removal).
    private func waitUntilQueueEmpty(timeout: TimeInterval = 2, file: StaticString = #file, line: UInt = #line) {
        let predicate = NSPredicate { _, _ in self.mockDataQueue.count() == 0 }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: NSNull())
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(.completed, result, "Timed out waiting for the queue to drain", file: file, line: line)
    }

    private func buildEntities(count: Int, batchingEnabled: Bool) -> [DataEntity] {
        var entities: [DataEntity] = []
        for i in 0..<count {
            let xdmData: [String: Any] = ["test": "data"]
            let eventData: [String: Any] = ["xdm": xdmData]
            let event = Event(name: "test-event-\(i)", type: EventType.edge, source: EventSource.requestContent, data: eventData)
            let configuration: [String: Any] = [
                "edge.configId": "test-config-id",
                EdgeConstants.SharedState.Configuration.EDGE_BATCHING_ENABLED: batchingEnabled
            ]
            let edgeEntity = EdgeDataEntity(event: event,
                                            configuration: AnyCodable.from(dictionary: configuration) ?? [:],
                                            identityMap: [:])
            let data = try? JSONEncoder().encode(edgeEntity)
            entities.append(DataEntity(uniqueIdentifier: "uuid-\(i)", timestamp: Date(), data: data))
        }
        return entities
    }
}

/// Test double for `EdgeHitProcessor` that overrides `processBatch` to return a configurable
/// `BatchOutcome` instead of performing real network I/O, mirroring Android's Mockito-mocked processor.
class MockBatchProcessor: EdgeHitProcessor {
    var processBatchCalls: [[DataEntity]] = []
    var outcomeProvider: ([DataEntity]) -> BatchOutcome = { .done(resolvedCount: $0.count) }
    var onEachCall: (() -> Void)?

    override func processBatch(entities: [DataEntity], completion: @escaping (BatchOutcome) -> Void) {
        processBatchCalls.append(entities)
        completion(outcomeProvider(entities))
        onEachCall?()
    }
}

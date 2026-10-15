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

@testable import AEPEdge
import AEPServices
import AEPTestUtils
import XCTest

class BypassConsentHitQueueTests: XCTestCase {
    private var dataQueue: ControlledBypassDataQueue!
    private var processor: DeferredBypassProcessor!
    private var hitQueue: HitQueuing!

    override func setUp() {
        dataQueue = ControlledBypassDataQueue()
        processor = DeferredBypassProcessor()
        hitQueue = BypassConsentHitQueue(dataQueue: dataQueue, processor: processor)
    }

    override func tearDown() {
        hitQueue.close()
        processor.onProcess = nil
        processor.onRetry = nil
    }

    func testTerminalCompletionAdvancesToNextHit() {
        let processed = expectation(description: "Both hits are processed")
        processed.expectedFulfillmentCount = 2
        processed.assertForOverFulfill = true
        processor.onProcess = { entity in
            self.processor.complete(entity.uniqueIdentifier, finished: true)
            processed.fulfill()
        }
        XCTAssertTrue(hitQueue.queue(entity: entity("first")))
        XCTAssertTrue(hitQueue.queue(entity: entity("second")))
        hitQueue.beginProcessing()
        wait(for: [processed], timeout: 2)
        waitUntilEmpty()
        XCTAssertEqual(["first", "second"], processor.processedIds.shallowCopy)
    }

    func testRetryRetainsHeadUntilLaterTerminalCompletion() {
        let retried = expectation(description: "Head retries before next hit")
        retried.expectedFulfillmentCount = 3
        processor.onProcess = { entity in
            let retry = self.processor.processedIds.count == 1
            self.processor.complete(entity.uniqueIdentifier, finished: !retry)
            retried.fulfill()
        }
        hitQueue.queue(entity: entity("first"))
        hitQueue.queue(entity: entity("second"))
        hitQueue.beginProcessing()
        wait(for: [retried], timeout: 2)
        waitUntilEmpty()
        XCTAssertEqual(["first", "first", "second"], processor.processedIds.shallowCopy)
    }

    func testResetDuringInFlightRequestDoesNotRemoveNewHead() {
        let started = expectation(description: "Old identity request is in flight")
        let newStarted = expectation(description: "New identity request must actually be processed")
        processor.onProcess = { entity in
            if entity.uniqueIdentifier == "old" {
                started.fulfill()
            } else {
                newStarted.fulfill()
                self.processor.complete(entity.uniqueIdentifier, finished: true)
            }
        }
        hitQueue.queue(entity: entity("old"))
        hitQueue.beginProcessing()
        wait(for: [started], timeout: 2)
        hitQueue.clear()
        XCTAssertEqual(0, hitQueue.count())
        hitQueue.queue(entity: entity("new"))
        processor.complete("old", finished: true)
        wait(for: [newStarted], timeout: 2)
        waitUntilEmpty()
        XCTAssertEqual(["old", "new"], processor.processedIds.shallowCopy)
    }

    func testResetDuringInFlightRetryDoesNotDelayNewHead() {
        let started = expectation(description: "Old identity request is in flight")
        let newStarted = expectation(description: "New request does not inherit old retry delay")
        processor.retryDelay = 60
        processor.onProcess = { entity in
            if entity.uniqueIdentifier == "old" {
                started.fulfill()
            } else {
                newStarted.fulfill()
                self.processor.complete(entity.uniqueIdentifier, finished: true)
            }
        }
        hitQueue.queue(entity: entity("old"))
        hitQueue.beginProcessing()
        wait(for: [started], timeout: 2)
        hitQueue.clear()
        hitQueue.queue(entity: entity("new"))
        processor.complete("old", finished: false)
        wait(for: [newStarted], timeout: 2)
        waitUntilEmpty()
    }

    func testResetWhileWaitingToRetryCancelsOldDelay() {
        let retryScheduled = expectation(description: "Old request enters retry wait")
        let newStarted = expectation(description: "New identity request starts without old delay")
        processor.retryDelay = 60
        processor.onRetry = { retryScheduled.fulfill() }
        processor.onProcess = { entity in
            if entity.uniqueIdentifier == "old" {
                self.processor.complete("old", finished: false)
            } else {
                newStarted.fulfill()
                self.processor.complete(entity.uniqueIdentifier, finished: true)
            }
        }
        hitQueue.queue(entity: entity("old"))
        hitQueue.beginProcessing()
        wait(for: [retryScheduled], timeout: 2)
        hitQueue.clear()
        hitQueue.queue(entity: entity("new"))
        wait(for: [newStarted], timeout: 2)
        waitUntilEmpty()
    }

    func testResetWithEmptyQueueAllowsLaterRequests() {
        let started = expectation(description: "Old request starts")
        processor.onProcess = { _ in started.fulfill() }
        hitQueue.queue(entity: entity("old"))
        hitQueue.beginProcessing()
        wait(for: [started], timeout: 2)
        hitQueue.suspend()
        hitQueue.clear()
        processor.complete("old", finished: true)
        let newStarted = expectation(description: "Queue remains usable after reset")
        processor.onProcess = { entity in
            newStarted.fulfill()
            self.processor.complete(entity.uniqueIdentifier, finished: true)
        }
        hitQueue.queue(entity: entity("new"))
        hitQueue.beginProcessing()
        wait(for: [newStarted], timeout: 2)
        waitUntilEmpty()
    }

    func testDuplicateCompletionDoesNotRemoveNextHit() {
        let oldStarted = expectation(description: "First request starts")
        let newStarted = expectation(description: "Second request starts")
        processor.onProcess = { entity in
            (entity.uniqueIdentifier == "first" ? oldStarted : newStarted).fulfill()
        }
        hitQueue.queue(entity: entity("first"))
        hitQueue.queue(entity: entity("second"))
        hitQueue.beginProcessing()
        wait(for: [oldStarted], timeout: 2)
        processor.complete("first", finished: true)
        processor.complete("first", finished: true)
        wait(for: [newStarted], timeout: 2)
        XCTAssertEqual(1, hitQueue.count())
        processor.complete("second", finished: true)
        waitUntilEmpty()
    }

    func testSuspendStopsNextHitUntilResumed() {
        let started = expectation(description: "First hit starts")
        let next = expectation(description: "Next hit starts after resume")
        processor.onProcess = { entity in
            (entity.uniqueIdentifier == "first" ? started : next).fulfill()
        }
        hitQueue.queue(entity: entity("first"))
        hitQueue.queue(entity: entity("second"))
        hitQueue.beginProcessing()
        wait(for: [started], timeout: 2)
        hitQueue.suspend()
        processor.complete("first", finished: true)
        let removed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in self.hitQueue.count() == 1 }, object: nil)
        wait(for: [removed], timeout: 2)
        XCTAssertEqual(["first"], processor.processedIds.shallowCopy)
        hitQueue.beginProcessing()
        wait(for: [next], timeout: 2)
        processor.complete("second", finished: true)
        waitUntilEmpty()
    }

    func testPersistenceRemovalFailurePausesUntilExplicitResume() {
        let failedRemoval = expectation(description: "Persistence deletion fails")
        dataQueue.removeSucceeds = false
        dataQueue.onRemove = { failedRemoval.fulfill() }
        processor.onProcess = { entity in self.processor.complete(entity.uniqueIdentifier, finished: true) }
        hitQueue.queue(entity: entity("first"))
        hitQueue.beginProcessing()
        wait(for: [failedRemoval], timeout: 2)
        XCTAssertEqual(1, hitQueue.count())
        dataQueue.onRemove = nil
        dataQueue.removeSucceeds = true
        hitQueue.beginProcessing()
        waitUntilEmpty()
        XCTAssertEqual(["first", "first"], processor.processedIds.shallowCopy)
    }

    func testFailedClearPausesPendingOldIdentityHits() {
        let started = expectation(description: "First hit starts")
        processor.onProcess = { _ in started.fulfill() }
        hitQueue.queue(entity: entity("first"))
        hitQueue.queue(entity: entity("old-pending"))
        hitQueue.beginProcessing()
        wait(for: [started], timeout: 2)
        dataQueue.clearSucceeds = false
        hitQueue.clear()
        processor.complete("first", finished: true)
        let removed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in self.hitQueue.count() == 1 }, object: nil)
        wait(for: [removed], timeout: 2)
        XCTAssertEqual(["first"], processor.processedIds.shallowCopy)
    }

    func testClosedQueueRejectsNewHitsAndLateCompletion() {
        let started = expectation(description: "Request starts")
        processor.onProcess = { _ in started.fulfill() }
        hitQueue.queue(entity: entity("first"))
        hitQueue.beginProcessing()
        wait(for: [started], timeout: 2)
        hitQueue.close()
        processor.complete("first", finished: true)
        XCTAssertFalse(hitQueue.queue(entity: entity("new")))
        XCTAssertEqual(["first"], processor.processedIds.shallowCopy)
    }

    private func entity(_ id: String) -> DataEntity {
        DataEntity(uniqueIdentifier: id, timestamp: Date(), data: Data("{}".utf8))
    }

    private func waitUntilEmpty() {
        let empty = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in self.hitQueue.count() == 0 }, object: nil)
        wait(for: [empty], timeout: 2)
    }
}

private class DeferredBypassProcessor: HitProcessing {
    let processedIds = ThreadSafeArray<String>()
    private let completions = ThreadSafeDictionary<String, (Bool) -> Void>()
    var onProcess: ((DataEntity) -> Void)?
    var onRetry: (() -> Void)?
    var retryDelay: TimeInterval = 0

    func retryInterval(for entity: DataEntity) -> TimeInterval {
        onRetry?()
        return retryDelay
    }

    func processHit(entity: DataEntity, completion: @escaping (Bool) -> Void) {
        processedIds.append(entity.uniqueIdentifier)
        completions[entity.uniqueIdentifier] = completion
        onProcess?(entity)
    }

    func complete(_ id: String, finished: Bool) {
        guard let completion = completions[id] else {
            XCTFail("No pending completion for \(id)")
            return
        }
        completion(finished)
    }
}

private class ControlledBypassDataQueue: DataQueue {
    private let storage = MockDataQueue()
    var removeSucceeds = true
    var clearSucceeds = true
    var onRemove: (() -> Void)?

    func add(dataEntity: DataEntity) -> Bool { storage.add(dataEntity: dataEntity) }
    func peek() -> DataEntity? { storage.peek() }
    func peek(n count: Int) -> [DataEntity]? { storage.peek(n: count) }
    func remove() -> Bool {
        let removed = removeSucceeds && storage.remove()
        onRemove?()
        return removed
    }
    func remove(n count: Int) -> Bool { removeSucceeds && storage.remove(n: count) }
    func clear() -> Bool { clearSucceeds && storage.clear() }
    func count() -> Int { storage.count() }
    func close() { storage.close() }
}

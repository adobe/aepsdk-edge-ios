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

import AEPServices
import Foundation

/// Batch-capable hit queue for the Edge extension. Uses the same `DataQueue` persistence and serial
/// `DispatchQueue` pattern as `PersistentHitQueue`, but processes a window of entities per cycle when
/// batching is enabled (`edge.batching.enabled = true`), mirroring `aepsdk-edge-android`'s
/// `EdgeBatchingHitQueue`.
///
/// The effective batch size is determined at processing time from the head entity's snapshotted
/// configuration:
/// - batching disabled (default) -> window of 1, identical to `PersistentHitQueue`'s behavior.
/// - batching enabled -> window of `min(queue.count(), MAX_BATCH_SIZE)`.
class EdgeBatchingHitQueue: HitQueuing {
    private let SELF_TAG = "EdgeBatchingHitQueue"
    let processor: HitProcessing
    private let edgeHitProcessor: EdgeHitProcessor
    private let dataQueue: DataQueue

    private var suspended = true
    private var isTaskScheduled = false
    private let queue = DispatchQueue(label: "com.adobe.edge.batchingHitQueue")

    init(dataQueue: DataQueue, processor: EdgeHitProcessor) {
        self.dataQueue = dataQueue
        self.edgeHitProcessor = processor
        self.processor = processor
    }

    @discardableResult
    func queue(entity: DataEntity) -> Bool {
        let result = dataQueue.add(dataEntity: entity)
        processNextBatch()
        return result
    }

    func beginProcessing() {
        queue.async { self.suspended = false }
        processNextBatch()
    }

    func suspend() {
        queue.async { self.suspended = true }
    }

    func clear() {
        _ = dataQueue.clear()
    }

    func count() -> Int {
        return dataQueue.count()
    }

    func close() {
        suspend()
        dataQueue.close()
    }

    /// Schedules one batch-processing cycle if none is already running. Mirrors the guard in
    /// `PersistentHitQueue.processNextHit()`.
    private func processNextBatch() {
        queue.async {
            guard !self.suspended, !self.isTaskScheduled else { return }
            guard let head = self.dataQueue.peek() else { return } // nothing left in the queue, stop processing

            let batchSize = self.effectiveBatchSize(for: head)
            let entities: [DataEntity]
            if batchSize > 1, let peeked = self.dataQueue.peek(n: batchSize), !peeked.isEmpty {
                entities = peeked
            } else {
                entities = [head]
            }

            self.isTaskScheduled = true
            self.edgeHitProcessor.processBatch(entities: entities) { [weak self] outcome in
                guard let self = self else { return }
                self.handleOutcome(outcome, batchCount: entities.count)
            }
        }
    }

    private func handleOutcome(_ outcome: BatchOutcome, batchCount: Int) {
        switch outcome {
        case .done(let resolvedCount):
            // Remove only what processBatch actually resolved — it may have been given a larger
            // peeked window than it acted on (truncation at a Consent/Reset/decode-failure boundary,
            // or a single non-ExperienceEvent head processed alone), and anything beyond the resolved
            // prefix was never sent, so it must stay queued for the next cycle.
            queue.async {
                guard resolvedCount > 0 else {
                    self.isTaskScheduled = false
                    self.processNextBatch()
                    return
                }
                if self.dataQueue.remove(n: resolvedCount) {
                    self.isTaskScheduled = false
                    self.processNextBatch()
                } else {
                    Log.warning(label: self.SELF_TAG, "An unexpected error occurred while attempting to delete records from the database. Data processing will be paused.")
                }
            }

        case .retryBatch(let retryInterval):
            Log.trace(label: self.SELF_TAG, "Batch of \(batchCount) will be retried in \(retryInterval) seconds.")
            queue.asyncAfter(deadline: .now() + retryInterval) { [weak self] in
                guard let self = self else { return }
                self.isTaskScheduled = false
                self.processNextBatch()
            }

        case .partialRemove(let resolvedHeadCount, let retryInterval):
            queue.async {
                if resolvedHeadCount > 0 {
                    _ = self.dataQueue.remove(n: resolvedHeadCount)
                }
                if let retryInterval = retryInterval {
                    Log.trace(label: self.SELF_TAG, "Partial removal of \(resolvedHeadCount) entities; next entity needs retry in \(retryInterval) seconds.")
                    self.queue.asyncAfter(deadline: .now() + retryInterval) { [weak self] in
                        guard let self = self else { return }
                        self.isTaskScheduled = false
                        self.processNextBatch()
                    }
                } else {
                    self.isTaskScheduled = false
                    self.processNextBatch()
                }
            }
        }
    }

    /// Returns the number of entities to include in the next batch, based on the `edge.batching.enabled`
    /// flag snapshotted in the head entity's configuration.
    private func effectiveBatchSize(for head: DataEntity) -> Int {
        guard let data = head.data, let edgeEntity = try? JSONDecoder().decode(EdgeDataEntity.self, from: data) else {
            return 1
        }
        guard edgeEntity.batchingEnabled else { return 1 }
        return min(dataQueue.count(), EdgeConstants.Defaults.MAX_BATCH_SIZE)
    }
}

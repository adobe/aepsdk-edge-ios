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
/// `edge.batching` configuration (parsed by `EdgeBatchingConfig`):
/// - batching disabled (default) -> window of 1, identical to `PersistentHitQueue`'s behavior.
/// - batching enabled -> window of `min(queue.count(), maxBatchSize)`, where `maxBatchSize` comes from
///   the head entity's `edge.batching` object (falling back to `MAX_BATCH_SIZE` when absent or
///   non-positive, clamped to `MAX_BATCH_SIZE_LIMIT` regardless of source).
class EdgeBatchingHitQueue: HitQueuing {
    private let SELF_TAG = "EdgeBatchingHitQueue"
    let processor: HitProcessing
    private let edgeHitProcessor: EdgeHitProcessor
    private let dataQueue: DataQueue

    /// Guarded by `state` rather than by running only inside `queue`'s closures: `suspend()` must take
    /// effect immediately, even ahead of a batch cycle that was already enqueued on `queue` (e.g. collect
    /// consent flipping to pending while a cycle from a just-queued event is sitting behind other work).
    /// If `suspended` were only ever mutated from within `queue.async`, its flip would be stuck in the
    /// same FIFO line as the cycle it's meant to stop, arriving too late to matter.
    private struct BatchQueueState {
        var suspended = true
        var isTaskScheduled = false
    }
    private let state = Atomic(BatchQueueState())

    #if DEBUG
    // Not `private`: exposed at module (internal) scope only in DEBUG builds so tests can occupy this
    // queue directly to deterministically exercise the "cycle enqueued but not yet started" race window.
    let queue = DispatchQueue(label: "com.adobe.edge.batchingHitQueue")
    #else
    private let queue = DispatchQueue(label: "com.adobe.edge.batchingHitQueue")
    #endif

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
        state.mutate { $0.suspended = false }
        processNextBatch()
    }

    func suspend() {
        state.mutate { $0.suspended = true }
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
    ///
    /// The `suspended` check happens under `state` rather than merely by virtue of running inside this
    /// `queue.async` closure: since this closure was itself enqueued on `queue` earlier, an intervening
    /// `suspend()` that mutated the flag directly (not via `queue.async`) is visible here as soon as it
    /// happens, instead of being stuck behind this cycle in the same FIFO line. This closes the window
    /// Android's `EdgeBatchingHitQueue.runBatchCycle` guards against: a `suspend()` landing after a cycle
    /// was scheduled but before it started.
    ///
    /// `isTaskScheduled` is only ever mutated from within `queue`'s own closures (this method and
    /// `handleOutcome`'s), so calls to this method never overlap with each other — it is safe to set the
    /// flag true only once an actual batch has been found, right before dispatching it.
    private func processNextBatch() {
        queue.async {
            var canStart = false
            self.state.mutate { canStart = !$0.suspended && !$0.isTaskScheduled }
            guard canStart else { return }

            guard let head = self.dataQueue.peek() else { return } // nothing left in the queue, stop processing

            self.state.mutate { $0.isTaskScheduled = true }

            let batchSize = self.effectiveBatchSize(for: head)
            let entities: [DataEntity]
            if batchSize > 1, let peeked = self.dataQueue.peek(n: batchSize), !peeked.isEmpty {
                entities = peeked
            } else {
                entities = [head]
            }

            self.edgeHitProcessor.processBatch(entities: entities) { [weak self] outcome in
                guard let self = self else { return }
                self.handleOutcome(outcome, batchCount: entities.count)
            }
        }
    }

    private func markTaskFinished() {
        state.mutate { $0.isTaskScheduled = false }
    }

    /// Clears the in-flight flag and immediately tries to schedule the next cycle. Common tail call
    /// shared by every `handleOutcome` branch once its queue mutation (or retry wait) has settled.
    private func finishAndScheduleNext() {
        markTaskFinished()
        processNextBatch()
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
                    self.finishAndScheduleNext()
                    return
                }
                if self.dataQueue.remove(n: resolvedCount) {
                    self.finishAndScheduleNext()
                } else {
                    Log.warning(label: self.SELF_TAG, "An unexpected error occurred while attempting to delete records from the database. Data processing will be paused.")
                }
            }

        case .retryBatch(let retryInterval):
            Log.trace(label: self.SELF_TAG, "Batch of \(batchCount) will be retried in \(retryInterval) seconds.")
            queue.asyncAfter(deadline: .now() + retryInterval) { [weak self] in
                self?.finishAndScheduleNext()
            }

        case .partialRemove(let resolvedHeadCount, let retryInterval):
            queue.async {
                if resolvedHeadCount > 0 {
                    _ = self.dataQueue.remove(n: resolvedHeadCount)
                }
                if let retryInterval = retryInterval {
                    Log.trace(label: self.SELF_TAG, "Partial removal of \(resolvedHeadCount) entities; next entity needs retry in \(retryInterval) seconds.")
                    self.queue.asyncAfter(deadline: .now() + retryInterval) { [weak self] in
                        self?.finishAndScheduleNext()
                    }
                } else {
                    self.finishAndScheduleNext()
                }
            }
        }
    }

    /// Returns the number of entities to include in the next batch, based on the `enabled` flag and
    /// `maxBatchSize` from the `edge.batching` configuration snapshotted in the head entity's
    /// configuration (parsed by `EdgeBatchingConfig`). `maxBatchSize` is already clamped to a positive
    /// value no greater than `EdgeConstants.Defaults.MAX_BATCH_SIZE_LIMIT`, so a misconfigured value
    /// can't grow the batch (and the request payload) unbounded.
    private func effectiveBatchSize(for head: DataEntity) -> Int {
        guard let data = head.data, let edgeEntity = try? JSONDecoder().decode(EdgeDataEntity.self, from: data) else {
            return 1
        }
        let batchingConfig = EdgeBatchingConfig.from(edgeEntity.configuration.asAnyDictionary)
        guard batchingConfig.isEnabled else { return 1 }
        return min(dataQueue.count(), batchingConfig.maxBatchSize)
    }
}

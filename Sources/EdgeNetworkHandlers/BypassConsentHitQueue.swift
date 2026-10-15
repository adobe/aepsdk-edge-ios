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

/// Single-hit persistent queue whose acknowledgments cannot remove hits queued after an identity reset.
class BypassConsentHitQueue: HitQueuing {
    let processor: HitProcessing
    private let dataQueue: DataQueue
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "com.adobe.edge.bypassConsentHitQueue")
    private var suspended = true
    private var closed = false
    private var generation: UInt = 0
    private var activeAttempt: UUID?
    private var retryTask: DispatchWorkItem?

    private struct Attempt {
        let id: UUID
        let generation: UInt
        let entity: DataEntity
    }

    init(dataQueue: DataQueue, processor: HitProcessing) {
        self.dataQueue = dataQueue
        self.processor = processor
    }

    @discardableResult
    func queue(entity: DataEntity) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !closed else {
            Log.error(label: EdgeConstants.LOG_TAG, "Cannot enqueue device attributes on a closed queue.")
            return false
        }
        let added = dataQueue.add(dataEntity: entity)
        processNextHit()
        return added
    }

    func beginProcessing() {
        lock.lock()
        defer { lock.unlock() }
        guard !closed else {
            Log.error(label: EdgeConstants.LOG_TAG, "Cannot start a closed device attributes queue.")
            return
        }
        suspended = false
        processNextHit()
    }

    func suspend() {
        lock.lock()
        defer { lock.unlock() }
        suspended = true
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        guard dataQueue.clear() else {
            Log.error(label: EdgeConstants.LOG_TAG, "Failed to clear device attributes persistence. Processing is paused.")
            suspended = true
            return
        }
        generation &+= 1
        if let retryTask = retryTask {
            retryTask.cancel()
            self.retryTask = nil
            activeAttempt = nil
        }
        processNextHit()
    }

    func count() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return dataQueue.count()
    }

    func close() {
        lock.lock()
        defer { lock.unlock() }
        closed = true
        suspended = true
        generation &+= 1
        retryTask?.cancel()
        retryTask = nil
        activeAttempt = nil
        dataQueue.close()
    }

    private func nextAttempt() -> Attempt? {
        lock.lock()
        defer { lock.unlock() }
        guard !suspended, !closed, activeAttempt == nil, let entity = dataQueue.peek() else { return nil }
        let attempt = Attempt(id: UUID(), generation: generation, entity: entity)
        activeAttempt = attempt.id
        return attempt
    }

    private func processNextHit() {
        queue.async {
            guard let attempt = self.nextAttempt() else { return }
            self.processor.processHit(entity: attempt.entity) { [weak self] finished in
                self?.handleCompletion(finished, for: attempt)
            }
        }
    }

    private func handleCompletion(_ finished: Bool, for attempt: Attempt) {
        queue.async {
            self.lock.lock()
            defer { self.lock.unlock() }
            guard !self.closed else { return }
            guard self.activeAttempt == attempt.id, self.retryTask == nil else {
                Log.warning(label: EdgeConstants.LOG_TAG, "Ignoring duplicate or abandoned device attributes queue completion.")
                return
            }
            // A reset has already removed this hit. Do not remove or delay the new queue head.
            guard self.generation == attempt.generation else {
                self.activeAttempt = nil
                self.processNextHit()
                return
            }

            if finished {
                if self.dataQueue.peek()?.uniqueIdentifier == attempt.entity.uniqueIdentifier,
                   !self.dataQueue.remove() {
                    Log.error(label: EdgeConstants.LOG_TAG, "Failed to remove a device attributes hit from persistence. Processing is paused.")
                    self.suspended = true
                }
                self.activeAttempt = nil
                self.processNextHit()
            } else {
                let task = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    self.lock.lock()
                    defer { self.lock.unlock() }
                    guard self.generation == attempt.generation, self.activeAttempt == attempt.id else { return }
                    self.retryTask = nil
                    self.activeAttempt = nil
                    self.processNextHit()
                }
                self.retryTask = task
                self.queue.asyncAfter(deadline: .now() + self.processor.retryInterval(for: attempt.entity), execute: task)
            }
        }
    }
}

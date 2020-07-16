//
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import Foundation

/// OperationQueue implements a startable/stoppable queue of items and an associated handler function.
///
/// This class maintains it's own internal GCD queueing mechanisms, so all available functions are thread safe.
class OperationQueue<T> {
    /// Used to coordinate processing of item queue.
    private let source: DispatchSourceUserDataOr

    /// Dispatch queue used for all features of this class
    private let queue: DispatchQueue

    /// Handler function used to operate on items.
    private var handler: ((T) -> Bool)?

    /// Array of waiting items, only accessed by `queue` to maintain thread safety.
    private var array: [T] = []

    /// Current state of the queue (started or stopped)
    ///
    /// - Note: When set to active this will automatically trigger `source` to jump-start queue operation
    private var active: Bool = false {
        didSet {
            triggerSourceIfNeeded()
        }
    }

    /// Initializes a new `OperationQueue` with an optional tag.
    ///
    /// - Parameters:
    ///     - tag: Optional string identifier for the internal queue, useful for debugging purposes.
    /// - Returns: A new `OperationQueue` in a stopped state.
    init(_ tag: String = "anonymous") {
        self.queue = DispatchQueue(label: "com.adobe.operationqueue(\(tag))")
        self.source = DispatchSource.makeUserDataOrSource(queue: queue)
        source.setEventHandler(handler: drain)
        source.activate() // Must activate DispatchSource to avoid crashes on deinit.
    }

    /// Adds an item of type `T` to the `queue`.
    ///
    /// - Parameter item: Item of type `T` to add to the queue.
    func add(_ item: T) {
        async {
            self.array.append(item)
            self.triggerSourceIfNeeded()
        }
    }

    /// Schedules a closure on the internal queue, to allow for ordering external operations against the `OperationQueue`
    /// - Parameter closure: closure to schedule on the queue.
    private func async(_ execute: @escaping () -> Void) {
        queue.async(execute: execute)
    }

    /// Sets the item handler function for this `OperationQueue`
    ///
    /// - Parameter handler: Function called for each queued item (in-order).
    /// - Note: If `handler` returns `true`, the handled item is removed from the queue and processing continues.
    ///         If `handler` returns `false`, the handled item is *not* removed from the queue, and processing is paused
    ///         until another item is added or until the `start` function is called.
    func setHandler(_ handler: @escaping (T) -> Bool) {
        async {
            if self.active {
                self.drain()
            }
            self.handler = handler
            self.triggerSourceIfNeeded()
        }
    }

    /// Puts queue in active state.
    func start() {
        async {
            self.active = true
        }
    }

    /// Puts queue in inactive state.
    /// - Note: This is not an immediate stop, already queued items may continue to be handled.
    func stop() {
        async {
            self.active = false
        }
    }

    /// Triggers the DispatchOr source if the queue is currently active.
    /// - Note: Should only be called from internal `queue`.
    private func triggerSourceIfNeeded() {
        if self.active {
            self.source.or(data: 1)
        }
    }

    /// Attempts to drain the queue by iterating over all queued items and calling the handle function on them.
    private func drain() {
        while let item = self.array.first {
            guard let handleFunc = self.handler else { return }
            if handleFunc(item) { // Handler processed item, we can remove.
                self.array.removeFirst()
            } else { // Handler declined to process, bail and wait for another trigger.
                return
            }
        }
    }
}

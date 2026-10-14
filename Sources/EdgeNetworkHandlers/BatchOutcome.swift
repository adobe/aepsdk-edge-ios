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

import Foundation

/// Result returned by `EdgeHitProcessor.processBatch` to tell `EdgeBatchingHitQueue` how to advance
/// the data queue after a batch attempt. Mirrors `aepsdk-edge-android`'s `BatchOutcome`.
enum BatchOutcome {
    /// The first `resolvedCount` entities (from the head) were resolved (delivered, dropped with
    /// error, or ingested). Remove exactly that many from the queue — `processBatch` may have been
    /// given a larger peeked window than it actually resolved (e.g. a window truncated at a
    /// Consent/Reset/decode-failure boundary, or a single non-ExperienceEvent head processed alone);
    /// only the resolved prefix is safe to dequeue. Anything beyond it was never sent and must stay
    /// queued for the next cycle.
    case done(resolvedCount: Int)

    /// A recoverable network error occurred; nothing was ingested.
    /// Leave the entire batch in the queue and retry after `retryInterval`.
    case retryBatch(retryInterval: TimeInterval)

    /// A 400 explosion partially resolved the batch from the head.
    /// Remove the first `resolvedHeadCount` entities; leave the rest for the next cycle.
    /// `retryInterval` is non-nil when the next unresolved entity needs a retry delay before the next cycle.
    case partialRemove(resolvedHeadCount: Int, retryInterval: TimeInterval?)
}

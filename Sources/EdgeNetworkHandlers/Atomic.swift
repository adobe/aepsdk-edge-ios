//
// Copyright 2021 Adobe. All rights reserved.
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

/// Represents a thread-safe type for read and write operations
final class Atomic<A> {
    private let queue = DispatchQueue(label: "com.adobe.atomic.queue")
    private var _value: A

    /// Creates a new `Atomic` type with `value`
    /// - Parameter value: the value for this `Atomic` to hold
    init(_ value: A) {
        self._value = value
    }

    /// The underlying concrete type wrapped by this `Atomic` class
    var value: A {
        return queue.sync { self._value }
    }

    /// Helper function to safely mutate the underlying value
    /// - Parameter transform: a closure that describes how to mutate `value`
    func mutate(_ transform: (inout A) -> Void) {
        queue.sync {
            transform(&self._value)
        }
    }
}

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
import XCTest

/// CountDown latch to be used for asserts and expectations
class CountDownLatch {
    private let initialCount: Int32
    private var count: Int32
    private let waitSemaphore = DispatchSemaphore(value: 0)
    
    init(_ count: Int32) {
        guard count > 0 else {
            assertionFailure("CountDownLatch requires a count greater than 0")
            self.count = 0
            self.initialCount = 0
            return
        }
        
        self.count = count
        self.initialCount = count
    }
    
    func getCurrentCount() -> Int32 {
        return count
    }
    
    func getInitialCount() -> Int32 {
        return initialCount
    }
    
    func await(timeout: TimeInterval = 1) -> DispatchTimeoutResult {
        return waitSemaphore.wait(timeout: (DispatchTime.now() + timeout))
    }
    
    func countDown() {
        OSAtomicDecrement32(&count)
        if count == 0 {
            waitSemaphore.signal()
        }
        
        if count < 0 {
            print("Count Down decreased more times than expected.")
        }
        
    }
}

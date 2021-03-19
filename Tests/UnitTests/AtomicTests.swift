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

@testable import AEPEdge
import Foundation
import XCTest

class AtomicTests: XCTestCase {
    private let queue = DispatchQueue(label: "test queue",
                                      attributes: .concurrent)

    func testAtomicWrite() {
        let atomic = Atomic<Int>(0)
        for _ in 0..<1_000 {
            queue.async {
                atomic.mutate { $0 += 1 }
            }
        }
        queue.sync(flags: .barrier) {}
        XCTAssertEqual(atomic.value, 1_000)
    }
}

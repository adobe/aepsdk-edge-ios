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

func assertEqual(_ expected: [String: Any], _ actual: [String: Any], _ message: String? = nil, file: StaticString = #file, line: UInt = #line) {
    if let unwrappedMessage = message {
        XCTAssertEqual(expected as NSObject, actual as NSObject, unwrappedMessage, file: (file), line: line)
    } else {
        XCTAssertEqual(expected as NSObject, actual as NSObject, file: (file), line: line)
    }
}

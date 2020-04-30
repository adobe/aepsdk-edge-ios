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

import XCTest

@testable import ACPExperiencePlatform

class ExperiencePlatformNetworkServiceTests: XCTestCase {
    
    func testStrings() {
        let testStr : String = "\u{00A9}{\"some\":\"thing\\n\"}\u{00F8}" +
        "\u{00A9}{" +
        "  \"may\": {" +
        "    \"include\": \"nested\"," +
        "    \"objects\": [" +
        "      \"and\"," +
        "      \"arrays\"" +
        "    ]" +
        "  }" +
        "}\u{00F8}";
        let requestConfigRecordSeparator: Character = "\u{00A9}"
        let requestConfigLineFeed: Character = "\u{00F8}"
        // todo
        
    }
}
  

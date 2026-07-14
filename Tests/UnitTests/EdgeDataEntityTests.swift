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

@testable import AEPCore
@testable import AEPEdge
import XCTest

class EdgeDataEntityTests: XCTestCase {
    private let event = Event(name: "test-event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["test": "data"]])

    func testDecode_currentFormat_decodesBatchingEnabledValue() throws {
        let entity = EdgeDataEntity(event: event, configuration: [:], identityMap: [:], batchingEnabled: true)
        let data = try JSONEncoder().encode(entity)
        let decoded = try JSONDecoder().decode(EdgeDataEntity.self, from: data)

        XCTAssertTrue(decoded.batchingEnabled)
    }

    /// Simulates a hit persisted before `batchingEnabled` was introduced: the JSON has no such key.
    /// Decoding must succeed (not throw) and default `batchingEnabled` to `false`.
    func testDecode_oldFormatWithoutBatchingEnabledKey_defaultsToFalse() throws {
        let entity = EdgeDataEntity(event: event, configuration: [:], identityMap: [:], batchingEnabled: true)
        let data = try JSONEncoder().encode(entity)

        guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to parse encoded EdgeDataEntity as a JSON object")
            return
        }
        XCTAssertNotNil(json["batchingEnabled"], "Precondition: current format is expected to include the key before we strip it")
        json.removeValue(forKey: "batchingEnabled")

        let oldFormatData = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(EdgeDataEntity.self, from: oldFormatData)

        XCTAssertFalse(decoded.batchingEnabled)
        XCTAssertEqual(event.id, decoded.event.id)
    }
}

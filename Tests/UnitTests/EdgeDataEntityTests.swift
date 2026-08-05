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
import AEPServices
import XCTest

class EdgeDataEntityTests: XCTestCase {
    private let event = Event(name: "test-event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["test": "data"]])

    func testDecode_roundTrip_preservesEventAndConfiguration() throws {
        let configuration: [String: AnyCodable] = ["edge.configId": AnyCodable("1234")]
        let entity = EdgeDataEntity(event: event, configuration: configuration, identityMap: [:])
        let data = try JSONEncoder().encode(entity)
        let decoded = try JSONDecoder().decode(EdgeDataEntity.self, from: data)

        XCTAssertEqual(event.id, decoded.event.id)
        XCTAssertEqual("1234", decoded.configuration["edge.configId"]?.stringValue)
    }

    /// The batching keys (`edge.batching.enabled`, `edge.batching.eventNameAllowlist`) are snapshotted
    /// as ordinary entries inside `configuration`, not a dedicated field, so they must round-trip
    /// through encode/decode and be readable via `asAnyDictionary` alongside String-valued keys.
    func testDecode_roundTrip_preservesHeterogeneousBatchingKeys() throws {
        let configuration: [String: AnyCodable] = [
            "edge.configId": AnyCodable("1234"),
            EdgeConstants.SharedState.Configuration.EDGE_BATCHING_ENABLED: AnyCodable(true),
            EdgeConstants.SharedState.Configuration.EDGE_BATCHING_EVENT_NAME_ALLOWLIST: AnyCodable(["add-to-cart", "checkout"])
        ]
        let entity = EdgeDataEntity(event: event, configuration: configuration, identityMap: [:])
        let data = try JSONEncoder().encode(entity)
        let decoded = try JSONDecoder().decode(EdgeDataEntity.self, from: data)

        let anyDictionary = decoded.configuration.asAnyDictionary
        XCTAssertEqual("1234", anyDictionary["edge.configId"] as? String)
        XCTAssertEqual(true, anyDictionary[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_ENABLED] as? Bool)
        XCTAssertEqual(["add-to-cart", "checkout"], anyDictionary[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_EVENT_NAME_ALLOWLIST] as? [String])
    }

    /// Simulates a hit persisted before the batching keys existed: `configuration` has neither key.
    /// `asAnyDictionary` lookups for those keys must return nil rather than throwing or crashing.
    func testAsAnyDictionary_missingBatchingKeys_returnsNil() throws {
        let entity = EdgeDataEntity(event: event, configuration: ["edge.configId": AnyCodable("1234")], identityMap: [:])

        let anyDictionary = entity.configuration.asAnyDictionary
        XCTAssertNil(anyDictionary[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_ENABLED])
        XCTAssertNil(anyDictionary[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_EVENT_NAME_ALLOWLIST])
    }
}

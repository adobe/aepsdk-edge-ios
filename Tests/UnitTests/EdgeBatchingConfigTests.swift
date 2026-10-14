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

@testable import AEPEdge
import XCTest

/// Tests for `EdgeBatchingConfig` parsing and `xdm.eventType` allow-list matching, mirroring
/// `aepsdk-edge-android`'s `EdgeBatchingConfigTest.kt`.
class EdgeBatchingConfigTests: XCTestCase {
    private let enabledKey = EdgeConstants.Batching.ENABLED
    private let maxBatchSizeKey = EdgeConstants.Batching.MAX_BATCH_SIZE
    private let wildcardsKey = EdgeConstants.Batching.WILDCARDS
    private let typeKey = EdgeConstants.Batching.XDM_EVENT_TYPE
    private let batchingKey = EdgeConstants.SharedState.Configuration.EDGE_BATCHING

    /// Wraps a raw `edge.batching` object in an Edge configuration map and parses it.
    private func parse(_ batching: [String: Any]) -> EdgeBatchingConfig {
        return EdgeBatchingConfig.from([batchingKey: batching])
    }

    private func entry(_ type: String, _ enabled: Bool) -> [String: Any] {
        return [typeKey: type, enabledKey: enabled]
    }

    // MARK: - Presence / master switch

    func testFromNilConfigurationIsDisabled() {
        let config = EdgeBatchingConfig.from(nil)
        XCTAssertFalse(config.isEnabled)
        XCTAssertFalse(config.isEventTypeBatchable("anything"))
    }

    func testConfigurationWithoutEdgeBatchingKeyIsDisabled() {
        let config = EdgeBatchingConfig.from(["edge.configId": "1234"])
        XCTAssertFalse(config.isEnabled)
        XCTAssertFalse(config.isEventTypeBatchable("anything"))
    }

    func testEdgeBatchingValueThatIsNotAMapIsDisabled() {
        let config = EdgeBatchingConfig.from([batchingKey: "not-a-map"])
        XCTAssertFalse(config.isEnabled)
    }

    func testEnabledTrueIsParsed() {
        XCTAssertTrue(parse([enabledKey: true]).isEnabled)
    }

    func testEnabledFalseAndAbsentAreBothDisabled() {
        XCTAssertFalse(parse([enabledKey: false]).isEnabled)
        XCTAssertFalse(parse([:]).isEnabled)
    }

    // MARK: - maxBatchSize

    func testMaxBatchSizeAbsentUsesDefault() {
        XCTAssertEqual(EdgeConstants.Defaults.MAX_BATCH_SIZE, parse([enabledKey: true]).maxBatchSize)
    }

    func testMaxBatchSizeValidValuePassesThrough() {
        XCTAssertEqual(5, parse([maxBatchSizeKey: 5]).maxBatchSize)
    }

    func testMaxBatchSizeNonPositiveFallsBackToDefault() {
        XCTAssertEqual(EdgeConstants.Defaults.MAX_BATCH_SIZE, parse([maxBatchSizeKey: 0]).maxBatchSize)
        XCTAssertEqual(EdgeConstants.Defaults.MAX_BATCH_SIZE, parse([maxBatchSizeKey: -3]).maxBatchSize)
    }

    func testMaxBatchSizeAboveLimitIsClamped() {
        XCTAssertEqual(EdgeConstants.Defaults.MAX_BATCH_SIZE_LIMIT, parse([maxBatchSizeKey: 999]).maxBatchSize)
    }

    // MARK: - Exact matching

    func testEnabledExactEntryMatchesOnlyItsType() {
        let config = parse([enabledKey: true, "optimize": [entry("decisioning.propositionFetch", true)]])
        XCTAssertTrue(config.isEventTypeBatchable("decisioning.propositionFetch"))
        XCTAssertFalse(config.isEventTypeBatchable("decisioning.propositionInteract"))
    }

    func testDisabledExactEntryIsNotBatchable() {
        let config = parse([enabledKey: true, "optimize": [entry("decisioning.propositionFetch", false)]])
        XCTAssertFalse(config.isEventTypeBatchable("decisioning.propositionFetch"))
    }

    func testEntryWithMissingOrEmptyXdmEventTypeIsIgnored() {
        let config = parse([enabledKey: true, "group": [
            [enabledKey: true],            // no xdmEventType
            [typeKey: "", enabledKey: true] // empty xdmEventType
        ]])
        XCTAssertFalse(config.isEventTypeBatchable(""))
        XCTAssertFalse(config.isEventTypeBatchable("anything"))
    }

    func testExactMatchingIsCaseSensitive() {
        let config = parse([enabledKey: true, "group": [entry("media.play", true)]])
        XCTAssertTrue(config.isEventTypeBatchable("media.play"))
        XCTAssertFalse(config.isEventTypeBatchable("Media.Play"))
    }

    func testSameTypeAcrossGroupsIsBatchableIfAnyEntryIsEnabled() {
        let config = parse([enabledKey: true,
                            "optimize": [entry("decisioning.propositionFetch", false)],
                            "messaging": [entry("decisioning.propositionFetch", true)]])
        XCTAssertTrue(config.isEventTypeBatchable("decisioning.propositionFetch"))
    }

    func testTypeOnlyInDisabledEntriesAcrossGroupsIsNotBatchable() {
        let config = parse([enabledKey: true,
                            "optimize": [entry("decisioning.propositionFetch", false)],
                            "messaging": [entry("decisioning.propositionFetch", false)]])
        XCTAssertFalse(config.isEventTypeBatchable("decisioning.propositionFetch"))
    }

    func testReservedKeysAreNotParsedAsExtensionGroups() {
        // `_meta`, `enabled`, `maxBatchSize`, `wildcards` must never contribute exact-match entries.
        let config = parse([
            enabledKey: true,
            maxBatchSizeKey: 10,
            "_meta": ["schemaVersion": 1],
            wildcardsKey: [entry("media.*", true)]
        ])
        // Nothing exact was declared; only the wildcard should match.
        XCTAssertTrue(config.isEventTypeBatchable("media.play"))
        XCTAssertFalse(config.isEventTypeBatchable("enabled"))
        XCTAssertFalse(config.isEventTypeBatchable("maxBatchSize"))
    }

    // MARK: - Wildcards

    func testTrailingStarIsAPrefixMatch() {
        let config = parse([enabledKey: true, wildcardsKey: [entry("media.*", true)]])
        XCTAssertTrue(config.isEventTypeBatchable("media.play"))
        XCTAssertTrue(config.isEventTypeBatchable("media.sessionStart"))
        XCTAssertFalse(config.isEventTypeBatchable("commerce.purchases"))
    }

    func testLeadingStarIsASuffixMatch() {
        let config = parse([enabledKey: true, wildcardsKey: [entry("*.propositionFetch", true)]])
        XCTAssertTrue(config.isEventTypeBatchable("decisioning.propositionFetch"))
        XCTAssertFalse(config.isEventTypeBatchable("decisioning.propositionInteract"))
    }

    func testBareStarMatchesAnyNonEmptyType() {
        let config = parse([enabledKey: true, wildcardsKey: [entry("*", true)]])
        XCTAssertTrue(config.isEventTypeBatchable("anything"))
        XCTAssertTrue(config.isEventTypeBatchable("media.play"))
    }

    func testDisabledWildcardIsIgnored() {
        let config = parse([enabledKey: true, wildcardsKey: [entry("media.*", false)]])
        XCTAssertFalse(config.isEventTypeBatchable("media.play"))
    }

    func testInfixStarDegradesToExactMatch() {
        let config = parse([enabledKey: true, wildcardsKey: [entry("media.*.play", true)]])
        XCTAssertFalse(config.isEventTypeBatchable("media.foo.play"))
        XCTAssertTrue(config.isEventTypeBatchable("media.*.play"))
    }

    func testNilOrEmptyXdmEventTypeIsNeverBatchableEvenWithBareStar() {
        let config = parse([enabledKey: true, wildcardsKey: [entry("*", true)]])
        XCTAssertFalse(config.isEventTypeBatchable(nil))
        XCTAssertFalse(config.isEventTypeBatchable(""))
    }

    func testNonListGroupValueIsIgnoredWithoutAffectingValidGroups() {
        let config = parse([enabledKey: true,
                            "brokenGroup": "not-a-list",
                            "validGroup": [entry("media.play", true)]])
        XCTAssertTrue(config.isEventTypeBatchable("media.play"))
    }
}

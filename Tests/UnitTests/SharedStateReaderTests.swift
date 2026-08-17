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

class SharedStateReaderTests: XCTestCase {
    private var stubSystemInfoService: StubBatchingSystemInfoService!
    private var originalSystemInfoService: SystemInfoService!
    private let event = Event(name: "test-event", type: EventType.edge, source: EventSource.requestContent, data: nil)

    override func setUp() {
        originalSystemInfoService = ServiceProvider.shared.systemInfoService
        stubSystemInfoService = StubBatchingSystemInfoService()
        ServiceProvider.shared.systemInfoService = stubSystemInfoService
        EdgeBundledBatchingConfig.resetForTesting()
    }

    override func tearDown() {
        ServiceProvider.shared.systemInfoService = originalSystemInfoService
        EdgeBundledBatchingConfig.resetForTesting()
    }

    private func reader(configurationState: [String: Any]?) -> SharedStateReader {
        SharedStateReader(getSharedState: { _, _, _ in
            guard let configurationState = configurationState else { return nil }
            return SharedStateResult(status: .set, value: configurationState)
        })
    }

    func testGetEdgeBatchingConfig_keyAbsentFromConfigState_fallsBackToBundledEnabled() {
        stubSystemInfoService.asset = "{\"edge.batching.enabled\": true}"
        let config = reader(configurationState: [:]).getEdgeBatchingConfig(event: event)

        XCTAssertEqual(true, config[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_ENABLED] as? Bool)
    }

    func testGetEdgeBatchingConfig_keyPresentInConfigState_bundledIgnored() {
        stubSystemInfoService.asset = "{\"edge.batching.enabled\": false}"
        let config = reader(configurationState: [EdgeConstants.SharedState.Configuration.EDGE_BATCHING_ENABLED: true])
            .getEdgeBatchingConfig(event: event)

        XCTAssertEqual(true, config[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_ENABLED] as? Bool)
    }

    func testGetEdgeBatchingConfig_eventNameAllowlist_bundledFallback() {
        stubSystemInfoService.asset = "{\"edge.batching.eventNameAllowlist\": [\"a\", \"b\"]}"
        let config = reader(configurationState: [:]).getEdgeBatchingConfig(event: event)

        XCTAssertEqual(["a", "b"], config[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_EVENT_NAME_ALLOWLIST] as? [String])
    }

    func testGetEdgeBatchingConfig_maxBatchSize_bundledFallback() {
        stubSystemInfoService.asset = "{\"edge.batching.maxBatchSize\": 15}"
        let config = reader(configurationState: [:]).getEdgeBatchingConfig(event: event)

        XCTAssertEqual(15, config[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_MAX_BATCH_SIZE] as? Int)
    }

    func testGetEdgeBatchingConfig_maxBatchSize_configStateWins() {
        stubSystemInfoService.asset = "{\"edge.batching.maxBatchSize\": 20}"
        let config = reader(configurationState: [EdgeConstants.SharedState.Configuration.EDGE_BATCHING_MAX_BATCH_SIZE: 5])
            .getEdgeBatchingConfig(event: event)

        XCTAssertEqual(5, config[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_MAX_BATCH_SIZE] as? Int)
    }

    func testGetEdgeBatchingConfig_allKeysAbsent_returnsEmptyDictionary() {
        stubSystemInfoService.asset = nil
        let config = reader(configurationState: [:]).getEdgeBatchingConfig(event: event)

        XCTAssertTrue(config.isEmpty)
    }

    func testGetEdgeBatchingConfig_maxBatchSize_wrongType_notSurfaced() {
        stubSystemInfoService.asset = nil
        let config = reader(configurationState: [EdgeConstants.SharedState.Configuration.EDGE_BATCHING_MAX_BATCH_SIZE: "not-a-number"])
            .getEdgeBatchingConfig(event: event)

        XCTAssertNil(config[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_MAX_BATCH_SIZE])
    }

    func testGetEdgeBatchingConfig_nilConfigurationSharedState_fallsBackToBundled() {
        stubSystemInfoService.asset = "{\"edge.batching.enabled\": true, \"edge.batching.maxBatchSize\": 12}"
        let config = reader(configurationState: nil).getEdgeBatchingConfig(event: event)

        XCTAssertEqual(true, config[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_ENABLED] as? Bool)
        XCTAssertEqual(12, config[EdgeConstants.SharedState.Configuration.EDGE_BATCHING_MAX_BATCH_SIZE] as? Int)
    }
}

/// Minimal `SystemInfoService` stub exposing a settable `asset` string, used to control
/// `EdgeBundledBatchingConfig`'s fallback source without touching the real app bundle.
private class StubBatchingSystemInfoService: SystemInfoService {
    var asset: String?

    func getProperty(for key: String) -> String? { nil }
    func getAsset(fileName: String, fileType: String) -> String? { asset }
    func getAsset(fileName: String, fileType: String) -> [UInt8]? { nil }
    func getDeviceName() -> String { "" }
    func getMobileCarrierName() -> String? { nil }
    func getRunMode() -> String { "Application" }
    func getApplicationName() -> String? { nil }
    func getApplicationBuildNumber() -> String? { nil }
    func getApplicationVersionNumber() -> String? { nil }
    func getOperatingSystemName() -> String { "" }
    func getOperatingSystemVersion() -> String { "" }
    func getCanonicalPlatformName() -> String { "" }
    func getDisplayInformation() -> (width: Int, height: Int) { (0, 0) }
    func getDefaultUserAgent() -> String { "" }
    func getActiveLocaleName() -> String { "" }
    func getSystemLocaleName() -> String { "" }
    func getDeviceType() -> DeviceType { .UNKNOWN }
    func getApplicationBundleId() -> String? { nil }
    func getApplicationVersion() -> String? { nil }
    func getCurrentOrientation() -> DeviceOrientation { .UNKNOWN }
    func getDeviceModelNumber() -> String { "" }
}

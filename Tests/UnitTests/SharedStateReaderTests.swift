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

    /// Convenience: extracts the resolved `edge.batching` object from a `getEdgeBatchingConfig` result.
    private func batchingObject(_ config: [String: Any]) -> [String: Any]? {
        config[EdgeConstants.SharedState.Configuration.EDGE_BATCHING] as? [String: Any]
    }

    func testGetEdgeBatchingConfig_absentFromConfigState_fallsBackToBundledWholesale() {
        stubSystemInfoService.asset = "{\"enabled\": true, \"maxBatchSize\": 15, \"events\": [{\"xdmEventType\": \"a\", \"enabled\": true}]}"
        let config = reader(configurationState: [:]).getEdgeBatchingConfig(event: event)

        let batching = batchingObject(config)
        XCTAssertEqual(true, batching?[EdgeConstants.Batching.ENABLED] as? Bool)
        XCTAssertEqual(15, batching?[EdgeConstants.Batching.MAX_BATCH_SIZE] as? Int)
        XCTAssertNotNil(batching?["events"])
    }

    func testGetEdgeBatchingConfig_presentInConfigState_winsWholesale_bundledIgnored() {
        // Bundled says disabled; Configuration says enabled — Configuration wins in its entirety.
        stubSystemInfoService.asset = "{\"enabled\": false}"
        let remoteBatching: [String: Any] = [EdgeConstants.Batching.ENABLED: true, EdgeConstants.Batching.MAX_BATCH_SIZE: 7]
        let config = reader(configurationState: [EdgeConstants.SharedState.Configuration.EDGE_BATCHING: remoteBatching])
            .getEdgeBatchingConfig(event: event)

        let batching = batchingObject(config)
        XCTAssertEqual(true, batching?[EdgeConstants.Batching.ENABLED] as? Bool)
        XCTAssertEqual(7, batching?[EdgeConstants.Batching.MAX_BATCH_SIZE] as? Int)
    }

    func testGetEdgeBatchingConfig_wholesale_configStateWins_bundledKeysNotMerged() {
        // Configuration object has no maxBatchSize; the bundled file's maxBatchSize must NOT be merged in
        // (wholesale resolution, not per-key), so it stays absent.
        stubSystemInfoService.asset = "{\"enabled\": false, \"maxBatchSize\": 20}"
        let remoteBatching: [String: Any] = [EdgeConstants.Batching.ENABLED: true]
        let config = reader(configurationState: [EdgeConstants.SharedState.Configuration.EDGE_BATCHING: remoteBatching])
            .getEdgeBatchingConfig(event: event)

        let batching = batchingObject(config)
        XCTAssertEqual(true, batching?[EdgeConstants.Batching.ENABLED] as? Bool)
        XCTAssertNil(batching?[EdgeConstants.Batching.MAX_BATCH_SIZE])
    }

    func testGetEdgeBatchingConfig_absentFromBothSources_returnsEmptyDictionary() {
        stubSystemInfoService.asset = nil
        let config = reader(configurationState: [:]).getEdgeBatchingConfig(event: event)

        XCTAssertTrue(config.isEmpty)
    }

    func testGetEdgeBatchingConfig_nilConfigurationSharedState_fallsBackToBundled() {
        stubSystemInfoService.asset = "{\"enabled\": true, \"maxBatchSize\": 12}"
        let config = reader(configurationState: nil).getEdgeBatchingConfig(event: event)

        let batching = batchingObject(config)
        XCTAssertEqual(true, batching?[EdgeConstants.Batching.ENABLED] as? Bool)
        XCTAssertEqual(12, batching?[EdgeConstants.Batching.MAX_BATCH_SIZE] as? Int)
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

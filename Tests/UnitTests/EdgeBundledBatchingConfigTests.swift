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
import AEPServices
import XCTest

class EdgeBundledBatchingConfigTests: XCTestCase {
    private var stubSystemInfoService: StubSystemInfoService!
    private var originalSystemInfoService: SystemInfoService!

    override func setUp() {
        originalSystemInfoService = ServiceProvider.shared.systemInfoService
        stubSystemInfoService = StubSystemInfoService()
        ServiceProvider.shared.systemInfoService = stubSystemInfoService
        EdgeBundledBatchingConfig.resetForTesting()
    }

    override func tearDown() {
        ServiceProvider.shared.systemInfoService = originalSystemInfoService
        EdgeBundledBatchingConfig.resetForTesting()
    }

    func testGet_validJson_returnsParsedDictionary() {
        stubSystemInfoService.asset = "{\"edge.batching.enabled\": true, \"edge.batching.eventNameAllowlist\": [\"a\", \"b\"], \"edge.batching.maxBatchSize\": 15}"

        let config = EdgeBundledBatchingConfig.get()

        XCTAssertEqual(true, config["edge.batching.enabled"] as? Bool)
        XCTAssertEqual(["a", "b"], config["edge.batching.eventNameAllowlist"] as? [String])
        XCTAssertEqual(15, config["edge.batching.maxBatchSize"] as? Int)
    }

    func testGet_missingFile_returnsEmptyDictionary() {
        stubSystemInfoService.asset = nil

        XCTAssertTrue(EdgeBundledBatchingConfig.get().isEmpty)
    }

    func testGet_emptyFile_returnsEmptyDictionary() {
        stubSystemInfoService.asset = ""

        XCTAssertTrue(EdgeBundledBatchingConfig.get().isEmpty)
    }

    func testGet_malformedJson_returnsEmptyDictionary() {
        stubSystemInfoService.asset = "{not valid json"

        XCTAssertTrue(EdgeBundledBatchingConfig.get().isEmpty)
    }

    func testGet_jsonArrayNotObject_returnsEmptyDictionary() {
        stubSystemInfoService.asset = "[1, 2, 3]"

        XCTAssertTrue(EdgeBundledBatchingConfig.get().isEmpty)
    }

    func testGet_calledTwice_readsAssetOnlyOnce() {
        stubSystemInfoService.asset = "{\"edge.batching.enabled\": true}"

        let firstResult = EdgeBundledBatchingConfig.get()

        // Changing the underlying asset after the first read must not affect subsequent reads - the
        // parsed result is cached the first time `get()` is called.
        stubSystemInfoService.asset = "{\"edge.batching.enabled\": false}"
        let secondResult = EdgeBundledBatchingConfig.get()

        XCTAssertEqual(true, firstResult["edge.batching.enabled"] as? Bool)
        XCTAssertEqual(true, secondResult["edge.batching.enabled"] as? Bool)
        XCTAssertEqual(1, stubSystemInfoService.getAssetCallCount)
    }

    func testResetForTesting_forcesReload() {
        stubSystemInfoService.asset = "{\"edge.batching.enabled\": true}"
        _ = EdgeBundledBatchingConfig.get()

        stubSystemInfoService.asset = "{\"edge.batching.enabled\": false}"
        EdgeBundledBatchingConfig.resetForTesting()
        let result = EdgeBundledBatchingConfig.get()

        XCTAssertEqual(false, result["edge.batching.enabled"] as? Bool)
        XCTAssertEqual(2, stubSystemInfoService.getAssetCallCount)
    }
}

/// Minimal `SystemInfoService` stub exposing a settable `asset` string returned from
/// `getAsset(fileName:fileType:) -> String?`, regardless of the requested file name/type. All other
/// members return placeholder values since `EdgeBundledBatchingConfig` only calls `getAsset`.
private class StubSystemInfoService: SystemInfoService {
    var asset: String?
    private(set) var getAssetCallCount = 0

    func getProperty(for key: String) -> String? { nil }

    func getAsset(fileName: String, fileType: String) -> String? {
        getAssetCallCount += 1
        return asset
    }

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

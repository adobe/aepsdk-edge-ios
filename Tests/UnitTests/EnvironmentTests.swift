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
import AEPServices
import XCTest

class EnvironmentTests: XCTestCase {

    private func buildAndSetMockInfoService() {
        let mockSystemInfoService = MockSystemInfoService()
        mockSystemInfoService.mobileCarrierName = "test-carrier"
        mockSystemInfoService.platformName = "test-platform"
        mockSystemInfoService.operatingSystemName = "test-os-name"
        mockSystemInfoService.operatingSystemVersion = "test-os-version"
        ServiceProvider.shared.systemInfoService = mockSystemInfoService
    }

    func testFromDirectData() {
        // setup
        buildAndSetMockInfoService()

        let lifecycleContextData = ["locale": "en-US", "runmode": "Application"]
        let directData = ["lifecyclecontextdata": lifecycleContextData]

        // test
        let env = Environment.fromDirect(data: directData) as? Environment

        // verify
        XCTAssertEqual("test-carrier", env?.carrier)
        XCTAssertEqual("en-US", env?.language)
        XCTAssertEqual("test-platform", env?.operatingSystemVendor)
        XCTAssertEqual("test-os-name", env?.operatingSystem)
        XCTAssertEqual("test-os-version", env?.operatingSystemVersion)
        XCTAssertEqual(EnvironmentType.application, env?.type)
    }

    // MARK: Encodable tests

    func testEncodeEnvironment() throws {
        // setup
        buildAndSetMockInfoService()
        let lifecycleContextData = ["locale": "en-US", "runmode": "Application"]
        let directData = ["lifecyclecontextdata": lifecycleContextData]
        let env = Environment.fromDirect(data: directData) as? Environment

        // test
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try XCTUnwrap(encoder.encode(env))
        let dataStr = try XCTUnwrap(String(data: data, encoding: .utf8))

        // verify
        let expected = """
        {
          "operatingSystemVendor" : "test-platform",
          "language" : "en-US",
          "carrier" : "test-carrier",
          "operatingSystemVersion" : "test-os-version",
          "operatingSystem" : "test-os-name",
          "type" : "application"
        }
        """

        XCTAssertEqual(expected, dataStr)
    }

}

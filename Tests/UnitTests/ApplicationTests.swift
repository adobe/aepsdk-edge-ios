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

class ApplicationTests: XCTestCase {

    private func buildAndSetMockInfoService() {
        let mockSystemInfoService = MockSystemInfoService()
        mockSystemInfoService.appId = "test-app-id"
        mockSystemInfoService.applicationName = "test-app-name"
        mockSystemInfoService.appVersion = "test-version"
        ServiceProvider.shared.systemInfoService = mockSystemInfoService
    }

    func testFromDirectData() {
        // setup
        buildAndSetMockInfoService()

        let lifecycleContextData = ["installdate": "5/17/2021",
                                    "installevent": "InstallEvent",
                                    "launchevent": "LaunchEvent",
                                    "upgradeevent": "UpgradeEvent",
                                    "prevsessionlength": "424394"]
        let directData = ["lifecyclecontextdata": lifecycleContextData]

        // test
        let application = Application.fromDirect(data: directData) as? Application

        // verify
        XCTAssertEqual("test-app-id", application?.id)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        XCTAssertEqual(formatter.date(from: "5/17/2021"), application?.installDate)
        XCTAssertTrue(application?.isInstall ?? false)
        XCTAssertTrue(application?.isLaunch ?? false)
        XCTAssertTrue(application?.isUpgrade ?? false)
        XCTAssertEqual("test-app-name", application?.name)
        XCTAssertEqual(424394, application?.sessionLength)
        XCTAssertEqual("test-version", application?.version)
    }

    // MARK: Encodable Tests

    func testEncodeApplication() throws {
        // setup
        buildAndSetMockInfoService()

        let lifecycleContextData = ["installdate": "5/17/2021",
                                    "installevent": "InstallEvent",
                                    "launchevent": "LaunchEvent",
                                    "upgradeevent": "UpgradeEvent",
                                    "prevsessionlength": "424394"]
        let directData = ["lifecyclecontextdata": lifecycleContextData]

        let application = Application.fromDirect(data: directData) as? Application

        // test
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try XCTUnwrap(encoder.encode(application))
        let dataStr = try XCTUnwrap(String(data: data, encoding: .utf8))

        // verify
        let expected = """
        {
          "isInstall" : true,
          "id" : "test-app-id",
          "sessionLength" : 424394,
          "isLaunch" : true,
          "installDate" : "2021-05-17",
          "version" : "test-version",
          "isUpgrade" : true,
          "name" : "test-app-name"
        }
        """

        XCTAssertEqual(expected, dataStr)
    }
}

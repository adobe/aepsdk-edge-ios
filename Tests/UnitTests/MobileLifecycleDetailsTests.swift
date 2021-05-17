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

class MobileLifecycleDetailsTests: XCTestCase {

    private func buildAndSetMockInfoService() {
        let mockSystemInfoService = MockSystemInfoService()
        mockSystemInfoService.appId = "test-app-id"
        mockSystemInfoService.applicationName = "test-app-name"
        mockSystemInfoService.appVersion = "test-version"
        mockSystemInfoService.mobileCarrierName = "test-carrier"
        mockSystemInfoService.platformName = "test-platform"
        mockSystemInfoService.operatingSystemName = "test-os-name"
        mockSystemInfoService.operatingSystemVersion = "test-os-version"
        mockSystemInfoService.deviceName = "test-device-name"
        mockSystemInfoService.displayInformation = (100, 200)
        mockSystemInfoService.orientation = .PORTRAIT
        mockSystemInfoService.deviceType = .PHONE
        ServiceProvider.shared.systemInfoService = mockSystemInfoService
    }

    func testFromDirectData() {
        // setup
        buildAndSetMockInfoService()

        let lifecycleContextData = ["installdate": "5/17/2021",
                                    "installevent": "InstallEvent",
                                    "launchevent": "LaunchEvent",
                                    "upgradeevent": "UpgradeEvent",
                                    "prevsessionlength": "424394",
                                    "locale": "en-US",
                                    "runmode": "Application"]
        let directData = ["lifecyclecontextdata": lifecycleContextData]

        // test
        let lifecycleDetails = MobileLifecycleDetails.fromDirect(data: directData) as? MobileLifecycleDetails

        // verify
        XCTAssertEqual("application.lifecycle", lifecycleDetails?.eventType)
        XCTAssertEqual("test-app-id", lifecycleDetails?.application?.id)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        XCTAssertEqual(formatter.date(from: "5/17/2021"), lifecycleDetails?.application?.installDate)
        XCTAssertTrue(lifecycleDetails?.application?.isInstall ?? false)
        XCTAssertTrue(lifecycleDetails?.application?.isLaunch ?? false)
        XCTAssertTrue(lifecycleDetails?.application?.isUpgrade ?? false)
        XCTAssertEqual("test-app-name", lifecycleDetails?.application?.name)
        XCTAssertEqual(424394, lifecycleDetails?.application?.sessionLength)
        XCTAssertEqual("test-version", lifecycleDetails?.application?.version)

        XCTAssertEqual("apple", lifecycleDetails?.device?.manufacturer)
        XCTAssertEqual("test-device-name", lifecycleDetails?.device?.model)
        XCTAssertEqual(100, lifecycleDetails?.device?.screenWidth)
        XCTAssertEqual(200, lifecycleDetails?.device?.screenHeight)
        XCTAssertEqual(ScreenOrientation.portrait, lifecycleDetails?.device?.screenOrientation)
        XCTAssertEqual(DeviceType.mobile, lifecycleDetails?.device?.type)

        XCTAssertEqual("test-carrier", lifecycleDetails?.environment?.carrier)
        XCTAssertEqual("en-US", lifecycleDetails?.environment?.language)
        XCTAssertEqual("test-platform", lifecycleDetails?.environment?.operatingSystemVendor)
        XCTAssertEqual("test-os-name", lifecycleDetails?.environment?.operatingSystem)
        XCTAssertEqual("test-os-version", lifecycleDetails?.environment?.operatingSystemVersion)
        XCTAssertEqual(EnvironmentType.application, lifecycleDetails?.environment?.type)
    }

    // MARK: Encodable Tests

    func testEncodeLifecycleDetails() throws {
        // setup
        buildAndSetMockInfoService()

        let lifecycleContextData = ["installdate": "5/17/2021",
                                    "installevent": "InstallEvent",
                                    "launchevent": "LaunchEvent",
                                    "upgradeevent": "UpgradeEvent",
                                    "prevsessionlength": "424394",
                                    "locale": "en-US",
                                    "runmode": "Application"]
        let directData = ["lifecyclecontextdata": lifecycleContextData]

        let lifecycleDetails = MobileLifecycleDetails.fromDirect(data: directData) as? MobileLifecycleDetails

        // test
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try XCTUnwrap(encoder.encode(lifecycleDetails))
        let dataStr = try XCTUnwrap(String(data: data, encoding: .utf8))

        // verify
        let expected = """
        {
          "environment" : {
            "operatingSystemVendor" : "test-platform",
            "language" : "en-US",
            "carrier" : "test-carrier",
            "operatingSystemVersion" : "test-os-version",
            "operatingSystem" : "test-os-name",
            "type" : "application"
          },
          "device" : {
            "manufacturer" : "apple",
            "model" : "test-device-name",
            "screenHeight" : 200,
            "screenWidth" : 100,
            "screenOrientation" : "portrait",
            "type" : "mobile"
          },
          "application" : {
            "isInstall" : true,
            "id" : "test-app-id",
            "sessionLength" : 424394,
            "isLaunch" : true,
            "installDate" : "2021-05-17",
            "version" : "test-version",
            "isUpgrade" : true,
            "name" : "test-app-name"
          },
          "eventType" : "application.lifecycle"
        }
        """

        XCTAssertEqual(expected, dataStr)
    }

}

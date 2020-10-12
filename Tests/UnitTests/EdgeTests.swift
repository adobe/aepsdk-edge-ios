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

import AEPCore
import XCTest

@testable import AEPEdge

class EdgeTests: XCTestCase {
    private var mockResponseHandler: MockEdgeResponseHandler?

    override func setUp() {
        continueAfterFailure = false
        mockResponseHandler = MockEdgeResponseHandler()
    }

    func generateXdm() -> [String: Any] {
        var xdm = [String: Any]()
        xdm["testXdmKey1"] = "testXdmValue1"
        xdm["testXdmKey2"] = "testXdmValue2"
        return xdm
    }

    func generateData() -> [String: Any] {
        var data = [String: Any]()
        data["testDataKey1"] = "testDataValue1"
        data["testDataKey2"] = "testDataValue2"
        return data
    }

    struct MobileSDKSchema: XDMSchema {
        var schemaVersion: String
        var schemaIdentifier: String
        var datasetIdentifier: String
    }
    let generateXdmSchema = MobileSDKSchema(schemaVersion: "1.4", schemaIdentifier: "https://ns.adobe.com/acopprod1/schemas/e1af53c26439f963fbfebe50330323ae", datasetIdentifier: "5dd603781b95cc18a83d42ce")

    func testRegisterExtension_registersWithoutAnyErrorOrCrash() {
        XCTAssertNoThrow(MobileCore.registerExtensions([Edge.self]))
    }

    func testSendEvent_withNonNullXdmAndNonNullData_ExperienceEventData() {
        MobileCore.registerExtensions([Edge.self])
        let experienceEvent = ExperienceEvent(xdm: generateXdm(), data: generateData())
        XCTAssertTrue(Edge.sendEvent(experienceEvent: experienceEvent, responseHandler: mockResponseHandler) == ())
    }

    func testSendEvent_withNonNullXdmAndNullData_ExperienceEventData() {
        MobileCore.registerExtensions([Edge.self])
        let experienceEvent = ExperienceEvent(xdm: generateXdm(), data: nil)
        XCTAssertTrue(Edge.sendEvent(experienceEvent: experienceEvent, responseHandler: mockResponseHandler) == ())
    }

    func testSendEvent_withNonNullXdmSchemaAndNonNullData_ExperienceEventData() {
        MobileCore.registerExtensions([Edge.self])
        let experienceEvent = ExperienceEvent(xdm: generateXdmSchema, data: generateData())
        XCTAssertTrue(Edge.sendEvent(experienceEvent: experienceEvent, responseHandler: mockResponseHandler) == ())
    }
}

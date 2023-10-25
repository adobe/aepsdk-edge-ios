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

@testable import AEPEdge
import XCTest

class ExperienceEventTests: XCTestCase {
    private let datasetId = "datasetId"
    private let xdm = "xdm"
    private let data = "data"
    private let query = "query"
    private let config = "config"

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
    let generatedXdmSchema = MobileSDKSchema(schemaVersion: "1.4", schemaIdentifier: "https://ns.adobe.com/acopprod1/schemas/e1af53c26439f963fbfebe50330323ae", datasetIdentifier: "5dd603781b95cc18a83d42ce")
    let expectedXdmSchema = ["schemaVersion": "1.4", "schemaIdentifier": "https://ns.adobe.com/acopprod1/schemas/e1af53c26439f963fbfebe50330323ae", "datasetIdentifier": "5dd603781b95cc18a83d42ce"]

    func testAsDictionary_withXdmAndData() {

        let expectedXdm = generateXdm()
        let expectedData = generateData()

        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdm
        expectedEventData[data] = expectedData

        let experienceEvent = ExperienceEvent(xdm: expectedXdm, data: expectedData)
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func testAsDictionary_withNilXdmAndNilData() {

        let expectedXdm = generateXdm()

        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdm
        expectedEventData[data] = nil

        let experienceEvent = ExperienceEvent(xdm: expectedXdm, data: nil)
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func testAsDictionary_withXdmAndDatasetId() {

        let expectedXdm = generateXdm()

        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdm
        expectedEventData[data] = nil
        expectedEventData[datasetId] = "testDatasetId"

        let experienceEvent = ExperienceEvent(xdm: expectedXdm, data: nil, datasetIdentifier: "testDatasetId")
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func testAsDictionary_withXdmAndEmptyDatasetId() {

        let expectedXdm = generateXdm()

        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdm
        expectedEventData[data] = nil
        expectedEventData[datasetId] = ""

        let experienceEvent = ExperienceEvent(xdm: expectedXdm, data: nil, datasetIdentifier: "")
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func testAsDictionary_withXdmSchemaAndData() {

        let expectedData = generateData()
        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdmSchema
        expectedEventData[data] = expectedData
        expectedEventData[datasetId] = "5dd603781b95cc18a83d42ce"

        let experienceEvent = ExperienceEvent(xdm: generatedXdmSchema, data: expectedData)
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func testAsDictionary_withXdmSchemaAndDataAndDatastreamIdOverride() {

        let expectedData = generateData()
        let expectedConfig: [String: Any] = ["datastreamIdOverride": "testDatastreamId"]
        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdmSchema
        expectedEventData[data] = expectedData
        expectedEventData[datasetId] = "5dd603781b95cc18a83d42ce"
        expectedEventData[config] = expectedConfig

        let experienceEvent = ExperienceEvent(xdm: generatedXdmSchema, data: expectedData, datastreamIdOverride: "testDatastreamId")
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func testAsDictionary_withXdmSchemaAndDataAndDatastreamConfigOverride() {

        let expectedData = generateData()
        let expectedConfig: [String: Any] = ["datastreamConfigOverride": ["key": "value"]]
        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdmSchema
        expectedEventData[data] = expectedData
        expectedEventData[datasetId] = "5dd603781b95cc18a83d42ce"
        expectedEventData[config] = expectedConfig

        let experienceEvent = ExperienceEvent(xdm: generatedXdmSchema, data: expectedData, datastreamConfigOverride: ["key": "value"])
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func testAsDictionary_withXdmSchemaAndDataAndDatastreamIdOverrideAndDatastreamConfigOverride() {

        let expectedData = generateData()
        let expectedConfig: [String: Any] = ["datastreamIdOverride": "testDatastreamId", "datastreamConfigOverride": ["key": "value"]]
        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdmSchema
        expectedEventData[data] = expectedData
        expectedEventData[datasetId] = "5dd603781b95cc18a83d42ce"
        expectedEventData[config] = expectedConfig

        let experienceEvent = ExperienceEvent(xdm: generatedXdmSchema, data: expectedData, datastreamIdOverride: "testDatastreamId", datastreamConfigOverride: ["key": "value"])
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func testAsDictionary_withXdmSchemaAndEmptyDatasetIdAndDataAndDatastreamIdOverrideAndDatastreamConfigOverride() {

        let expectedData = generateData()
        let xdmSchemaWithEmptyDatasetId = MobileSDKSchema(schemaVersion: "1.4", schemaIdentifier: "https://ns.adobe.com/acopprod1/schemas/e1af53c26439f963fbfebe50330323ae", datasetIdentifier: "")
        let expectedXdmSchema = ["schemaVersion": "1.4", "schemaIdentifier": "https://ns.adobe.com/acopprod1/schemas/e1af53c26439f963fbfebe50330323ae", "datasetIdentifier": ""]

        let expectedConfig: [String: Any] = ["datastreamIdOverride": "testDatastreamId", "datastreamConfigOverride": ["key": "value"]]
        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdmSchema
        expectedEventData[datasetId] = ""
        expectedEventData[data] = expectedData
        expectedEventData[config] = expectedConfig

        let experienceEvent = ExperienceEvent(xdm: xdmSchemaWithEmptyDatasetId, data: expectedData, datastreamIdOverride: "testDatastreamId", datastreamConfigOverride: ["key": "value"])
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func testAsDictionary_withXdmSchemaAndNilData() {

        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdmSchema
        expectedEventData[data] = nil
        expectedEventData[datasetId] = "5dd603781b95cc18a83d42ce"

        let experienceEvent = ExperienceEvent(xdm: generatedXdmSchema, data: nil)
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func testAsDictionary_withQuery() {

        let expectedQuery = generateData()
        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdmSchema
        expectedEventData[data] = nil
        expectedEventData[datasetId] = "5dd603781b95cc18a83d42ce"
        expectedEventData[query] = expectedQuery

        let experienceEvent = ExperienceEvent(xdm: generatedXdmSchema, data: nil)
        experienceEvent.query = expectedQuery
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func testAsDictionary_withNilQuery() {

        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdmSchema
        expectedEventData[data] = nil
        expectedEventData[datasetId] = "5dd603781b95cc18a83d42ce"

        let experienceEvent = ExperienceEvent(xdm: generatedXdmSchema, data: nil)
        experienceEvent.query = nil
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func testAsDictionary_withXdmAndDatastreamIdOverride() {

        let expectedXdm = generateXdm()
        let expectedConfig: [String: Any] = ["datastreamIdOverride": "testDatastreamId"]

        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdm
        expectedEventData[config] = expectedConfig

        let experienceEvent = ExperienceEvent(xdm: expectedXdm, datastreamIdOverride: "testDatastreamId")
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func testAsDictionary_withXdmAndDatastreamConfigOverride() {

        let expectedXdm = generateXdm()
        let expectedConfig: [String: Any] = ["datastreamConfigOverride": ["key": "value"]]

        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdm
        expectedEventData[config] = expectedConfig

        let experienceEvent = ExperienceEvent(xdm: expectedXdm, datastreamConfigOverride: ["key": "value"])
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func testAsDictionary_withXdmAndDatastreamIdOverrideAndDatastreamConfigOverride() {

        let expectedXdm = generateXdm()
        let expectedConfig: [String: Any] = ["datastreamIdOverride": "testDatastreamId", "datastreamConfigOverride": ["key": "value"]]

        var expectedEventData: [String: Any] = [:]
        expectedEventData[xdm] = expectedXdm
        expectedEventData[config] = expectedConfig

        let experienceEvent = ExperienceEvent(xdm: expectedXdm, datastreamIdOverride: "testDatastreamId", datastreamConfigOverride: ["key": "value"])
        guard let actualEventData = experienceEvent.asDictionary() else {
            XCTFail("Failed to retrieve experience event asDictionary")
            return
        }
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

}

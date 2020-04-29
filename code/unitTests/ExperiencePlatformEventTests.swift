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


import XCTest
@testable import ACPExperiencePlatform


class ExperiencePlatformEventTests: XCTestCase {
    
    func generateXdm() -> XDM {
        var xdm = XDM
        xdm["testXdmKey1"] = "testXdmValue1"
        xdm["testXdmKey2"] = "testXdmValue2"
        return xdm
    }
 
    func generatedXdmSchema() -> [String : Any] {
        var xdmSchema = [String: Any]()
        xdmSchema["testXdmSchemaKey1"] = "testXdmSchemaValue1"
        xdmSchema["testXdmSchemaKey2"] = "testXdmSchemaValue2"
        return xdmSchema
    }

    func generateData()  -> [String : Any] {
        var data = [String: Any]()
         data["testDataKey1"] = "testDataValue1"
         data["testDataKey2"] = "testDataValue2"
         return data
   }

    
    func test_asDictionary_withNonNullXdmAndData_ExperiencePlatformEventData() {
        
        let expectedXdm = generateXdm()
        let expectedData = generateData()
        
        var expectedEventData: [String : Any] = [:]
        expectedEventData["xdm"] = expectedXdm
        expectedEventData["data"] = expectedData

        let experiencePlatformEvent: ExperiencePlatformEvent
        experiencePlatformEvent.xdm = expectedXdm
        experiencePlatformEvent.data = expectedData
        let actualEventData = experiencePlatformEvent.asDictionary()

        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
    }

    func test_asDictionary_withNonNullXdmAndNullData_ExperiencePlatformEventData() {

        let expectedXdm = generateXdm()
        let expectedData = nil
        
        var expectedEventData: [String : Any] = [:]
        expectedEventData["xdm"] = expectedXdm
        expectedEventData["data"] = nil

        let experiencePlatformEvent: ExperiencePlatformEvent
        experiencePlatformEvent.xdm = expectedXdm
        experiencePlatformEvent.data = nil
        let actualEventData = experiencePlatformEvent.asDictionary()

        XCTAssertTrue(NSDictionary(dictionary: actualEventData!).isEqual(to: expectedEventData))
    }

    
    func test_asDictionary_withNullXdmAndNonNullData_ExperiencePlatformEventData() {

        let expectedXdm = nil
        let expectedData = generateData()
        
        var expectedEventData: [String : Any] = [:]
        expectedEventData["xdm"] = nil
        expectedEventData["data"] = expectedData
        
        let experiencePlatformEvent: ExperiencePlatformEvent
        experiencePlatformEvent.xdm = nil
        experiencePlatformEvent.data = expectedData
        let actualEventData = experiencePlatformEvent.asDictionary()
        XCTAssertTrue(NSDictionary(dictionary: actualEventData!).isEqual(to: expectedEventData))
    }

    func test_asDictionary_withNullDataAndXdm_ExperiencePlatformEventData() {
          
          let expectedXdm = generateXdm()
          let expectedData = nil
          
          var expectedEventData: [String : Any] = [:]
          expectedEventData["xdm"] = nil
          expectedEventData["data"] = nil

          let experiencePlatformEvent: ExperiencePlatformEvent
          experiencePlatformEvent.xdm = nil
          experiencePlatformEvent.data = nil

          let actualEventData = experiencePlatformEvent.asDictionary()
          XCTAssertTrue(NSDictionary(dictionary: actualEventData!).isEqual(to: expectedEventData))
      }

    
    func test_asDictionary_withNonNullXdmSchemsAndData_ExperiencePlatformEventData() {
        
        let expectedXdmSchema = generatedXdmSchema()
        let expectedData = generateData()
        let event:ExperiencePlatformEvent = ExperiencePlatformEvent(xdm:expectedXdmSchema,data:expectedData)
        
        var expectedEventData: [String : Any] = [:]
        expectedEventData["xdm"] = expectedXdmSchema
        expectedEventData["data"] = expectedData
        let experiencePlatformEvent: ExperiencePlatformEvent = ExperiencePlatformEvent(xdm:expectedXdmSchema,data:expectedData)
        let actualEventData = experiencePlatformEvent.asDictionary()
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
      }

    func test_asDictionary_withNonNullXdmSchemsAndNullData_ExperiencePlatformEventData() {
        
        let expectedXdmSchema = generatedXdmSchema()
        let expectedData =  nil
        let event:ExperiencePlatformEvent = ExperiencePlatformEvent(xdm:expectedXdmSchema,data:expectedData)
        
        var expectedEventData: [String : Any] = [:]
        expectedEventData["xdm"] = expectedXdmSchema
        expectedEventData["data"] = expectedData
        let experiencePlatformEvent: ExperiencePlatformEvent = ExperiencePlatformEvent(xdm:expectedXdmSchema,data:expectedData)
        let actualEventData = experiencePlatformEvent.asDictionary()
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
      }

    func test_asDictionary_withNullXdmSchemsAndNonNullData_ExperiencePlatformEventData() {
        
        let expectedXdmSchema = nil
        let expectedData = generateData()
        let event:ExperiencePlatformEvent = ExperiencePlatformEvent(xdm:expectedXdmSchema,data:expectedData)
        
        var expectedEventData: [String : Any] = [:]
        expectedEventData["xdm"] = expectedXdmSchema
        expectedEventData["data"] = expectedData
        let experiencePlatformEvent: ExperiencePlatformEvent = ExperiencePlatformEvent(xdm:expectedXdmSchema,data:expectedData)
        let actualEventData = experiencePlatformEvent.asDictionary()
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
      }

    func test_asDictionary_withNullXdmSchemsAndNullData_ExperiencePlatformEventData() {
        
        let expectedXdmSchema = nil
        let expectedData = nil
        let event:ExperiencePlatformEvent = ExperiencePlatformEvent(xdm:expectedXdmSchema,data:expectedData)
        
        var expectedEventData: [String : Any] = [:]
        expectedEventData["xdm"] = expectedXdmSchema
        expectedEventData["data"] = expectedData
        let experiencePlatformEvent: ExperiencePlatformEvent = ExperiencePlatformEvent(xdm:expectedXdmSchema,data:expectedData)
        let actualEventData = experiencePlatformEvent.asDictionary()
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))
      }

    
    
   
}

//
// ADOBE CONFIDENTIAL
//
// Copyright 2020 Adobe
// All Rights Reserved.
//
// NOTICE: All information contained herein is, and remains
// the property of Adobe and its suppliers, if any. The intellectual
// and technical concepts contained herein are proprietary to Adobe
// and its suppliers and are protected by all applicable intellectual
// property laws, including trade secret and copyright laws.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from Adobe.
//


import XCTest
@testable import ACPExperiencePlatform


class ExperiencePlatformEventTests: XCTestCase {
    
    func generateXdmData() -> [String : Any] {
        
        var xdmData = [String: Any]()
        xdmData["testXdmKey1"] = "testXdmValue1"
        xdmData["testXdmKey2"] = "testXdmValue2"
        return xdmData
    }
 
    func generateData()  -> [String : Any] {
        var data = [String: Any]()
         data["testeventDataKey1"] = "testeventDataValue1"
         data["testeventDataKey2"] = "testeventDataValue2"
         return data
   }

    
    
    func test_asDictionary_ExperiencePlatformEventData() {
        
        let expectedXdmData = generateXdmData()
        let expectedData = generateData()
        
        var expectedEventData: [String : Any] = [:]
        expectedEventData["xdm"] = expectedXdmData
        expectedEventData["data"] = expectedData
        let experiencePlatformEvent: ExperiencePlatformEvent! = ExperiencePlatformEvent(xdmData:expectedXdmData,data:expectedData)

        let actualEventData = experiencePlatformEvent.asDictionary()
        XCTAssertTrue(NSDictionary(dictionary: actualEventData!).isEqual(to: expectedEventData))
    }

   
}

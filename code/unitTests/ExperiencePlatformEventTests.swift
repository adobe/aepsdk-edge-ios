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

     override func setUp() {
          // Put setup code here. This method is called before the invocation of each test method in the class.
          continueAfterFailure = false // fail so nil checks stop execution
      }
      
      override func tearDown() {
          // Put teardown code here. This method is called after the invocation of each test method in the class.
      }
    
    func generateXdmData() -> [String : Any] {
        
        var xdmData = [String: Any]()
        xdmData["testXdmKey1"] = "testXdmValue1"
        xdmData["testXdmKey2"] = "testXdmValue2"
        return xdmData;
    }
 
    func generateEventData()  -> [String : Any] {
        var eventData = [String: Any]()
         eventData["testeventDataKey1"] = "testeventDataValue1"
         eventData["testeventDataKey2"] = "testeventDataValue2"
         return eventData;

    }

    
    
    func test_ExperiencePlatformEvent() {
        
        let expectedXdmData = generateXdmData()
        let expectedEventData = generateEventData()
        let experiencePlatformEvent: ExperiencePlatformEvent! = ExperiencePlatformEvent(xdmData:expectedXdmData,data:expectedEventData)
        let actualXdmData = experiencePlatformEvent.xdmData
        let actualEventData = experiencePlatformEvent.data
        XCTAssertTrue(NSDictionary(dictionary: actualXdmData).isEqual(to: expectedXdmData))
        XCTAssertTrue(NSDictionary(dictionary: actualEventData).isEqual(to: expectedEventData))

    }

   
}

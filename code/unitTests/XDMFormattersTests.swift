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

class XDMFormattersTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func matches(regex: String, text: String) -> NSRange {
        var range:NSRange = NSRange(location: 0, length: 0)
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in:text, range: NSRange(location: 0, length: nsString.length))
            for match in results {
                range = match.range
            }
            return range
        } catch  {
            return range
        }
    }
    
    func test_dateToISO8601String_onValidTimestamp_returnsFormattedString() {
        
        var dateComponents = DateComponents()
        dateComponents.year = 2019
        dateComponents.month = 9
        dateComponents.day = 23
        dateComponents.timeZone = TimeZone(abbreviation: "Z")
        dateComponents.hour = 11
        dateComponents.minute = 15
        dateComponents.second = 45
        let userCalendar = Calendar.current
        let cal = userCalendar.date(from: dateComponents)
        let serializedDate: String = XDMFormatters.dateToISO8601String (from:cal)!
        var pattern: String
        if (serializedDate.contains("Z")) {
            pattern = "[0-9]{4}-[0-9]{2}-[0-9]{2}T([0-9]{2}:){2}[0-9]{2}Z";
        } else {
            pattern = "[0-9]{4}-[0-9]{2}-[0-9]{2}T([0-9]{2}:){2}[0-9]{2}[+|-][0-9]{2}:[0-9]{2}";
        }
        XCTAssertEqual(NSMakeRange(0, 20), matches(regex: pattern, text: serializedDate))
    }
    
    func test_dateToISO8601String_onNil_returnsEmptyString() {
        let currentDateTime:Date? = nil
        let serializedDate: String = XDMFormatters.dateToISO8601String (from:currentDateTime)!
        XCTAssertEqual(serializedDate,"")
    }

    func test_dateToFullDateString_onValidTimestamp_returnsFormattedString() {
           
        var dateComponents = DateComponents()
        dateComponents.year = 2019
        dateComponents.month = 9
        dateComponents.day = 23
        dateComponents.timeZone = TimeZone(abbreviation: "Z")
        dateComponents.hour = 11
        dateComponents.minute = 15
        dateComponents.second = 45
        let userCalendar = Calendar.current
        let cal = userCalendar.date(from: dateComponents)

        let serializedDate: String = XDMFormatters.dateToFullDateString (from:cal)!
        var pattern: String
        pattern = "[0-9]{4}-[0-9]{2}-[0-9]{2}";

        XCTAssertEqual("2019-09-23",serializedDate)
        XCTAssertEqual(NSMakeRange(0, 10), matches(regex: pattern, text: serializedDate))
       }

    func test_dateToFullDateString_onNil_returnsEmptyString() {
        
         let cal:Date? = nil
         let serializedDate: String = XDMFormatters.dateToFullDateString (from:cal)!
         XCTAssertEqual("",serializedDate)
    }
    
    
}


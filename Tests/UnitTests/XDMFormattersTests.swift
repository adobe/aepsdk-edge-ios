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

class XDMFormattersTests: XCTestCase {

    func matches(regex: String, text: String) -> NSRange {
        var range: NSRange = NSRange(location: 0, length: 0)
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            for match in results {
                range = match.range
            }
            return range
        } catch {
            return range
        }
    }

    func testDateToISO8601String_onValidTimestamp_returnsFormattedString() {

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
        guard let serializedDate: String = XDMFormatters.dateToISO8601String(from: cal) else {
            XCTFail("Failed to serialize date to ISO8601 string")
            return
        }
        var pattern: String
        if serializedDate.contains("Z") {
            pattern = "[0-9]{4}-[0-9]{2}-[0-9]{2}T([0-9]{2}:){2}[0-9]{2}Z"
        } else {
            pattern = "[0-9]{4}-[0-9]{2}-[0-9]{2}T([0-9]{2}:){2}[0-9]{2}[+|-][0-9]{2}:[0-9]{2}"
        }
        XCTAssertEqual(NSRange(location: 0, length: 20), matches(regex: pattern, text: serializedDate))
    }

    func testDateToISO8601String_onNil_returnsNil() {

        let cal: Date? = nil
        XCTAssertNil(XDMFormatters.dateToISO8601String(from: cal))
    }

    func testDateToFullDateString_onValidTimestamp_returnsFormattedString() {

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

        guard let serializedDate: String = XDMFormatters.dateToFullDateString(from: cal) else {
            XCTFail("Failed to convert date to full date string")
            return
        }
        var pattern: String
        pattern = "[0-9]{4}-[0-9]{2}-[0-9]{2}"

        XCTAssertEqual("2019-09-23", serializedDate)
        XCTAssertEqual(NSRange(location: 0, length: 10), matches(regex: pattern, text: serializedDate))
    }

    func testDateToFullDateString_onNil_returnsNil() {

        let cal: Date? = nil
        XCTAssertNil(XDMFormatters.dateToFullDateString(from: cal))
    }
}

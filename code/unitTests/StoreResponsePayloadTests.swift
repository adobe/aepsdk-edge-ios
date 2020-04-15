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

class StoreResponsePayloadTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: encoder tests

    func testEncode() {
        let payload = StoreResponsePayload(key: "key", value: "value", maxAgeSeconds: 3600)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(payload)
        
        XCTAssertNotNil(data)
        let expected = """
           {
             "expiryDate" : "\(ISO8601DateFormatter().string(from: payload.expiryDate))",
             "payload" : {
               "key" : "key",
               "maxAge" : 3600,
               "value" : "value"
             }
           }
           """
        let jsonString = String(data: data!, encoding: .utf8)
        XCTAssertEqual(expected, jsonString)
    }
    
    // MARK: decoder tests
    
    func testDecode() {
        let data = """
            {
              "expiryDate" : "2020-04-10T20:34:12Z",
              "payload" : {
                "key" : "key",
                "maxAge" : 3600,
                "value" : "value"
              }
            }
        """.data(using: .utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let storeResponse = try? decoder.decode(StoreResponsePayload.self, from: data!)
        XCTAssertNotNil(storeResponse)
        XCTAssertEqual("key", storeResponse?.payload.key)
        XCTAssertEqual("value", storeResponse?.payload.value)
        XCTAssertEqual(3600, storeResponse?.payload.maxAge)
        
        let dateFormatter = ISO8601DateFormatter()
        let expectedDate = dateFormatter.date(from: "2020-04-10T20:34:12Z")
        XCTAssertEqual(expectedDate, storeResponse?.expiryDate)
    }
    
    // MARK: is expired tests
    
    func testIsExpired_expiryDateSetFromMaxAge_oneHourAhead() {
        let date = Date(timeIntervalSinceNow: 36000)
        let data = """
            {
              "expiryDate" : "\(ISO8601DateFormatter().string(from: date))",
              "payload" : {
                "key" : "key",
                "maxAge" : 3600,
                "value" : "value"
              }
            }
        """.data(using: .utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let payload = try? decoder.decode(StoreResponsePayload.self, from: data!) else {
            XCTFail("Failed to decode StoreResponsePayload.")
            return
        }

        XCTAssertFalse(payload.isExpired)
    }
    
    func testIsExpired_expiryDate_inPast() {
        let data = """
            {
              "expiryDate" : "1955-11-05T06:00:00Z",
              "payload" : {
                "key" : "key",
                "maxAge" : 3600,
                "value" : "value"
              }
            }
        """.data(using: .utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let payload = try? decoder.decode(StoreResponsePayload.self, from: data!) else {
            XCTFail("Failed to decode StoreResponsePayload.")
            return
        }

        print(Date().timeIntervalSince1970)
        print(payload.expiryDate.timeIntervalSince1970)
        XCTAssertTrue(payload.isExpired)
    }
}

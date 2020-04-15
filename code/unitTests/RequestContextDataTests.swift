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

class RequestContextDataTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: encoder tests
    
    func testEncode_noParameters() {
        let context = RequestContextData()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(context)
        
        XCTAssertNotNil(data)
        let expected = """
            {

            }
            """
        let jsonString = String(data: data!, encoding: .utf8)
        
        XCTAssertEqual(expected, jsonString)
    }
    
    func testEncode_paramIdentityMap() {
        let context = RequestContextData(identityMap: IdentityMap())
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try? encoder.encode(context)
        
        XCTAssertNotNil(data)
        let expected = """
            {
              "identityMap" : {

              }
            }
            """
        let jsonString = String(data: data!, encoding: .utf8)
        
        XCTAssertEqual(expected, jsonString)
    }
    
    // MARK: decoder tests
      
      func testDecode_noParameters() {
         let data = """
         {

         }
         """.data(using: .utf8)
         
         let decoder = JSONDecoder()
         decoder.dateDecodingStrategy = .iso8601
         
         let context = try? decoder.decode(RequestContextData.self, from: data!)
         
         XCTAssertNotNil(context)
         XCTAssertNil(context!.identityMap)
      }
     
    func testDecode_paramIdentityMap() {
       let data = """
       {
         "identityMap" : { }
       }
       """.data(using: .utf8)
       
       let decoder = JSONDecoder()
       decoder.dateDecodingStrategy = .iso8601
       
       let context = try? decoder.decode(RequestContextData.self, from: data!)
       
       XCTAssertNotNil(context)
       XCTAssertNotNil(context!.identityMap)
    }
    
    func testDecode_validAndUnknownParams_decodeValidParams() {
       let data = """
       {
         "unknown" : [ ],
         "identityMap" : { }
       }
       """.data(using: .utf8)
       
       let decoder = JSONDecoder()
       decoder.dateDecodingStrategy = .iso8601
       
       let context = try? decoder.decode(RequestContextData.self, from: data!)
       
       XCTAssertNotNil(context)
       XCTAssertNotNil(context!.identityMap)
    }
    
    func testDecode_unknownParams_decodeEmptyObject() {
       let data = """
       {
         "unknown" : [ ]
       }
       """.data(using: .utf8)
       
       let decoder = JSONDecoder()
       decoder.dateDecodingStrategy = .iso8601
       
       let context = try? decoder.decode(RequestContextData.self, from: data!)
       
       XCTAssertNotNil(context)
       XCTAssertNil(context!.identityMap)
    }
}

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

class IdentityMapTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: encoder tests
    
    func testIdentityMap_encode_oneItem() {
        var identityMap = IdentityMap()
        identityMap.addItem(namespace: "space", id: "id", state: AuthenticationState.ambiguous, primary: false)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try? encoder.encode(identityMap)
        
        XCTAssertNotNil(data)
        let expected = """
            {
              "space" : [
                {
                  "authenticationState" : "ambiguous",
                  "id" : "id",
                  "primary" : false
                }
              ]
            }
            """
        let jsonString = String(data: data!, encoding: .utf8)
        XCTAssertEqual(expected, jsonString)
    }
    
    func testIdentityMap_encode_twoItems() {
        var identityMap = IdentityMap()
        identityMap.addItem(namespace: "space", id: "id", state: AuthenticationState.ambiguous, primary: false)
        identityMap.addItem(namespace: "A", id: "123")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try? encoder.encode(identityMap)
        
        XCTAssertNotNil(data)
        let expected = """
            {
              "A" : [
                {
                  "id" : "123"
                }
              ],
              "space" : [
                {
                  "authenticationState" : "ambiguous",
                  "id" : "id",
                  "primary" : false
                }
              ]
            }
            """
        let jsonString = String(data: data!, encoding: .utf8)
        XCTAssertEqual(expected, jsonString)
    }
    
    func testIdentityMap_encode_twoItemsSameNamespace() {
        var identityMap = IdentityMap()
        identityMap.addItem(namespace: "space", id: "id", state: AuthenticationState.ambiguous, primary: false)
        identityMap.addItem(namespace: "space", id: "123")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try? encoder.encode(identityMap)
        
        XCTAssertNotNil(data)
        let expected = """
            {
              "space" : [
                {
                  "authenticationState" : "ambiguous",
                  "id" : "id",
                  "primary" : false
                },
                {
                  "id" : "123"
                }
              ]
            }
            """
        let jsonString = String(data: data!, encoding: .utf8)        
        XCTAssertEqual(expected, jsonString)
    }
    
    // MARK: decoder tests
    
    func testIdentityMap_decode_oneItem() {
        let data = """
            {
              "space" : [
                {
                  "authenticationState" : "ambiguous",
                  "id" : "id",
                  "primary" : false
                }
              ]
            }
        """.data(using: .utf8)
        let decoder = JSONDecoder()
        
        let identityMap = try? decoder.decode(IdentityMap.self, from: data!)
        XCTAssertNotNil(identityMap)
        let items = identityMap!.getItemsFor(namespace: "space")
        XCTAssertNotNil(items)
        XCTAssertEqual(1, items.count)
        XCTAssertEqual("id", items[0].id)
        XCTAssertEqual("ambiguous", items[0].state?.rawValue)
        XCTAssertFalse(items[0].primary!)
    }
    
    func testIdentityMap_decode_twoItems() {
        let data = """
             {
               "A" : [
                 {
                   "id" : "123"
                 }
               ],
               "space" : [
                 {
                   "authenticationState" : "ambiguous",
                   "id" : "id",
                   "primary" : false
                 }
               ]
             }
         """.data(using: .utf8)
        let decoder = JSONDecoder()
        
        let identityMap = try? decoder.decode(IdentityMap.self, from: data!)
        XCTAssertNotNil(identityMap)
        let spaceItems = identityMap!.getItemsFor(namespace: "space")
        XCTAssertNotNil(spaceItems)
        XCTAssertEqual(1, spaceItems.count)
        XCTAssertEqual("id", spaceItems[0].id)
        XCTAssertEqual("ambiguous", spaceItems[0].state?.rawValue)
        XCTAssertFalse(spaceItems[0].primary!)
        
        let aItems = identityMap!.getItemsFor(namespace: "A")
        XCTAssertNotNil(aItems)
        XCTAssertEqual("123", aItems[0].id)
        XCTAssertNil(aItems[0].state)
        XCTAssertNil(aItems[0].primary)
    }
    
    func testIdentityMap_decode_twoItemsSameNamespace() {
        let data = """
             {
               "space" : [
                 {
                   "authenticationState" : "ambiguous",
                   "id" : "id",
                   "primary" : false
                 },
                 {
                   "id" : "123"
                 }
               ]
             }
         """.data(using: .utf8)
        let decoder = JSONDecoder()
        
        let identityMap = try? decoder.decode(IdentityMap.self, from: data!)
        XCTAssertNotNil(identityMap)
        
        let spaceItems = identityMap!.getItemsFor(namespace: "space")
        XCTAssertNotNil(spaceItems)
        XCTAssertEqual(2, spaceItems.count)
        XCTAssertEqual("id", spaceItems[0].id)
        XCTAssertEqual("ambiguous", spaceItems[0].state?.rawValue)
        XCTAssertFalse(spaceItems[0].primary!)
        
        XCTAssertEqual("123", spaceItems[1].id)
        XCTAssertNil(spaceItems[1].state)
        XCTAssertNil(spaceItems[1].primary)
    }
}

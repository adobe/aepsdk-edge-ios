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
    
    // MARK: getItemsFor tests
    
    func testGetItemsFor() {
        var identityMap = IdentityMap()
        identityMap.addItem(namespace: "space", id: "id", state: AuthenticationState.ambiguous, primary: false)
        
        let spaceItems = identityMap.getItemsFor(namespace: "space")
        XCTAssertNotNil(spaceItems)
        XCTAssertEqual(1, spaceItems!.count)
        XCTAssertEqual("id", spaceItems![0].id)
        XCTAssertEqual("ambiguous", spaceItems![0].state?.rawValue)
        XCTAssertFalse(spaceItems![0].primary!)
        
        let unknown = identityMap.getItemsFor(namespace: "unknown")
        XCTAssertNil(unknown)
    }
    
    func testAddItems() {
        var identityMap = IdentityMap()
        identityMap.addItem(namespace: "space", id: "id", state: AuthenticationState.ambiguous, primary: false)
        identityMap.addItem(namespace: "email", id: "example@adobe.com")
        identityMap.addItem(namespace: "space", id: "custom", state: AuthenticationState.ambiguous, primary: true)
        
        guard let spaceItems = identityMap.getItemsFor(namespace: "space") else {
            XCTFail("Namespace 'space' is nil but expected not nil.")
            return
        }
        
        XCTAssertEqual(2, spaceItems.count)
        XCTAssertEqual("id", spaceItems[0].id)
        XCTAssertEqual(AuthenticationState.ambiguous, spaceItems[0].state)
        XCTAssertFalse(spaceItems[0].primary!)
        XCTAssertEqual("custom", spaceItems[1].id)
        XCTAssertEqual(AuthenticationState.ambiguous, spaceItems[1].state)
        XCTAssertTrue(spaceItems[1].primary!)
        
        guard let emailItems = identityMap.getItemsFor(namespace: "email") else {
             XCTFail("Namespace 'email' is nil but expected not nil.")
             return
         }
        
        XCTAssertEqual(1, emailItems.count)
        XCTAssertEqual("example@adobe.com", emailItems[0].id)
    }
    
    func testAddItems_overwrite() {
        var identityMap = IdentityMap()
        identityMap.addItem(namespace: "space", id: "id", state: AuthenticationState.ambiguous, primary: false)
        identityMap.addItem(namespace: "space", id: "id", state: AuthenticationState.authenticated)
        
        guard let spaceItems = identityMap.getItemsFor(namespace: "space") else {
            XCTFail("Namespace 'space' is nil but expected not nil.")
            return
        }
        
        XCTAssertEqual(1, spaceItems.count)
        XCTAssertEqual("id", spaceItems[0].id)
        XCTAssertEqual(AuthenticationState.authenticated, spaceItems[0].state)
        XCTAssertNil(spaceItems[0].primary)
    }
    
    // MARK: encoder tests
    
    func testEncode_oneItem() {
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
    
    func testEncode_twoItems() {
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
    
    func testEncode_twoItemsSameNamespace() {
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
    
    func testDecode_oneItem() {
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
        guard let items = identityMap!.getItemsFor(namespace: "space") else {
            XCTFail("Namespace 'space' is nil but expected not nil.")
            return
        }

        XCTAssertEqual(1, items.count)
        XCTAssertEqual("id", items[0].id)
        XCTAssertEqual("ambiguous", items[0].state?.rawValue)
        XCTAssertFalse(items[0].primary!)
    }
    
    func testDecode_twoItems() {
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
        guard let spaceItems = identityMap!.getItemsFor(namespace: "space") else {
            XCTFail("Namespace 'space' is nil but expected not nil.")
            return
        }

        XCTAssertEqual(1, spaceItems.count)
        XCTAssertEqual("id", spaceItems[0].id)
        XCTAssertEqual("ambiguous", spaceItems[0].state?.rawValue)
        XCTAssertFalse(spaceItems[0].primary!)
        
        guard let aItems = identityMap!.getItemsFor(namespace: "A") else {
            XCTFail("Namespace 'A' is nil but expected not nil.")
            return
        }

        XCTAssertEqual("123", aItems[0].id)
        XCTAssertNil(aItems[0].state)
        XCTAssertNil(aItems[0].primary)
    }
    
    func testDecode_twoItemsSameNamespace() {
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
        
        guard let spaceItems = identityMap!.getItemsFor(namespace: "space") else {
            XCTFail("Namespace 'space' is nil but expected not nil.")
            return
        }
        
        XCTAssertEqual(2, spaceItems.count)
        XCTAssertEqual("id", spaceItems[0].id)
        XCTAssertEqual("ambiguous", spaceItems[0].state?.rawValue)
        XCTAssertFalse(spaceItems[0].primary!)
        
        XCTAssertEqual("123", spaceItems[1].id)
        XCTAssertNil(spaceItems[1].state)
        XCTAssertNil(spaceItems[1].primary)
    }
    
    func testDecode_unknownParamsInIdentityItem() {
         let data = """
              {
                "space" : [
                  {
                    "authenticationState" : "ambiguous",
                    "id" : "id",
                    "unknown" : true,
                    "primary" : false
                  }
                ]
              }
          """.data(using: .utf8)
         let decoder = JSONDecoder()
         
         let identityMap = try? decoder.decode(IdentityMap.self, from: data!)
         XCTAssertNotNil(identityMap)
         
         guard let spaceItems = identityMap!.getItemsFor(namespace: "space") else {
            XCTFail("Namespace 'space' is nil but expected not nil.")
            return
         }
        
         XCTAssertEqual(1, spaceItems.count)
         XCTAssertEqual("id", spaceItems[0].id)
         XCTAssertEqual("ambiguous", spaceItems[0].state?.rawValue)
         XCTAssertFalse(spaceItems[0].primary!)
     }
    
    func testDecode_emptyJson() {
         let data = """
              {
              }
          """.data(using: .utf8)
         let decoder = JSONDecoder()
         
         let identityMap = try? decoder.decode(IdentityMap.self, from: data!)
         XCTAssertNotNil(identityMap)
     }
}

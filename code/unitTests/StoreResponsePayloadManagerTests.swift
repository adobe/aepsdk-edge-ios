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

class StoreResponsePayloadManagerTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK:

    func testGetActiveStores_isCorrect_whenRecordsInDataStore() {
        let manager = StoreResponsePayloadManager(MockKeyValueStore())
        manager.saveStorePayloads(buildStorePayloads())
        XCTAssertEqual(2, manager.getActiveStores().count)
    }
    
    func testGetActiveStores_evictsExpiredKey_whenCurrentDatePassesExpiry() {
        let manager = StoreResponsePayloadManager(MockKeyValueStore())
        manager.saveStorePayloads(buildStorePayloads())
        XCTAssertEqual(2, manager.getActiveStores().count)
        sleep(3)
        XCTAssertEqual(1, manager.getActiveStores().count)
    }
    
    func testGetActivePayloadList_returnsList_whenRecordsInDataStore() {
        let manager = StoreResponsePayloadManager(MockKeyValueStore())
        manager.saveStorePayloads(buildStorePayloads())
        let payloads = manager.getActivePayloadList()
        XCTAssertEqual(2, payloads.count)
    }
    
    func testSaveStorePayloads_savesPayloads_whenValid() {
        let manager = StoreResponsePayloadManager(MockKeyValueStore())
        manager.saveStorePayloads(buildStorePayloads())
        XCTAssertEqual(2, manager.getActiveStores().count)
    }
    
    func testSaveStorePayloads_overwritesPayloads_whenDuplicateKeys() {
        let manager = StoreResponsePayloadManager(MockKeyValueStore())
        manager.saveStorePayloads(buildStorePayloads())
        manager.saveStorePayloads(buildStorePayloads())
        XCTAssertEqual(2, manager.getActiveStores().count)
    }
    
    func testSaveStorePayloads_maxAgeLessThanOne_isRemoved() {
        let manager = StoreResponsePayloadManager(MockKeyValueStore())
        manager.saveStorePayloads([StoreResponsePayload(key: "key", value: "value", maxAgeSeconds: 3600)])
        XCTAssertEqual(1, manager.getActiveStores().count)
        manager.saveStorePayloads([StoreResponsePayload(key: "key", value: "value", maxAgeSeconds: -1)])
        XCTAssertEqual(0, manager.getActiveStores().count)
    }
    
    func testSaveStorePayloads_overwritesPayloads_whenDuplicateKeysAndNewValues() {
        let manager = StoreResponsePayloadManager(MockKeyValueStore())
        manager.saveStorePayloads(buildStorePayloads())

        let originalPayloads = manager.getActiveStores()
        
        // new payloads use same keys as original payloads
        var newPayloads: [StoreResponsePayload] = []
        newPayloads.append(StoreResponsePayload(key: "kndctr_53A16ACB5CC1D3760A495C99_AdobeOrg_optout",
                                             value: "general=false",
                                            maxAgeSeconds: 8000))
        newPayloads.append(StoreResponsePayload(key: "kndctr_53A16ACB5CC1D3760A495C99_AdobeOrg_optin",
                                             value: "newValue",
                                             maxAgeSeconds: 10))
        
        // overwrite and update
        manager.saveStorePayloads(newPayloads)
        
        let activePayloads = manager.getActiveStores()
        XCTAssertEqual(2, activePayloads.count)
        
        if let p1 = activePayloads["kndctr_53A16ACB5CC1D3760A495C99_AdobeOrg_optout"] {
            XCTAssertEqual("kndctr_53A16ACB5CC1D3760A495C99_AdobeOrg_optout", p1.payload.key)
            XCTAssertEqual("general=false", p1.payload.value)
            XCTAssertEqual(8000, p1.payload.maxAge)
            XCTAssertTrue(p1.expiryDate > originalPayloads[p1.payload.key]?.expiryDate ?? Date())
        } else {
            XCTFail("Failed to get payload with key kndctr_53A16ACB5CC1D3760A495C99_AdobeOrg_optout from active stores.")
        }
        
        if let p2 = activePayloads["kndctr_53A16ACB5CC1D3760A495C99_AdobeOrg_optin"] {
            XCTAssertEqual("kndctr_53A16ACB5CC1D3760A495C99_AdobeOrg_optin", p2.payload.key)
            XCTAssertEqual("newValue", p2.payload.value)
            XCTAssertEqual(10, p2.payload.maxAge)
            XCTAssertTrue(p2.expiryDate > originalPayloads[p2.payload.key]?.expiryDate ?? Date())
        } else {
            XCTFail("Failed to get payload with key kndctr_53A16ACB5CC1D3760A495C99_AdobeOrg_optin from active stores.")
        }
    }
    
    func buildStorePayloads() -> [StoreResponsePayload] {
        var payloads: [StoreResponsePayload] = []
        
        payloads.append(StoreResponsePayload(key: "kndctr_53A16ACB5CC1D3760A495C99_AdobeOrg_optout",
                                             value: "general=true",
                                            maxAgeSeconds: 7200))
        payloads.append(StoreResponsePayload(key: "kndctr_53A16ACB5CC1D3760A495C99_AdobeOrg_optin",
                                             value: "",
                                             maxAgeSeconds: 2))
        return payloads
    }

}

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
import AEPServices
import XCTest

class StoreResponsePayloadManagerTests: XCTestCase {
    let testDataStoreName = "StoreResponsePayloadManagerTests"
    let storePayloadsDataStoreKey = "storePayloads"

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false // fail so nil checks stop execution
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        ServiceProvider.shared.namedKeyValueService.remove(collectionName: testDataStoreName, key: storePayloadsDataStoreKey)
    }

    func testGetActiveStores_isCorrect_whenRecordsInDataStore() {
        let manager = StoreResponsePayloadManager(testDataStoreName)
        manager.saveStorePayloads(buildStorePayloads())
        XCTAssertEqual(2, manager.getActiveStores().count)
    }

    func testGetActiveStores_evictsExpiredKey_whenCurrentDatePassesExpiry() {
        let manager = StoreResponsePayloadManager(testDataStoreName)
        manager.saveStorePayloads(buildStorePayloads())
        XCTAssertEqual(2, manager.getActiveStores().count)
        sleep(3)
        XCTAssertEqual(1, manager.getActiveStores().count)
    }

    func testGetActivePayloadList_returnsList_whenRecordsInDataStore() {
        let manager = StoreResponsePayloadManager(testDataStoreName)
        manager.saveStorePayloads(buildStorePayloads())
        let payloads = manager.getActivePayloadList()
        XCTAssertEqual(2, payloads.count)
    }

    func testSaveStorePayloads_savesPayloads_whenValid() {
        let manager = StoreResponsePayloadManager(testDataStoreName)
        manager.saveStorePayloads(buildStorePayloads())
        XCTAssertEqual(2, manager.getActiveStores().count)
    }

    func testSaveStorePayloads_overwritesPayloads_whenDuplicateKeys() {
        let manager = StoreResponsePayloadManager(testDataStoreName)
        manager.saveStorePayloads(buildStorePayloads())
        manager.saveStorePayloads(buildStorePayloads())
        XCTAssertEqual(2, manager.getActiveStores().count)
    }

    func testSaveStorePayloads_maxAgeLessThanOne_isRemoved() {
        let manager = StoreResponsePayloadManager(testDataStoreName)
        manager.saveStorePayloads([StoreResponsePayload(payload: StorePayload(key: "key", value: "value", maxAge: 3600))])
        XCTAssertEqual(1, manager.getActiveStores().count)
        manager.saveStorePayloads([StoreResponsePayload(payload: StorePayload(key: "key", value: "value", maxAge: -1))])
        XCTAssertEqual(0, manager.getActiveStores().count)
    }

    func testSaveStorePayloads_overwritesPayloads_whenDuplicateKeysAndNewValues() {
        let manager = StoreResponsePayloadManager(testDataStoreName)
        manager.saveStorePayloads(buildStorePayloads())

        let originalPayloads = manager.getActiveStores()

        // new payloads use same keys as original payloads
        var newPayloads: [StoreResponsePayload] = []
        newPayloads.append(StoreResponsePayload(payload: StorePayload(key: "kndctr_testOrg_AdobeOrg_optout",
                                                                      value: "general=false",
                                                                      maxAge: 8000)))
        newPayloads.append(StoreResponsePayload(payload: StorePayload(key: "kndctr_testOrg_AdobeOrg_optin",
                                                                      value: "newValue",
                                                                      maxAge: 10)))

        // overwrite and update
        manager.saveStorePayloads(newPayloads)

        let activePayloads = manager.getActiveStores()
        XCTAssertEqual(2, activePayloads.count)

        if let payload1 = activePayloads["kndctr_testOrg_AdobeOrg_optout"] {
            XCTAssertEqual("kndctr_testOrg_AdobeOrg_optout", payload1.payload.key)
            XCTAssertEqual("general=false", payload1.payload.value)
            XCTAssertEqual(8000, payload1.payload.maxAge)
            XCTAssertTrue(payload1.expiryDate > originalPayloads[payload1.payload.key]?.expiryDate ?? Date())
        } else {
            XCTFail("Failed to get payload with key kndctr_testOrg_AdobeOrg_optout from active stores.")
        }

        if let payload2 = activePayloads["kndctr_testOrg_AdobeOrg_optin"] {
            XCTAssertEqual("kndctr_testOrg_AdobeOrg_optin", payload2.payload.key)
            XCTAssertEqual("newValue", payload2.payload.value)
            XCTAssertEqual(10, payload2.payload.maxAge)
            XCTAssertTrue(payload2.expiryDate > originalPayloads[payload2.payload.key]?.expiryDate ?? Date())
        } else {
            XCTFail("Failed to get payload with key kndctr_testOrg_AdobeOrg_optin from active stores.")
        }
    }

    func testDeleteStorePayloads_whenStoredValues_deletesAll() {
        let manager = StoreResponsePayloadManager(testDataStoreName)
        manager.saveStorePayloads(buildStorePayloads())

        var storePayloads = ServiceProvider.shared.namedKeyValueService.get(collectionName: testDataStoreName, key: storePayloadsDataStoreKey)
        XCTAssertNotNil(storePayloads)

        // test
        manager.deleteAllStorePayloads()
        XCTAssertTrue(manager.getActiveStores().isEmpty)
        storePayloads = ServiceProvider.shared.namedKeyValueService.get(collectionName: testDataStoreName, key: storePayloadsDataStoreKey)
        XCTAssertNil(storePayloads)
    }

    func testDeleteAllStorePayloads_whenNoStoredValues_deletesAll() {
        let manager = StoreResponsePayloadManager(testDataStoreName)
        var storePayloads = ServiceProvider.shared.namedKeyValueService.get(collectionName: testDataStoreName, key: storePayloadsDataStoreKey)
        XCTAssertNil(storePayloads)

        // test
        manager.deleteAllStorePayloads()
        XCTAssertTrue(manager.getActiveStores().isEmpty)
        storePayloads = ServiceProvider.shared.namedKeyValueService.get(collectionName: testDataStoreName, key: storePayloadsDataStoreKey)
        XCTAssertNil(storePayloads)
    }

    func testDeleteAllStorePayloads_whenDataStoreIsNull_doesNotCrash() {
        XCTAssertNoThrow(StoreResponsePayloadManager("").deleteAllStorePayloads())
    }

    func buildStorePayloads() -> [StoreResponsePayload] {
        var payloads: [StoreResponsePayload] = []

        payloads.append(StoreResponsePayload(payload: StorePayload(key: "kndctr_testOrg_AdobeOrg_optout",
                                                                   value: "general=true",
                                                                   maxAge: 7200)))
        payloads.append(StoreResponsePayload(payload: StorePayload(key: "kndctr_testOrg_AdobeOrg_optin",
                                                                   value: "",
                                                                   maxAge: 2)))
        return payloads
    }
}

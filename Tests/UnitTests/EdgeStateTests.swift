//
// Copyright 2022 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPCore
@testable import AEPEdge
import AEPServices
import XCTest

class EdgeStateTests: XCTestCase {
    let experienceEvent = Event(name: "Experience event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["data": "example"]])
    var edgeState: EdgeState!
    var mockDataQueue: MockDataQueue!
    var mockHitProcessor: MockHitProcessor!

    var mockDataStore: MockDataStore {
        return ServiceProvider.shared.namedKeyValueService as! MockDataStore
    }

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        mockDataQueue = MockDataQueue()
        mockHitProcessor = MockHitProcessor()

        edgeState = EdgeState(hitQueue: PersistentHitQueue(dataQueue: mockDataQueue, processor: mockHitProcessor),
                              edgeProperties: EdgeProperties())
    }

    func testBootupIfNeeded_loadsEdgePropertiesFromPersistence_andCreatesSharedState_withLocationHint() {
        var storedProperties = EdgeProperties()
        XCTAssertTrue(storedProperties.setLocationHint(hint: "or2", ttlSeconds: 100))
        storedProperties.saveToPersistence()

        guard let expectedExpiryDate = storedProperties.locationHintExpiryDate else {
            XCTFail("Failed to setup test with stored properties. Expiry Date not set.")
            return
        }

        let expectation = XCTestExpectation(description: "createSharedState callback")
        edgeState.bootupIfNeeded(event: experienceEvent,
                                 getSharedState: {_, _, _ in return nil },
                                 createSharedState: { data, _ in
                                    // Verify shared state is created with correct location hint value
                                    XCTAssertEqual("or2", data[EdgeConstants.SharedState.Edge.LOCATION_HINT] as? String)
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 1)

        // Verify Edge Properties loaded correct location hint and expiry date
        XCTAssertEqual("or2", edgeState.edgeProperties.locationHint)
        XCTAssertEqual(expectedExpiryDate.timeIntervalSince1970, edgeState.edgeProperties.locationHintExpiryDate?.timeIntervalSince1970 ?? 0)
    }

    func testBootupIfNeeded_loadsEdgePropertiesFromPersistence_andCreatesSharedState_withExpiredLocationHint() {
        var storedProperties = EdgeProperties()
        XCTAssertTrue(storedProperties.setLocationHint(hint: "or2", ttlSeconds: 1))
        storedProperties.saveToPersistence()

        guard let expectedExpiryDate = storedProperties.locationHintExpiryDate else {
            XCTFail("Failed to setup test with stored properties. Expiry Date not set.")
            return
        }

        sleep(1)

        let expectation = XCTestExpectation(description: "createSharedState callback")
        edgeState.bootupIfNeeded(event: experienceEvent,
                                 getSharedState: {_, _, _ in return nil },
                                 createSharedState: { data, _ in
                                    // Verify shared state is created but without location hint value as it expired
                                    XCTAssertNil(data[EdgeConstants.SharedState.Edge.LOCATION_HINT] as? String)
                                    expectation.fulfill()
                                 })

        wait(for: [expectation], timeout: 1)

        // Verify Edge Properties loaded correct location hint and expiry date
        // Location Hint is expired so returns nil, but expiry date isn't cleared
        XCTAssertNil(edgeState.edgeProperties.locationHint)
        XCTAssertEqual(expectedExpiryDate.timeIntervalSince1970, edgeState.edgeProperties.locationHintExpiryDate?.timeIntervalSince1970 ?? 0)
    }

    func testGetLocationHint_returnsHint_forValidHint() {
        XCTAssertTrue(edgeState.edgeProperties.setLocationHint(hint: "or2", ttlSeconds: 100))
        XCTAssertEqual("or2", edgeState.getLocationHint())
    }

    func testGetLocationHint_returnsNil_forExpiredHint() {
        XCTAssertTrue(edgeState.edgeProperties.setLocationHint(hint: "or2", ttlSeconds: 1))
        sleep(1)
        XCTAssertNil(edgeState.getLocationHint())
    }

    func testSetLocationHint_updatesHintAndExpiryDate_andSharesState() {
        let expectation = XCTestExpectation(description: "createSharedState callback")
        let expectedExpiryDate = Date() + 100
        edgeState.setLocationHint(hint: "or2", ttlSeconds: 100, createSharedState: {data, _ in
            // Verify shared state is created with new location hint
            XCTAssertEqual("or2", data[EdgeConstants.SharedState.Edge.LOCATION_HINT] as? String)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)

        // Verify Edge Properties updated with correct location hint and expiry date
        XCTAssertEqual("or2", edgeState.edgeProperties.locationHint)
        XCTAssertEqual(expectedExpiryDate.timeIntervalSince1970, edgeState.edgeProperties.locationHintExpiryDate?.timeIntervalSince1970 ?? 0, accuracy: 2)

        // Verify Edge Properties stored in data store
        guard let storedProps = getPropertiesFromMockDataStore() else {
            XCTFail("Failed to read EdgeProperties from MockDataStore.")
            return
        }

        XCTAssertEqual("or2", storedProps.locationHint)
        XCTAssertEqual(expectedExpiryDate.timeIntervalSince1970, storedProps.locationHintExpiryDate?.timeIntervalSince1970 ?? 0, accuracy: 2)
    }

    func testSetLocationHint_updatesHintAndExpiryDate_andDoesNotShareState_whenHintDoesNotChange() {
        // Set a previous Hint and Date
        XCTAssertTrue(edgeState.edgeProperties.setLocationHint(hint: "or2", ttlSeconds: 10))

        let expectedExpiryDate = Date() + 1000
        edgeState.setLocationHint(hint: "or2", ttlSeconds: 1000, createSharedState: {_, _ in
            XCTFail("Shared state not expected.")
        })

        sleep(1) // short wait to verify shared state is not called, as EdgeState uses async dispatch queue

        // Verify Edge Properties updated with correct location hint and expiry date
        XCTAssertEqual("or2", edgeState.edgeProperties.locationHint)
        XCTAssertEqual(expectedExpiryDate.timeIntervalSince1970, edgeState.edgeProperties.locationHintExpiryDate?.timeIntervalSince1970 ?? 0, accuracy: 2)

        // Verify Edge Properties stored in data store
        guard let storedProps = getPropertiesFromMockDataStore() else {
            XCTFail("Failed to read EdgeProperties from MockDataStore.")
            return
        }

        XCTAssertEqual("or2", storedProps.locationHint)
        XCTAssertEqual(expectedExpiryDate.timeIntervalSince1970, storedProps.locationHintExpiryDate?.timeIntervalSince1970 ?? 0, accuracy: 2)
    }

    func testSetLocationHint_updatesHintAndExpiryDate_andSharesState_whenHintHasExpired() {
        // Set a previous Hint and Date
        XCTAssertTrue(edgeState.edgeProperties.setLocationHint(hint: "or2", ttlSeconds: 1))

        sleep(1) // wait for hint to expire

        // Set hint to same value and verify shared state is created, as previous hint expired
        let expectation = XCTestExpectation(description: "createSharedState callback")
        let expectedExpiryDate = Date() + 100
        edgeState.setLocationHint(hint: "or2", ttlSeconds: 100, createSharedState: {data, _ in
            // Verify shared state is created with new location hint
            XCTAssertEqual("or2", data[EdgeConstants.SharedState.Edge.LOCATION_HINT] as? String)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)

        // Verify Edge Properties updated with correct location hint and expiry date
        XCTAssertEqual("or2", edgeState.edgeProperties.locationHint)
        XCTAssertEqual(expectedExpiryDate.timeIntervalSince1970, edgeState.edgeProperties.locationHintExpiryDate?.timeIntervalSince1970 ?? 0, accuracy: 2)

        // Verify Edge Properties stored in data store
        guard let storedProps = getPropertiesFromMockDataStore() else {
            XCTFail("Failed to read EdgeProperties from MockDataStore.")
            return
        }

        XCTAssertEqual("or2", storedProps.locationHint)
        XCTAssertEqual(expectedExpiryDate.timeIntervalSince1970, storedProps.locationHintExpiryDate?.timeIntervalSince1970 ?? 0, accuracy: 2)
    }

    func testClearLocationHint_clearsHintAndExpiryDate_andCreatesSharedState() {
        // Set a previous Hint and Date
        XCTAssertTrue(edgeState.edgeProperties.setLocationHint(hint: "or2", ttlSeconds: 100))

        let expectation = XCTestExpectation(description: "createSharedState callback")
        edgeState.clearLocationHint(createSharedState: {data, _ in
            // Verify shared state is created without location hint as hint value changed
            XCTAssertNil(data[EdgeConstants.SharedState.Edge.LOCATION_HINT] as? String)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)

        // Verify Edge Properties clears location hint and expiry date
        XCTAssertNil(edgeState.edgeProperties.locationHint)
        XCTAssertNil(edgeState.edgeProperties.locationHintExpiryDate)

        // Verify Edge Properties clears hint in data store
        guard let storedProps = getPropertiesFromMockDataStore() else {
            XCTFail("Failed to read EdgeProperties from MockDataStore.")
            return
        }

        XCTAssertNil(storedProps.locationHint)
        XCTAssertNil(storedProps.locationHintExpiryDate)
    }

    func testClearLocationHint_whenNoHitSet_doesNotCreateSharedState() {
        // Clear hint, but as no previous hint is set (hint == nil) then no shared state is created
        edgeState.clearLocationHint(createSharedState: {_, _ in
            XCTFail("Shared state not expected.")
        })

        sleep(1) // short wait to verify shared state is not called, as EdgeState uses async dispatch queue
    }

    func testClearLocationHint_clearsHintAndExpiryDate_andCreatesSharedState_whenHintHasExpired() {
        // Set a previous Hint and Date
        XCTAssertTrue(edgeState.edgeProperties.setLocationHint(hint: "or2", ttlSeconds: 1))

        sleep(1) // wait for hint to expire

        // Clear hint and verify shared state is created even though previous hint expired
        let expectation = XCTestExpectation(description: "createSharedState callback")
        edgeState.clearLocationHint(createSharedState: {data, _ in
            // Verify shared state is created with not location hint
            XCTAssertNil(data[EdgeConstants.SharedState.Edge.LOCATION_HINT] as? String)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 1)

        // Verify Edge Properties updated with correct location hint and expiry date
        XCTAssertNil(edgeState.edgeProperties.locationHint)
        XCTAssertNil(edgeState.edgeProperties.locationHintExpiryDate)

        // Verify Edge Properties stored in data store
        guard let storedProps = getPropertiesFromMockDataStore() else {
            XCTFail("Failed to read EdgeProperties from MockDataStore.")
            return
        }

        XCTAssertNil(storedProps.locationHint)
        XCTAssertNil(storedProps.locationHintExpiryDate)
    }

    /// Helper to read `EdgeProperties` from `MockDataStore`.
    /// - Returns: EdgeProperties from MockDataStore under key "edge.properties", or nil if no value found or an error occurred while reading properties.
    private func getPropertiesFromMockDataStore() -> EdgeProperties? {
        guard let data = mockDataStore.dict["edge.properties"] as? Data else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(EdgeProperties.self, from: data)
    }

}

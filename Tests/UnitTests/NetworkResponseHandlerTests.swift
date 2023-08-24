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

import AEPCore
@testable import AEPEdge
import XCTest

class NetworkResponseHandlerTests: XCTestCase {
    private var networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (_: String?, _: TimeInterval?) -> Void in  })
    private let event1 = Event(name: "e1", type: "eventType", source: "eventSource", data: nil)
    private let event2 = Event(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private let event3 = Event(name: "e3", type: "eventType", source: "eventSource", data: nil)

    override func setUp() {
        continueAfterFailure = false // fail so nil checks stop execution
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (_: String?, _: TimeInterval?) -> Void in  })
    }

    // MARK: addWaitingEvents, getWaitingEvents, removeWaitingEvents
    func testAddWaitingEvents_addsNewList_happy() {
        let requestId = "test"
        let eventsList: [Event] = [event1, event2]

        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: eventsList)
        guard let result = networkResponseHandler.getWaitingEvents(requestId: requestId), result.count == 2 else {
            XCTFail("Waiting events list was empty, should contain two events")
            return
        }

        XCTAssertEqual(event1.id.uuidString, result[0].id.uuidString)
        XCTAssertEqual(event2.id.uuidString, result[1].id.uuidString)
    }

    func testAddWaitingEvents_skips_whenEmptyRequestId() {
        let eventsList: [Event] = [event1, event2]

        networkResponseHandler.addWaitingEvents(requestId: "", batchedEvents: eventsList)
        let result = networkResponseHandler.getWaitingEvents(requestId: "")

        XCTAssertNil(result)
    }

    func testAddWaitingEvents_skips_whenEmptyList() {
        let requestId = "test"

        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [])
        let result = networkResponseHandler.getWaitingEvents(requestId: requestId)

        XCTAssertNil(result)
    }

    func testAddWaitingEvents_overrides_existingRequestId() {
        let requestId = "test"

        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event1, event2])
        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event3])
        guard let result = networkResponseHandler.getWaitingEvents(requestId: requestId), result.count == 1 else {
            XCTFail("Waiting events list was empty, should contain one event - e3")
            return
        }

        XCTAssertEqual(event3.id.uuidString, result[0].id.uuidString)
    }

    func testRemoveWaitingEvents_removesByRequestId() {
        let requestId1 = "test1"
        let requestId2 = "test2"

        networkResponseHandler.addWaitingEvents(requestId: requestId1, batchedEvents: [event1, event2])
        networkResponseHandler.addWaitingEvents(requestId: requestId2, batchedEvents: [event3])
        guard let result = networkResponseHandler.removeWaitingEvents(requestId: requestId2), result.count == 1 else {
            XCTFail("Removed events list was empty, should contain one event id - e3")
            return
        }

        XCTAssertEqual(event3.id.uuidString, result[0].id.uuidString)
        XCTAssertNil(networkResponseHandler.getWaitingEvents(requestId: requestId2))
        guard let result2 = networkResponseHandler.getWaitingEvents(requestId: requestId1), result2.count == 2 else {
            XCTFail("Waiting events list was empty, should contain two events - e1, e2")
            return
        }
    }

    func testRemoveWaitingEvents_returnsNil_whenEmptyRequestId() {
        let requestId = "test"

        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [event1, event2])
        XCTAssertNil(networkResponseHandler.removeWaitingEvents(requestId: ""))
        guard let result = networkResponseHandler.getWaitingEvents(requestId: requestId), result.count == 2 else {
            XCTFail("Waiting events list was empty, should contain two events - e1, e2")
            return
        }
    }

    func testRemoveWaitingEvents_returnsNil_whenNotKnownRequestId() {
        let requestId1 = "test1"
        let requestId2 = "test2"

        networkResponseHandler.addWaitingEvents(requestId: requestId1, batchedEvents: [event1, event2])
        XCTAssertNil(networkResponseHandler.removeWaitingEvents(requestId: requestId2))
        guard let result = networkResponseHandler.getWaitingEvents(requestId: requestId1), result.count == 2 else {
            XCTFail("Waiting events list was empty, should contain two events - e1, e2")
            return
        }
    }

    func testAddRemoveWaitingEvents_noConcurrencyCrash_whenCalledFromDifferentThreads() {
        let requestId = "test"
        let dispatchQueue1 = DispatchQueue(label: "test.queue1", attributes: .concurrent)
        let dispatchQueue2 = DispatchQueue(label: "test.queue2", attributes: .concurrent)
        let expectation = self.expectation(description: "Add/Remove multithreaded calls")
        expectation.expectedFulfillmentCount = 100
        expectation.assertForOverFulfill = true

        for _ in 1...100 {
            let rand = Int.random(in: 1..<100)
            if rand % 2 == 0 {
                dispatchQueue1.async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    XCTAssertNoThrow(self.networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [self.event1, self.event2]))
                    expectation.fulfill()
                }
            } else {
                dispatchQueue2.async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    XCTAssertNoThrow(self.networkResponseHandler.removeWaitingEvents(requestId: requestId))
                    expectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 2) { (error: Error?) in
            if error != nil {
                XCTFail("Test timed out before all expectations were fullfilled")
            }
        }
    }
}

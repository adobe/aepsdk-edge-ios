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

import XCTest
import ACPCore
@testable import ACPExperiencePlatform

class NetworkResponseHandlerTests: XCTestCase {
    private var networkResponseHandler = NetworkResponseHandler()
    private let e1 = try! ACPExtensionEvent(name: "e1", type: "eventType", source: "eventSource", data: nil)
    private let e2 = try! ACPExtensionEvent(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private let e3 = try! ACPExtensionEvent(name: "e3", type: "eventType", source: "eventSource", data: nil)
    
    override func setUp() {
        continueAfterFailure = false // fail so nil checks stop execution
        networkResponseHandler = NetworkResponseHandler()
    }
    
    func testAddWaitingEvents_addsNewList_happy() {
        let requestId = "test"
        let eventsList: [ACPExtensionEvent] = [e1, e2]
        
        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: eventsList)
        guard let result = networkResponseHandler.getWaitingEvents(requestId: requestId), result.count == 2 else {
            XCTFail("Waiting events list was empty, should contain two events")
            return
        }
        
        XCTAssertEqual(e1.eventUniqueIdentifier, result[0])
        XCTAssertEqual(e2.eventUniqueIdentifier, result[1])
    }
    
    func testAddWaitingEvents_skips_whenEmptyRequestId() {
        let eventsList: [ACPExtensionEvent] = [e1, e2]
        
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
        
        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [e1, e2])
        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [e3])
        guard let result = networkResponseHandler.getWaitingEvents(requestId: requestId), result.count == 1 else {
            XCTFail("Waiting events list was empty, should contain one event - e3")
            return
        }
        
        XCTAssertEqual(e3.eventUniqueIdentifier, result[0])
    }
    
    func testRemoveWaitingEvents_removesByRequestId() {
        let requestId1 = "test1"
        let requestId2 = "test2"
        
        networkResponseHandler.addWaitingEvents(requestId: requestId1, batchedEvents: [e1, e2])
        networkResponseHandler.addWaitingEvents(requestId: requestId2, batchedEvents: [e3])
        guard let result = networkResponseHandler.removeWaitingEvents(requestId: requestId2), result.count == 1 else {
            XCTFail("Removed events list was empty, should contain one event id - e3")
            return
        }
        
        XCTAssertEqual(e3.eventUniqueIdentifier, result[0])
        XCTAssertNil(networkResponseHandler.getWaitingEvents(requestId: requestId2))
        guard let result2 = networkResponseHandler.getWaitingEvents(requestId: requestId1), result2.count == 2 else {
            XCTFail("Waiting events list was empty, should contain two events - e1, e2")
            return
        }
    }
    
    func testRemoveWaitingEvents_returnsNil_whenEmptyRequestId() {
        let requestId = "test"
        
        networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [e1, e2])
        XCTAssertNil(networkResponseHandler.removeWaitingEvents(requestId: ""))
        guard let result = networkResponseHandler.getWaitingEvents(requestId: requestId), result.count == 2 else {
            XCTFail("Waiting events list was empty, should contain two events - e1, e2")
            return
        }
    }
    
    func testRemoveWaitingEvents_returnsNil_whenNotKnownRequestId() {
        let requestId1 = "test1"
        let requestId2 = "test2"
        
        networkResponseHandler.addWaitingEvents(requestId: requestId1, batchedEvents: [e1, e2])
        XCTAssertNil(networkResponseHandler.removeWaitingEvents(requestId: requestId2))
        guard let result = networkResponseHandler.getWaitingEvents(requestId: requestId1), result.count == 2 else {
            XCTFail("Waiting events list was empty, should contain two events - e1, e2")
            return
        }
    }
    
    func testAddRemoveWaitingEvents_noConcurrencyCrash_whenCalledFromDifferentThreads() {
        let requestId = "test"
        let dispatchQueue = DispatchQueue(label: "test.queue", attributes: .concurrent)
        let expectation = XCTestExpectation(description: "Add/Remove multithreaded calls")
        expectation.expectedFulfillmentCount = 100
        expectation.assertForOverFulfill = true
        
        for _ in 1...100 {
            let rand = Int.random(in: 1..<100)
            if rand % 2 == 0 {
                dispatchQueue.async { [weak self] in
                    guard let self = self else {
                      return
                    }
                    XCTAssertNoThrow(self.networkResponseHandler.addWaitingEvents(requestId: requestId, batchedEvents: [self.e1, self.e2]))
                    expectation.fulfill()
                }
            } else {
                dispatchQueue.async { [weak self] in
                    guard let self = self else {
                      return
                    }
                    XCTAssertNoThrow(self.networkResponseHandler.removeWaitingEvents(requestId: requestId))
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 2.0) // Wait until the expectation is fulfilled, timeout of 2 seconds
    }
}

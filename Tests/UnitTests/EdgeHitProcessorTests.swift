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
import AEPServices
import XCTest

class EdgeHitProcessorTests: XCTestCase {
    var hitProcessor: EdgeHitProcessor!
    var networkService: EdgeNetworkService!
    var networkResponseHandler: NetworkResponseHandler!
    var mockNetworkService: MockNetworking? {
        return ServiceProvider.shared.networkService as? MockNetworking
    }

    override func setUp() {
        ServiceProvider.shared.networkService = MockNetworking()
        networkService = EdgeNetworkService()
        networkResponseHandler = NetworkResponseHandler()
        hitProcessor = EdgeHitProcessor(networkService: networkService, networkResponseHandler: networkResponseHandler)
    }

    /// Tests that when a `DataEntity` with bad data is passed, that it is not retried and is removed from the queue
    func testProcessHitBadHit() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should not be retried")
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: nil) // entity data does not contain an `EdgeHit`

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertFalse(mockNetworkService?.connectAsyncCalled ?? true) // no network request should have been made
    }

    /// Tests that when a good hit is processed that a network request is made and the request returns 200
    func testProcessHitHappy() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should not be retried")
        guard let expectedUrl = URL(string: "adobe.com") else { XCTFail("Could not create URL"); return }
        let expectedEvent = Event(name: "Hit Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        let expectedHeaders = ["testHeaderKey": "testHeaderVal"]
        let expectedRequest = EdgeRequest(meta: nil, xdm: nil, events: nil)
        let hit = EdgeHit(url: expectedUrl, request: expectedRequest, headers: expectedHeaders, event: expectedEvent)

        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: expectedUrl, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(hit))

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(mockNetworkService?.connectAsyncCalled ?? false) // network request should have been made
        XCTAssertEqual(mockNetworkService?.connectAsyncCalledWithNetworkRequest?.url, expectedUrl) // network request should be made with the url in the hit
    }

    /// Tests that when the network request fails but has a recoverable error that we will retry the hit and do not invoke the response handler for that hit
    func testProcessHitRecoverableNetworkError() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should be retried")
        guard let expectedUrl = URL(string: "adobe.com") else { XCTFail("Could not create URL"); return }
        let expectedEvent = Event(name: "Hit Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        let expectedHeaders = ["testHeaderKey": "testHeaderVal"]
        let expectedRequest = EdgeRequest(meta: nil, xdm: nil, events: nil)
        let hit = EdgeHit(url: expectedUrl, request: expectedRequest, headers: expectedHeaders, event: expectedEvent)

        let edgeResponse = EdgeResponse(requestId: "test-req-id", handle: nil, errors: [EdgeEventError(eventIndex: 0, message: "test-err", code: "502", namespace: nil)], warnings: nil)
        let responseData = try? JSONEncoder().encode(edgeResponse)

        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: responseData, response: HTTPURLResponse(url: expectedUrl, statusCode: 502, httpVersion: nil, headerFields: nil), error: nil)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(hit))

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertFalse(success)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(mockNetworkService?.connectAsyncCalled ?? false) // network request should have been made
        XCTAssertEqual(mockNetworkService?.connectAsyncCalledWithNetworkRequest?.url, expectedUrl) // network request should be made with the url in the hit
    }

    /// Tests that when the network request fails and does not have a recoverable response code that we invoke the response handler and do not retry the hit
    func testProcessHitUnrecoverableNetworkError() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should not be retried")
        guard let expectedUrl = URL(string: "adobe.com") else { XCTFail("Could not create URL"); return }
        let expectedEvent = Event(name: "Hit Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        let expectedHeaders = ["testHeaderKey": "testHeaderVal"]
        let expectedRequest = EdgeRequest(meta: nil, xdm: nil, events: nil)
        let hit = EdgeHit(url: expectedUrl, request: expectedRequest, headers: expectedHeaders, event: expectedEvent)
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: expectedUrl, statusCode: -1, httpVersion: nil, headerFields: nil), error: nil)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(hit))

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(mockNetworkService?.connectAsyncCalled ?? false) // network request should have been made
        XCTAssertEqual(mockNetworkService?.connectAsyncCalledWithNetworkRequest?.url, expectedUrl) // network request should be made with the url in the hit
    }
}

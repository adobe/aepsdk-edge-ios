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

@testable import AEPCore
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

    let expectedHeaders = [Constants.NetworkKeys.HEADER_KEY_AEP_VALIDATION_TOKEN: "test-int-id"]

    override func setUp() {
        ServiceProvider.shared.networkService = MockNetworking()
        networkService = EdgeNetworkService()
        networkResponseHandler = NetworkResponseHandler()
        hitProcessor = EdgeHitProcessor(networkService: networkService, networkResponseHandler: networkResponseHandler, getSharedState: { _, _ -> SharedStateResult? in
            return SharedStateResult(status: .set, value: [Constants.SharedState.Assurance.INTEGRATION_ID: "test-int-id"])
        })
    }

    /// Tests that when a `DataEntity` with bad data is passed, that it is not retried and is removed from the queue
    func testProcessHit_badHit_decodeFails() {
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
    func testProcessHit_happy_sendsNetworkRequest_returnsTrue() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should not be retried")
        let expectedConfigId = "test-config-id"
        let expectedReqId = "test-req-id"
        let expectedEvent = Event(name: "Hit Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        let expectedRequest = EdgeRequest(meta: nil, xdm: nil, events: nil)
        let hit = EdgeHit(configId: expectedConfigId, requestId: expectedReqId, request: expectedRequest, event: expectedEvent)
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: URL(string: "adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(hit))

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(mockNetworkService?.connectAsyncCalled ?? false) // network request should have been made
    }

    /// Tests that when the network request fails but has a recoverable error that we will retry the hit and do not invoke the response handler for that hit
    func testProcessHit_whenRecoverableNetworkError_sendsNetworkRequest_returnsFalse() {
        // setup
        let recoverableNetworkErrorCodes = [HttpResponseCodes.clientTimeout.rawValue,
                                                           HttpResponseCodes.tooManyRequests.rawValue,
                                                           HttpResponseCodes.serviceUnavailable.rawValue,
                                                           HttpResponseCodes.gatewayTimeout.rawValue]

        let expectation = XCTestExpectation(description: "Callback should be invoked with false signaling this hit should be retried")
        expectation.expectedFulfillmentCount = recoverableNetworkErrorCodes.count
        let expectedConfigId = "test-config-id"
        let expectedReqId = "test-req-id"
        let expectedEvent = Event(name: "Hit Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        let expectedRequest = EdgeRequest(meta: nil, xdm: nil, events: nil)
        let hit = EdgeHit(configId: expectedConfigId, requestId: expectedReqId, request: expectedRequest, event: expectedEvent)

        for code in recoverableNetworkErrorCodes {
            let edgeResponse = EdgeResponse(requestId: "test-req-id", handle: nil, errors: [EdgeEventError(eventIndex: 0, message: "test-err", code: "\(code)", namespace: nil)], warnings: nil)
            let responseData = try? JSONEncoder().encode(edgeResponse)

            mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: responseData, response: HTTPURLResponse(url: URL(string: "adobe.com")!, statusCode: code, httpVersion: nil, headerFields: nil), error: nil)

            let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(hit))

            // test
            hitProcessor.processHit(entity: entity) { success in
                XCTAssertFalse(success)
                expectation.fulfill()
            }
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(mockNetworkService?.connectAsyncCalled ?? false) // network request should have been made
    }

    /// Tests that when the network request fails and does not have a recoverable response code that we invoke the response handler and do not retry the hit
    func testProcessHit_whenUnrecoverableNetworkError_sendsNetworkRequest_returnsTrue() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should not be retried")
        let expectedConfigId = "test-config-id"
        let expectedReqId = "test-req-id"
        let expectedEvent = Event(name: "Hit Event", type: EventType.identity, source: EventSource.requestIdentity, data: nil)
        let expectedRequest = EdgeRequest(meta: nil, xdm: nil, events: nil)
        let hit = EdgeHit(configId: expectedConfigId, requestId: expectedReqId, request: expectedRequest, event: expectedEvent)
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: URL(string: "adobe.com")!, statusCode: -1, httpVersion: nil, headerFields: nil), error: nil)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(hit))

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(mockNetworkService?.connectAsyncCalled ?? false) // network request should have been made
    }
}

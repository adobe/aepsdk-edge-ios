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
    private let ASSURANCE_SHARED_STATE = "com.adobe.assurance"
    private let CONFIGURATION_SHARED_STATE = "com.adobe.module.configuration"
    private let IDENTITY_SHARED_STATE = "com.adobe.module.identity"
    private let ASSURANCE_INTEGRATION_ID = "integrationid"
    private let EDGE_CONFIG_ID = "edge.configId"
    var hitProcessor: EdgeHitProcessor!
    var networkService: EdgeNetworkService!
    var networkResponseHandler: NetworkResponseHandler!
    var mockNetworkService: MockNetworking? {
        return ServiceProvider.shared.networkService as? MockNetworking
    }
    let expectedHeaders = ["X-Adobe-AEP-Validation-Token": "test-int-id"]

    override func setUp() {
        ServiceProvider.shared.networkService = MockNetworking()
        networkService = EdgeNetworkService()
        networkResponseHandler = NetworkResponseHandler(getPrivacyStatus: { () -> PrivacyStatus in
            return PrivacyStatus.optedIn
        })
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: resolveSharedState(extensionName:event:),
                                        getXDMSharedState: resolveXDMSharedState(extensionName:event:),
                                        readyForEvent: readyForEvent(_:))
    }

    private func resolveSharedState(extensionName: String, event: Event?) -> SharedStateResult? {
        if extensionName == ASSURANCE_SHARED_STATE {
            return SharedStateResult(status: .set, value: [ASSURANCE_INTEGRATION_ID: "test-int-id"])
        }

        if extensionName == CONFIGURATION_SHARED_STATE {
            return SharedStateResult(status: .set, value: [EDGE_CONFIG_ID: "test-config-id"])
        }

        return nil
    }

    private func resolveXDMSharedState(extensionName: String, event: Event?) -> SharedStateResult? {
        if extensionName == IDENTITY_SHARED_STATE {
            guard let identityMapData = """
                {
                  "ECID" : [
                    {
                      "authenticationState" : "ambiguous",
                      "id" : "test-mcid",
                      "primary" : false
                    }
                  ]
                }
            """.data(using: .utf8) else {
                XCTFail("Failed to convert json string to data")
                return nil
            }
            let identityMap = try? JSONSerialization.jsonObject(with: identityMapData, options: []) as? [String: Any]

            return SharedStateResult(status: .set, value: identityMap)
        }

        return nil
    }

    private func readyForEvent(_ event: Event) -> Bool {
        return true
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

    /// Tests that when `readyForEvent` returns false that we retry the hit
    func testProcessHit_readyForEventReturnsFalse() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should be retried")
        let event = Event(name: "test-event", type: EventType.custom, source: EventSource.requestContent, data: nil)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(event))
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: resolveSharedState(extensionName:event:),
                                        getXDMSharedState: resolveXDMSharedState(extensionName:event:),
                                        readyForEvent: { _ -> Bool in
                                            return false
                                        })

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertFalse(success) // hit should be retried
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertFalse(mockNetworkService?.connectAsyncCalled ?? true) // no network request should have been made
    }

    /// Tests that when an nil configuration is provided that the hit is dropped
    func testProcessHit_nilConfiguration() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should not be retried")
        let event = Event(name: "test-event", type: EventType.custom, source: EventSource.requestContent, data: nil)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(event))
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: { extensionName, event -> SharedStateResult? in
                                            if extensionName == self.CONFIGURATION_SHARED_STATE {
                                                // simulate shared state with no edge config
                                                return SharedStateResult(status: .pending, value: nil)
                                            }
                                            return self.resolveSharedState(extensionName: extensionName, event: event)
                                        },
                                        getXDMSharedState: resolveXDMSharedState(extensionName:event:),
                                        readyForEvent: readyForEvent(_:))

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertFalse(mockNetworkService?.connectAsyncCalled ?? true) // no network request should have been made
    }

    /// Tests that when no edge config id is in configuration shared state that we drop the hit
    func testProcessHit_noEdgeConfigId() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should not be retried")
        let event = Event(name: "test-event", type: EventType.custom, source: EventSource.requestContent, data: nil)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(event))
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: { extensionName, event -> SharedStateResult? in
                                            if extensionName == self.CONFIGURATION_SHARED_STATE {
                                                // simulate shared state with no edge config
                                                return SharedStateResult(status: .set, value: [:])
                                            }
                                            return self.resolveSharedState(extensionName: extensionName, event: event)
                                        },
                                        getXDMSharedState: resolveXDMSharedState(extensionName:event:),
                                        readyForEvent: readyForEvent(_:))

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertFalse(mockNetworkService?.connectAsyncCalled ?? true) // no network request should have been made
    }

    /// Tests that when Identity shared state is not set that we drop the hit
    func testProcessHit_noIdentitySharedState() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should not be retried")
        let event = Event(name: "test-event", type: EventType.custom, source: EventSource.requestContent, data: nil)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(event))
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: resolveXDMSharedState(extensionName:event:),
                                        getXDMSharedState: { extensionName, event -> SharedStateResult? in
                                            if extensionName == self.IDENTITY_SHARED_STATE {
                                                // simulate pending Identity shared state
                                                return SharedStateResult(status: .pending, value: nil)
                                            }
                                            return self.resolveXDMSharedState(extensionName: extensionName, event: event)
                                        }, readyForEvent: readyForEvent(_:))

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertFalse(mockNetworkService?.connectAsyncCalled ?? true) // no network request should have been made
    }

    /// Tests that when Identity shared state does not contain ECID that we still process the hit
    func testProcessHit_noECID() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should not be retried")
        let event = Event(name: "test-event", type: EventType.custom, source: EventSource.requestContent, data: nil)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(event))
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: resolveSharedState(extensionName:event:),
                                        getXDMSharedState: { extensionName, event -> SharedStateResult? in
                                            if extensionName == self.IDENTITY_SHARED_STATE {
                                                // simulate pending Identity shared state
                                                return SharedStateResult(status: .set, value: [:])
                                            }
                                            return self.resolveXDMSharedState(extensionName: extensionName, event: event)
                                        }, readyForEvent: readyForEvent(_:))

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(mockNetworkService?.connectAsyncCalled ?? false) // network request should have been made
    }

    /// Tests that when a good hit is processed that a network request is made and the request returns 200
    func testProcessHit_happy_sendsNetworkRequest_returnsTrue() {
        // setup
        let expectation = XCTestExpectation(description: "Callback should be invoked with true signaling this hit should not be retried")
        let event = Event(name: "test-event", type: EventType.custom, source: EventSource.requestContent, data: nil)

        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: URL(string: "adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(event))

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
    func testProcessHit_whenRecoverableNetworkError_sendsNetworkRequest_returnsFalse_setsRetryInterval() {
        // setup
        let recoverableNetworkErrorCodes = [HttpResponseCodes.clientTimeout.rawValue,
                                            HttpResponseCodes.tooManyRequests.rawValue,
                                            HttpResponseCodes.serviceUnavailable.rawValue,
                                            HttpResponseCodes.gatewayTimeout.rawValue]

        let expectation = XCTestExpectation(description: "Callback should be invoked with false signaling this hit should be retried")
        expectation.expectedFulfillmentCount = recoverableNetworkErrorCodes.count
        let event = Event(name: "test-event", type: EventType.custom, source: EventSource.requestContent, data: nil)

        // (headerValue, actualRetryValue)
        let retryValues = [("60", 60.0), ("InvalidHeader", 5.0), ("", 5.0), ("1", 1.0)]

        for (code, retryValueTuple) in zip(recoverableNetworkErrorCodes, retryValues) {
            let error = EdgeEventError(title: "test-title", detail: nil, status: code, type: "test-type", eventIndex: 0, report: nil)
            let edgeResponse = EdgeResponse(requestId: "test-req-id", handle: nil, errors: [error], warnings: nil)
            let responseData = try? JSONEncoder().encode(edgeResponse)

            mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: responseData,
                                                                                  response: HTTPURLResponse(url: URL(string: "adobe.com")!,
                                                                                                            statusCode: code,
                                                                                                            httpVersion: nil,
                                                                                                            headerFields: ["Retry-After": retryValueTuple.0]),
                                                                                  error: nil)

            let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(event))

            // test
            hitProcessor.processHit(entity: entity) { success in
                XCTAssertFalse(success)
                XCTAssertEqual(self.hitProcessor.retryInterval(for: entity), retryValueTuple.1)
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
        let event = Event(name: "test-event", type: EventType.custom, source: EventSource.requestContent, data: nil)
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: URL(string: "adobe.com")!, statusCode: -1, httpVersion: nil, headerFields: nil), error: nil)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(event))

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

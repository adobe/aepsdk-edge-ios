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
    private let IDENTITY_SHARED_STATE = "com.adobe.edge.identity"
    private let ASSURANCE_INTEGRATION_ID = "integrationid"
    private let EDGE_CONFIG_ID = "edge.configId"
    private let CONSENT_ENDPOINT = "https://edge.adobedc.net/ee/v1/privacy/set-consent"
    private let INTERACT_ENDPOINT = "https://edge.adobedc.net/ee/v1/interact"
    var hitProcessor: EdgeHitProcessor!
    var networkService: EdgeNetworkService!
    var networkResponseHandler: NetworkResponseHandler!
    var mockNetworkService: MockNetworking? {
        return ServiceProvider.shared.networkService as? MockNetworking
    }
    let expectedHeaders = ["X-Adobe-AEP-Validation-Token": "test-int-id"]
    let experienceEvent = Event(name: "test-experience-event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["test": "data"]])
    let consentUpdateEvent = Event(name: "test-consent-event", type: EventType.edge, source: EventSource.updateConsent, data: ["consents": ["collect": ["val": "y"]]])
    let url = URL(string: "adobe.com")! // swiftlint:disable:this force_unwrapping

    override func setUp() {
        ServiceProvider.shared.networkService = MockNetworking()
        networkService = EdgeNetworkService()
        networkResponseHandler = NetworkResponseHandler()
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
                  "identityMap" : {
                    "ECID" : [
                      {
                        "authenticationState" : "ambiguous",
                        "id" : "test-ecid",
                        "primary" : false
                      }
                    ]
                  }
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
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: nil) // entity data does not contain an `EdgeHit`

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    /// Tests that when `readyForEvent` returns false that we retry the hit
    func testProcessHit_experienceEvent_readyForEventReturnsFalse() {
        // setup
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(experienceEvent))
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: resolveSharedState(extensionName:event:),
                                        getXDMSharedState: resolveXDMSharedState(extensionName:event:),
                                        readyForEvent: { _ -> Bool in
                                            return false
                                        })

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: false)
    }

    /// Tests that when an nil configuration is provided that the hit is dropped
    func testProcessHit_experienceEvent_nilConfiguration() {
        // setup
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(experienceEvent))
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
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    /// Tests that when no edge config id is in configuration shared state that we drop the hit
    func testProcessHit_experienceEvent_noEdgeConfigId() {
        // setup
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(experienceEvent))
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
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    /// Tests that when Identity shared state is not set that we drop the hit
    func testProcessHit_experienceEvent_noIdentitySharedState() {
        // setup
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(experienceEvent))
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
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    /// Tests that when Identity shared state does not contain ECID that we still process the hit
    func testProcessHit_experienceEvent_noECID() {
        // setup
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(experienceEvent))
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
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
    }

    /// Tests that when a good hit is processed that a network request is made and the request returns 200
    func testProcessHit_experienceEvent_happy_sendsNetworkRequest_returnsTrue() {
        // setup
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(experienceEvent))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
    }

    /// Tests that when the network request fails but has a recoverable error that we will retry the hit and do not invoke the response handler for that hit
    func testProcessHit_experienceEvent_whenRecoverableNetworkError_sendsNetworkRequest_returnsFalse_setsRetryInterval() {
        // setup
        let recoverableNetworkErrorCodes = [HttpResponseCodes.clientTimeout.rawValue,
                                            HttpResponseCodes.tooManyRequests.rawValue,
                                            HttpResponseCodes.serviceUnavailable.rawValue,
                                            HttpResponseCodes.gatewayTimeout.rawValue]

        let expectation = XCTestExpectation(description: "Callback should be invoked with false signaling this hit should be retried")
        expectation.expectedFulfillmentCount = recoverableNetworkErrorCodes.count

        // (headerValue, actualRetryValue)
        let retryValues = [("60", 60.0), ("InvalidHeader", 5.0), ("", 5.0), ("1", 1.0)]

        for (code, retryValueTuple) in zip(recoverableNetworkErrorCodes, retryValues) {
            let error = EdgeEventError(title: "test-title", detail: nil, status: code, type: "test-type", eventIndex: 0, report: nil)
            let edgeResponse = EdgeResponse(requestId: "test-req-id", handle: nil, errors: [error], warnings: nil)
            let responseData = try? JSONEncoder().encode(edgeResponse)

            mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: responseData,
                                                                                  response: HTTPURLResponse(url: url,
                                                                                                            statusCode: code,
                                                                                                            httpVersion: nil,
                                                                                                            headerFields: ["Retry-After": retryValueTuple.0]),
                                                                                  error: nil)

            let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(experienceEvent))

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
    func testProcessHit_experienceEvent_whenUnrecoverableNetworkError_sendsNetworkRequest_returnsTrue() {
        // setup
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: -1, httpVersion: nil, headerFields: nil), error: nil)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(experienceEvent))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
        XCTAssertTrue( (mockNetworkService?.connectAsyncCalledWithNetworkRequest?.url.absoluteString ?? "").starts(with: INTERACT_ENDPOINT))
    }

    func testProcessHit_experienceEvent_nilData_doesNotSendNetworkRequest_returnsTrue() {
        // setup
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(Event(name: "test-consent-event", type: EventType.edge, source: EventSource.updateConsent, data: nil)))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    func testProcessHit_experienceEvent_emptyPayloadDueToInvalidData_doesNotSendNetworkRequest_returnsTrue() {
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(Event(name: "test-experience-event", type: EventType.edge, source: EventSource.requestContent, data: [:])))
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    // MARK: - Consent Update
    func testProcessHit_consentUpdateEvent_happy_sendsNetworkRequest_returnsTrue() {
        // setup
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(consentUpdateEvent))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
        XCTAssertTrue( (mockNetworkService?.connectAsyncCalledWithNetworkRequest?.url.absoluteString ?? "").starts(with: CONSENT_ENDPOINT))
    }

    func testProcessHit_consentUpdateEvent_emptyData_doesNotSendNetworkRequest_returnsTrue() {
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(Event(name: "test-consent-event", type: EventType.edge, source: EventSource.updateConsent, data: nil)))
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    func testProcessHit_consentUpdateEvent_emptyPayloadDueToInvalidData_doesNotSendNetworkRequest_returnsTrue() {
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(Event(name: "test-consent-event", type: EventType.edge, source: EventSource.updateConsent, data: ["some": "consent"])))
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    func assertProcessHit(entity: DataEntity, sendsNetworkRequest: Bool, returns: Bool, line: UInt = #line) {
        let expectation = XCTestExpectation(description: "Callback should be invoked signaling if the hit was processed or not")

        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertEqual(returns, success, "Expected callback to be called with \(returns), but it was \(success)", line: line)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(sendsNetworkRequest, mockNetworkService?.connectAsyncCalled, "Expected network request to be \(sendsNetworkRequest), but it was \(mockNetworkService?.connectAsyncCalled ?? false)", line: line)
    }
}

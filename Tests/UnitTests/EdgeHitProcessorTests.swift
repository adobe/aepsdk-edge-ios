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
    // Configuration keys
    private let EDGE_CONFIG_ID = "edge.configId"
    private let EDGE_ENV = "edge.environment"
    private let EDGE_DOMAIN = "edge.domain"
    // Edge Endpoints
    private let CONSENT_ENDPOINT = "https://edge.adobedc.net/ee/v1/privacy/set-consent"
    private let CONSENT_ENDPOINT_PRE_PROD = "https://edge.adobedc.net/ee-pre-prd/v1/privacy/set-consent"
    private let CONSENT_ENDPOINT_INT = "https://edge-int.adobedc.net/ee/v1/privacy/set-consent"
    private let INTERACT_ENDPOINT_PROD = "https://edge.adobedc.net/ee/v1/interact"
    private let INTERACT_ENDPOINT_PRE_PROD = "https://edge.adobedc.net/ee-pre-prd/v1/interact"
    private let INTERACT_ENDPOINT_INT = "https://edge-int.adobedc.net/ee/v1/interact"

    private let CONSENT_ENDPOINT_LOCATION_HINT = "https://edge.adobedc.net/ee/lh1/v1/privacy/set-consent"
    private let CONSENT_ENDPOINT_PRE_PROD_LOCATION_HINT = "https://edge.adobedc.net/ee-pre-prd/lh1/v1/privacy/set-consent"
    private let CONSENT_ENDPOINT_INT_LOCATION_HINT = "https://edge-int.adobedc.net/ee/lh1/v1/privacy/set-consent"
    private let INTERACT_ENDPOINT_PROD_LOCATION_HINT = "https://edge.adobedc.net/ee/lh1/v1/interact"
    private let INTERACT_ENDPOINT_PRE_PROD_LOCATION_HINT = "https://edge.adobedc.net/ee-pre-prd/lh1/v1/interact"
    private let INTERACT_ENDPOINT_INT_LOCATION_HINT = "https://edge-int.adobedc.net/ee/lh1/v1/interact"

    private let MEDIA_ENDPOINT = "https://edge.adobedc.net/ee/va/v1/sessionstart"
    private let MEDIA_ENDPOINT_PRE_PROD = "https://edge.adobedc.net/ee-pre-prd/va/v1/sessionstart"
    private let MEDIA_ENDPOINT_INTEGRATION = "https://edge-int.adobedc.net/ee/va/v1/sessionstart"
    private let MEDIA_ENDPOINT_LOC_HINT = "https://edge.adobedc.net/ee/lh1/va/v1/sessionstart"
    private let MEDIA_ENDPOINT_PRE_PROD_LOC_HINT = "https://edge.adobedc.net/ee-pre-prd/lh1/va/v1/sessionstart"
    private let MEDIA_ENDPOINT_INT_LOC_HINT = "https://edge-int.adobedc.net/ee/lh1/va/v1/sessionstart"

    private static let CUSTOM_DOMAIN = "my.awesome.site"
    private static let CUSTOM_CONSENT_ENDPOINT = "https://\(CUSTOM_DOMAIN)/ee/v1/privacy/set-consent"
    private static let CUSTOM_CONSENT_ENDPOINT_PRE_PROD = "https://\(CUSTOM_DOMAIN)/ee-pre-prd/v1/privacy/set-consent"
    private static let CUSTOM_INTERACT_ENDPOINT_PROD = "https://\(CUSTOM_DOMAIN)/ee/v1/interact"
    private static let CUSTOM_INTERACT_ENDPOINT_PRE_PROD = "https://\(CUSTOM_DOMAIN)/ee-pre-prd/v1/interact"
    private static let CUSTOM_MEDIA_ENDPOINT_PROD = "https://\(CUSTOM_DOMAIN)/ee/va/v1/sessionstart"
    private static let CUSTOM_MEDIA_ENDPOINT_PRE_PROD = "https://\(CUSTOM_DOMAIN)/ee-pre-prd/va/v1/sessionstart"

    // getLocationHint function
    let locationHintClosure = { return "lh1" }

    var hitProcessor: EdgeHitProcessor!
    var networkService: EdgeNetworkService!
    var networkResponseHandler: NetworkResponseHandler!
    var mockNetworkService: MockNetworking? {
        return ServiceProvider.shared.networkService as? MockNetworking
    }
    let expectedHeaders = ["X-Adobe-AEP-Validation-Token": "test-int-id"]
    let experienceEvent = Event(name: "test-experience-event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["test": "data"]])
    let experienceEventWithOverwritePath = Event(name: "test-experience-event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["test": "data"], "request": ["path": "/va/v1/sessionstart"]])
    let experienceEventWithDatastreamIdOverride = Event(name: "test-experience-event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["test": "data"], "config": ["datastreamIdOverride": "test-datastream-id-override"]])

    let invalidPaths = [
        "/va/v1/sessionstart?query=value",
        "//va/v1/sessionstart",
        "/va/v1//sessionstart",
        "/va/v1/sessionstart/@test",
        nil,
        ""
    ]

    let validPaths = [
        "/va/v1/session-start",
        "/va/v1/session.start",
        "/va/v1/sessionSTART123",
        "/va/v1/session~start_123"
    ]

    let consentUpdateEvent = Event(name: "test-consent-event", type: EventType.edge, source: EventSource.updateConsent, data: ["consents": ["collect": ["val": "y"]]])
    let consentUpdateEventWithOverwritePath = Event(name: "test-consent-event", type: EventType.edge, source: EventSource.updateConsent, data: ["consents": ["collect": ["val": "y"]], "request": ["path": "va/v1/sessionstart"]])
    let url = URL(string: "adobe.com")! // swiftlint:disable:this force_unwrapping

    override func setUp() {
        ServiceProvider.shared.networkService = MockNetworking()
        networkService = EdgeNetworkService()
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (_: String?, _: TimeInterval?) -> Void in  })
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: resolveSharedState(extensionName:event:),
                                        getXDMSharedState: resolveXDMSharedState(extensionName:event:barrier:),
                                        readyForEvent: readyForEvent(_:),
                                        getImplementationDetails: { return nil },
                                        getLocationHint: { return nil })
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

    private func resolveXDMSharedState(extensionName: String, event: Event?, barrier: Bool) -> SharedStateResult? {
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
        let edgeEntity = EdgeDataEntity(event: experienceEvent, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: resolveSharedState(extensionName:event:),
                                        getXDMSharedState: resolveXDMSharedState(extensionName:event:barrier:),
                                        readyForEvent: { _ -> Bool in
                                            return false
                                        },
                                        getImplementationDetails: { return nil },
                                        getLocationHint: { return nil })

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: false)
    }

    /// Tests that when an nil configuration is provided that the hit is dropped
    func testProcessHit_experienceEvent_nilConfiguration() {
        // setup
        let edgeEntity = EdgeDataEntity(event: experienceEvent, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: { extensionName, event -> SharedStateResult? in
                                            if extensionName == self.CONFIGURATION_SHARED_STATE {
                                                // simulate shared state with no edge config
                                                return SharedStateResult(status: .pending, value: nil)
                                            }
                                            return self.resolveSharedState(extensionName: extensionName, event: event)
                                        },
                                        getXDMSharedState: resolveXDMSharedState(extensionName:event:barrier:),
                                        readyForEvent: readyForEvent(_:),
                                        getImplementationDetails: { return nil },
                                        getLocationHint: { return nil })

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    /// Tests that when no edge config id is in configuration shared state that we drop the hit
    func testProcessHit_experienceEvent_noEdgeConfigId() {
        // setup
        let edgeEntity = EdgeDataEntity(event: experienceEvent, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: { extensionName, event -> SharedStateResult? in
                                            if extensionName == self.CONFIGURATION_SHARED_STATE {
                                                // simulate shared state with no edge config
                                                return SharedStateResult(status: .set, value: [:])
                                            }
                                            return self.resolveSharedState(extensionName: extensionName, event: event)
                                        },
                                        getXDMSharedState: resolveXDMSharedState(extensionName:event:barrier:),
                                        readyForEvent: readyForEvent(_:),
                                        getImplementationDetails: { return nil },
                                        getLocationHint: { return nil })

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    /// Tests that when a good hit is processed that a network request is made and the request returns 200
    func testProcessHit_experienceEvent_happy_sendsNetworkRequest_returnsTrue() {
        // setup
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        let edgeEntity = EdgeDataEntity(event: experienceEvent, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
    }

    /// Tests that when a good hit is processed that a network request is made and the request returns 200
    func testProcessHit_experienceEvent_withDatastreamOverrideSet_sendsNetworkRequest_returnsTrue() {
        // setup
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        let edgeEntity = EdgeDataEntity(event: experienceEventWithDatastreamIdOverride, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
        let requestString = mockNetworkService?.connectAsyncCalledWithNetworkRequest?.url.absoluteString ?? ""
        XCTAssertFalse(requestString.contains("test-config-id"))
        XCTAssertTrue(requestString.contains("test-datastream-id-override"))

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
            let error = EdgeEventError(title: "test-title", detail: nil, status: code, type: "test-type", report: EdgeErrorReport(eventIndex: 0, errors: nil, requestId: nil, orgId: nil))
            let edgeResponse = EdgeResponse(requestId: "test-req-id", handle: nil, errors: [error], warnings: nil)
            let responseData = try? JSONEncoder().encode(edgeResponse)

            mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: responseData,
                                                                                  response: HTTPURLResponse(url: url,
                                                                                                            statusCode: code,
                                                                                                            httpVersion: nil,
                                                                                                            headerFields: ["Retry-After": retryValueTuple.0]),
                                                                                  error: nil)

            let edgeEntity = EdgeDataEntity(event: experienceEvent, identityMap: [:])
            let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

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

        let edgeEntity = EdgeDataEntity(event: experienceEvent, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
        XCTAssertTrue( (mockNetworkService?.connectAsyncCalledWithNetworkRequest?.url.absoluteString ?? "").starts(with: INTERACT_ENDPOINT_PROD))
    }

    /// Tests that when the configurable edge endpoint is empty in configuration shared state that we fallback to production endpoint
    func testProcessHit_experienceEvent_whenConfigEndpointEmpty() {
        // setup
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        let edgeEntity = EdgeDataEntity(event: experienceEvent, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
        XCTAssertTrue( (mockNetworkService?.connectAsyncCalledWithNetworkRequest?.url.absoluteString ?? "").starts(with: INTERACT_ENDPOINT_PROD))
    }

    /// Tests that when the configurable edge endpoint is invalid in configuration shared state that we fallback to production endpoint
    func testProcessHit_experienceEvent_whenConfigEndpointInvalid() {
        // setup
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: { extensionName, _ -> SharedStateResult? in
                                            if extensionName == self.CONFIGURATION_SHARED_STATE {
                                                return SharedStateResult(status: .set, value: [self.EDGE_CONFIG_ID: "test-config-id", self.EDGE_ENV: "invalid-env"])
                                            }

                                            return nil
                                        },
                                        getXDMSharedState: resolveXDMSharedState(extensionName:event:barrier:),
                                        readyForEvent: readyForEvent(_:),
                                        getImplementationDetails: { return nil },
                                        getLocationHint: { return nil })
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        let edgeEntity = EdgeDataEntity(event: experienceEvent, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
        XCTAssertTrue( (mockNetworkService?.connectAsyncCalledWithNetworkRequest?.url.absoluteString ?? "").starts(with: INTERACT_ENDPOINT_PROD))
    }

    func testProcessHit_mediaEdgeEvent_happy_withOverwritePath_whenConfigEndpointProduction_sendsNetworkRequestWithCustomPath() {
        assertNetworkRequestUrl(event: experienceEventWithOverwritePath, environment: "prod", domain: nil, expectedEndpoint: MEDIA_ENDPOINT)
    }

    func testProcessHit_mediaEdgeEvent_happy_withOverwritePath_whenConfigEndpointPreProduction_sendsNetworkRequestWithCustomPath() {
        assertNetworkRequestUrl(event: experienceEventWithOverwritePath, environment: "pre-prod", domain: nil, expectedEndpoint: MEDIA_ENDPOINT_PRE_PROD)
    }

    func testProcessHit_mediaEdgeEvent_happy_withOverwritePath_whenConfigEndpointIntegration_sendsNetworkRequestWithCustomPath() {
        assertNetworkRequestUrl(event: experienceEventWithOverwritePath, environment: "int", domain: nil, expectedEndpoint: MEDIA_ENDPOINT_INTEGRATION)
    }

    func testProcessHit_mediaEdgeEvent_happy_withOverwritePath_whenConfigEndpointProductionAndCustomDomain_sendsNetworkRequestWithCustomPath() {
        assertNetworkRequestUrl(event: experienceEventWithOverwritePath, environment: "prod", domain: EdgeHitProcessorTests.CUSTOM_DOMAIN, expectedEndpoint: EdgeHitProcessorTests.CUSTOM_MEDIA_ENDPOINT_PROD)
    }

    func testProcessHit_mediaEdgeEvent_happy_withOverwritePath_whenConfigEndpointPreProductionAndCustomDomain_sendsNetworkRequestWithCustomPath() {
        assertNetworkRequestUrl(event: experienceEventWithOverwritePath, environment: "pre-prod", domain: EdgeHitProcessorTests.CUSTOM_DOMAIN, expectedEndpoint: EdgeHitProcessorTests.CUSTOM_MEDIA_ENDPOINT_PRE_PROD)
    }

    func testProcessHit_mediaEdgeEvent_happy_withOverwritePath_whenConfigEndpointIntegrationAndCustomDomain_sendsNetworkRequestWithCustomPath() {
        assertNetworkRequestUrl(event: experienceEventWithOverwritePath, environment: "int", domain: EdgeHitProcessorTests.CUSTOM_DOMAIN, expectedEndpoint: MEDIA_ENDPOINT_INTEGRATION)
    }

    func testProcessHit_mediaEdgeEvent_happy_withOverwritePath_validPath_sendsNetworkRequestWithCustomPath() {
        for path in validPaths {
            let expEventValidPath = Event(name: "test-consent-event", type: EventType.edge, source: EventSource.requestContent, data: ["request": ["path": path]])

            let expectedEndpoint = "https://edge-int.adobedc.net/ee\(path)"
            assertNetworkRequestUrl(event: expEventValidPath, environment: "int", domain: EdgeHitProcessorTests.CUSTOM_DOMAIN, expectedEndpoint: expectedEndpoint)
        }

    }

    func testProcessHit_withOverwritePath_invalidPath_doesNotOverwriteThePath() {
        for path in invalidPaths {
            let expEventInvalidPath = Event(name: "test-consent-event", type: EventType.edge, source: EventSource.requestContent, data: ["request": ["path": path]])
            assertNetworkRequestUrl(event: expEventInvalidPath, environment: "prod", domain: nil, expectedEndpoint: INTERACT_ENDPOINT_PROD)
        }
    }

    func testProcessHit_consentUpdateEvent_withOverwritePath_doesNotOverwriteThePath() {
        assertNetworkRequestUrl(event: consentUpdateEventWithOverwritePath, environment: "prod", domain: nil, expectedEndpoint: CONSENT_ENDPOINT)
    }

    func testProcessHit_consentUpdateEvent_whenConfigEndpointProduction_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: consentUpdateEvent, environment: "prod", domain: nil, expectedEndpoint: CONSENT_ENDPOINT)
    }

    func testProcessHit_consentUpdateEvent_whenConfigEndpointPreProduction_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: consentUpdateEvent, environment: "pre-prod", domain: nil, expectedEndpoint: CONSENT_ENDPOINT_PRE_PROD)
    }

    func testProcessHit_consentUpdateEvent_whenConfigEndpointIntegration_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: consentUpdateEvent, environment: "int", domain: nil, expectedEndpoint: CONSENT_ENDPOINT_INT)
    }

    func testProcessHit_consentUpdateEvent_whenConfigEndpointProductionWithLocationHint_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: consentUpdateEvent, environment: "prod", domain: nil, expectedEndpoint: CONSENT_ENDPOINT_LOCATION_HINT, getLocationHint: locationHintClosure)
    }

    func testProcessHit_consentUpdateEvent_whenConfigEndpointPreProductionWithLocationHint_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: consentUpdateEvent, environment: "pre-prod", domain: nil, expectedEndpoint: CONSENT_ENDPOINT_PRE_PROD_LOCATION_HINT, getLocationHint: locationHintClosure)
    }

    func testProcessHit_consentUpdateEvent_whenConfigEndpointIntegrationWithLocationHint_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: consentUpdateEvent, environment: "int", domain: nil, expectedEndpoint: CONSENT_ENDPOINT_INT_LOCATION_HINT, getLocationHint: locationHintClosure)
    }

    func testProcessHit_consentUpdateEvent_whenConfigEndpointProductionAndCustomDomain_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: consentUpdateEvent, environment: "prod", domain: EdgeHitProcessorTests.CUSTOM_DOMAIN, expectedEndpoint: EdgeHitProcessorTests.CUSTOM_CONSENT_ENDPOINT)
    }

    func testProcessHit_consentUpdateEvent_whenConfigEndpointPreProductionAndCustomDomain_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: consentUpdateEvent, environment: "pre-prod", domain: EdgeHitProcessorTests.CUSTOM_DOMAIN, expectedEndpoint: EdgeHitProcessorTests.CUSTOM_CONSENT_ENDPOINT_PRE_PROD)
    }

    func testProcessHit_consentUpdateEvent_whenConfigEndpointIntegrationAndCustomDomain_hasCorrectEndpoint() {
        // Note, custom domains are not supported with the integration endpoint
        assertNetworkRequestUrl(event: consentUpdateEvent, environment: "int", domain: EdgeHitProcessorTests.CUSTOM_DOMAIN, expectedEndpoint: CONSENT_ENDPOINT_INT)
    }

    func testProcessHit_experienceEvent_whenConfigEndpointProduction_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: experienceEvent, environment: "prod", domain: nil, expectedEndpoint: INTERACT_ENDPOINT_PROD)
    }

    func testProcessHit_experienceEvent_whenConfigEndpointPreProduction_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: experienceEvent, environment: "pre-prod", domain: nil, expectedEndpoint: INTERACT_ENDPOINT_PRE_PROD)
    }

    func testProcessHit_experienceEvent_whenConfigEndpointIntegration_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: experienceEvent, environment: "int", domain: nil, expectedEndpoint: INTERACT_ENDPOINT_INT)
    }

    func testProcessHit_experienceEvent_whenConfigEndpointProductionWithLocationHint_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: experienceEvent, environment: "prod", domain: nil, expectedEndpoint: INTERACT_ENDPOINT_PROD_LOCATION_HINT, getLocationHint: locationHintClosure)
    }

    func testProcessHit_experienceEvent_whenConfigEndpointPreProductionWithLocationHint_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: experienceEvent, environment: "pre-prod", domain: nil, expectedEndpoint: INTERACT_ENDPOINT_PRE_PROD_LOCATION_HINT, getLocationHint: locationHintClosure)
    }

    func testProcessHit_experienceEvent_whenConfigEndpointIntegrationWithLocationHint_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: experienceEvent, environment: "int", domain: nil, expectedEndpoint: INTERACT_ENDPOINT_INT_LOCATION_HINT, getLocationHint: locationHintClosure)
    }

    func testProcessHit_experienceEvent_withOverwritePath_whenConfigEndpointProductionWithLocationHint_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: experienceEventWithOverwritePath, environment: "prod", domain: nil, expectedEndpoint: MEDIA_ENDPOINT_LOC_HINT, getLocationHint: locationHintClosure)
    }

    func testProcessHit_experienceEvent_withOverwritePath_whenConfigEndpointPreProductionWithLocationHint_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: experienceEventWithOverwritePath, environment: "pre-prod", domain: nil, expectedEndpoint: MEDIA_ENDPOINT_PRE_PROD_LOC_HINT, getLocationHint: locationHintClosure)
    }

    func testProcessHit_experienceEvent_withOverwritePath_whenConfigEndpointIntegrationWithLocationHint_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: experienceEventWithOverwritePath, environment: "int", domain: nil, expectedEndpoint: MEDIA_ENDPOINT_INT_LOC_HINT, getLocationHint: locationHintClosure)
    }

    func testProcessHit_experienceEvent_whenConfigEndpointProductionAndCustomDomain_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: experienceEvent, environment: "prod", domain: EdgeHitProcessorTests.CUSTOM_DOMAIN, expectedEndpoint: EdgeHitProcessorTests.CUSTOM_INTERACT_ENDPOINT_PROD)
    }

    func testProcessHit_experienceEvent_whenConfigEndpointPreProductionAndCustomDomain_hasCorrectEndpoint() {
        assertNetworkRequestUrl(event: experienceEvent, environment: "pre-prod", domain: EdgeHitProcessorTests.CUSTOM_DOMAIN, expectedEndpoint: EdgeHitProcessorTests.CUSTOM_INTERACT_ENDPOINT_PRE_PROD)
    }

    func testProcessHit_experienceEvent_whenConfigEndpointIntegrationAndCustomDomain_hasCorrectEndpoint() {
        // Note, custom domains are not supported with the integration endpoint
        assertNetworkRequestUrl(event: experienceEvent, environment: "int", domain: EdgeHitProcessorTests.CUSTOM_DOMAIN, expectedEndpoint: INTERACT_ENDPOINT_INT)
    }

    func testProcessHit_experienceEvent_nilData_doesNotSendNetworkRequest_returnsTrue() {
        // setup
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)
        let event = Event(name: "test-consent-event", type: EventType.edge, source: EventSource.updateConsent, data: nil)
        let edgeEntity = EdgeDataEntity(event: event, identityMap: [:])

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    func testProcessHit_experienceEvent_emptyPayloadDueToInvalidData_doesNotSendNetworkRequest_returnsTrue() {
        let event = Event(name: "test-experience-event", type: EventType.edge, source: EventSource.requestContent, data: [:])
        let edgeEntity = EdgeDataEntity(event: event, identityMap: [:])

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    func testProcessHit_experienceEvent_addsEventToWaitingEventsList() {
        let edgeEntity = EdgeDataEntity(event: experienceEvent, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        let expectation = XCTestExpectation(description: "Callback should be invoked signaling if the hit was processed or not")
        // return recoverable error so the waiting event is not removed onComplete() before the assertion
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 408, httpVersion: nil, headerFields: nil), error: nil)

        // test
        hitProcessor.processHit(entity: entity) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        guard let requestUrl = mockNetworkService?.connectAsyncCalledWithNetworkRequest?.url else {
            XCTFail("unexpected nil request url")
            return
        }
        guard let requestId = requestUrl["requestId"] else {
            XCTFail("missing requestId in the request url")
            return
        }

        // verify
        let waitingEvents = networkResponseHandler.getWaitingEvents(requestId: requestId)
        XCTAssertEqual(1, waitingEvents?.count)
    }

    // MARK: - Consent Update
    func testProcessHit_consentUpdateEvent_happy_sendsNetworkRequest_returnsTrue() {
        // setup
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        let edgeEntity = EdgeDataEntity(event: consentUpdateEvent, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
        XCTAssertTrue( (mockNetworkService?.connectAsyncCalledWithNetworkRequest?.url.absoluteString ?? "").starts(with: CONSENT_ENDPOINT))
    }

    func testProcessHit_consentUpdateEvent_emptyData_doesNotSendNetworkRequest_returnsTrue() {
        let event = Event(name: "test-consent-event", type: EventType.edge, source: EventSource.updateConsent, data: nil)
        let edgeEntity = EdgeDataEntity(event: event, identityMap: [:])

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    func testProcessHit_consentUpdateEvent_emptyPayloadDueToInvalidData_doesNotSendNetworkRequest_returnsTrue() {
        let event = Event(name: "test-consent-event", type: EventType.edge, source: EventSource.updateConsent, data: ["some": "consent"])
        let edgeEntity = EdgeDataEntity(event: event, identityMap: [:])

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    func testProcessHit_consentUpdateEvent_addsEventToWaitingEventsList() {
        let edgeEntity = EdgeDataEntity(event: consentUpdateEvent, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        let expectation = XCTestExpectation(description: "Callback should be invoked signaling if the hit was processed or not")
        // return recoverable error so the waiting event is not removed onComplete() before the assertion
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 408, httpVersion: nil, headerFields: nil), error: nil)

        // test
        hitProcessor.processHit(entity: entity) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        guard let requestUrl = mockNetworkService?.connectAsyncCalledWithNetworkRequest?.url else {
            XCTFail("unexpected nil request url")
            return
        }
        guard let requestId = requestUrl["requestId"] else {
            XCTFail("missing requestId in the request url")
            return
        }

        // verify
        let waitingEvents = networkResponseHandler.getWaitingEvents(requestId: requestId)
        XCTAssertEqual(1, waitingEvents?.count)
    }

    func testProcessHit_resetIdentitiesEvent_clearsStateStore_returnsTrue() {
        let storeResponsePayloadManager = StoreResponsePayloadManager(EdgeConstants.DataStoreKeys.STORE_NAME)
        storeResponsePayloadManager.saveStorePayloads([StoreResponsePayload(payload: StorePayload(key: "key",
                                                                                                  value: "val",
                                                                                                  maxAge: 100000))])
        let event = Event(name: "test-reset-event",
                          type: EventType.genericIdentity,
                          source: EventSource.requestReset,
                          data: nil)
        let edgeEntity = EdgeDataEntity(event: event, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)

        XCTAssertTrue(storeResponsePayloadManager.getActiveStores().isEmpty)
    }

    // MARK: Implementation Details

    // tests Implementation Details added to Experience Events
    func testProcessHit_experienceEvent_sendsNetworkRequest_withImplementationDetails() {
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: resolveSharedState(extensionName:event:),
                                        getXDMSharedState: resolveXDMSharedState(extensionName:event:barrier:),
                                        readyForEvent: readyForEvent(_:),
                                        getImplementationDetails: {
                                            return [
                                                "name": "https://ns.adobe.com/experience/mobilesdk/ios",
                                                "environment": "app",
                                                "version": "3.3.1+1.0.0"
                                            ]
                                        },
                                        getLocationHint: { return nil })

        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        let edgeEntity = EdgeDataEntity(event: experienceEvent, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)

        guard let requestPayload = mockNetworkService?.connectAsyncCalledWithNetworkRequest?.connectPayload else {
            XCTFail("unexpected nil request connect payload")
            return
        }

        let payload = asFlattenDictionary(data: requestPayload)

        XCTAssertEqual("https://ns.adobe.com/experience/mobilesdk/ios", payload["xdm.implementationDetails.name"] as? String)
        XCTAssertEqual("3.3.1+1.0.0", payload["xdm.implementationDetails.version"] as? String)
        XCTAssertEqual("app", payload["xdm.implementationDetails.environment"] as? String)
    }

    // tests Implementation Details is not added to event when nil
    func testProcessHit_experienceEvent_sendsNetworkRequest_withoutImplementationDetails_whenNil() {
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: resolveSharedState(extensionName:event:),
                                        getXDMSharedState: resolveXDMSharedState(extensionName:event:barrier:),
                                        readyForEvent: readyForEvent(_:),
                                        getImplementationDetails: { return nil },
                                        getLocationHint: { return nil })

        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        let edgeEntity = EdgeDataEntity(event: experienceEvent, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)

        guard let requestPayload = mockNetworkService?.connectAsyncCalledWithNetworkRequest?.connectPayload else {
            XCTFail("unexpected nil request connect payload")
            return
        }

        let payload = asFlattenDictionary(data: requestPayload)

        XCTAssertNil(payload["xdm.implementationDetails.name"])
        XCTAssertNil(payload["xdm.implementationDetails.version"])
        XCTAssertNil(payload["xdm.implementationDetails.environment"])
    }

    // tests Implementation Details is not added to Consent events
    func testProcessHit_consentEvent_sendsNetworkRequest_withoutImplementationDetails() {
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: resolveSharedState(extensionName:event:),
                                        getXDMSharedState: resolveXDMSharedState(extensionName:event:barrier:),
                                        readyForEvent: readyForEvent(_:),
                                        getImplementationDetails: {
                                            return [
                                                "name": "https://ns.adobe.com/experience/mobilesdk/ios",
                                                "environment": "app",
                                                "version": "3.3.1+1.0.0"
                                            ]
                                        },
                                        getLocationHint: { return nil })

        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        let edgeEntity = EdgeDataEntity(event: consentUpdateEvent, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)

        guard let requestPayload = mockNetworkService?.connectAsyncCalledWithNetworkRequest?.connectPayload else {
            XCTFail("unexpected nil request connect payload")
            return
        }

        let payload = asFlattenDictionary(data: requestPayload)

        // Implementation Details are not added to Consent events
        XCTAssertNil(payload["xdm.implementationDetails.name"])
        XCTAssertNil(payload["xdm.implementationDetails.version"])
        XCTAssertNil(payload["xdm.implementationDetails.environment"])
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

    private func assertNetworkRequestUrl(event: Event, environment: String?, domain: String?, expectedEndpoint: String, getLocationHint: @escaping () -> String? = { return nil }) {
        var config: [String: Any] = [self.EDGE_CONFIG_ID: "test-config-id"]
        if let env = environment {
            config[self.EDGE_ENV] = env
        }
        if let domain = domain {
            config[self.EDGE_DOMAIN] = domain
        }

        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        getSharedState: { extensionName, _ -> SharedStateResult? in
                                            if extensionName == self.CONFIGURATION_SHARED_STATE {
                                                return SharedStateResult(status: .set, value: config)
                                            }

                                            return nil
                                        },
                                        getXDMSharedState: resolveXDMSharedState(extensionName:event:barrier:),
                                        readyForEvent: readyForEvent(_:),
                                        getImplementationDetails: { return nil },
                                        getLocationHint: getLocationHint)
        mockNetworkService?.connectAsyncMockReturnConnection = HttpConnection(data: "{}".data(using: .utf8), response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)

        let edgeEntity = EdgeDataEntity(event: event, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
        let actualUrl = mockNetworkService?.connectAsyncCalledWithNetworkRequest?.url.absoluteString ?? ""
        XCTAssertTrue( actualUrl.starts(with: expectedEndpoint))
    }
}

extension URL {
    subscript(queryParam: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParam })?.value
    }
}

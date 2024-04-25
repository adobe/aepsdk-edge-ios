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
import AEPTestUtils
import XCTest

class EdgeHitProcessorTests: XCTestCase, AnyCodableAsserts {
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
    private let mockNetworkService: MockNetworkService = MockNetworkService()
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

    // Mock for `getSharedState` closure in `EdgeHitProcessor`. Reassign variable in test to change behavior.
    private var mockGetSharedState: (String, Event?) -> SharedStateResult? = {extensionName, _ in
        if extensionName == "com.adobe.assurance" {
            return SharedStateResult(status: .set, value: [:])
        }
        XCTFail("Test called 'getSharedState(\(extensionName))' but was not expected.")
        return nil
    }

    // Mock for `readyForEvent` closure in `EdgeHitProcessor`. Reassign variable in test to change behavior.
    private var mockReadyForEvent: (Event) -> Bool = {_ in
        XCTFail("Test called 'readyForEvent' but was not expected.")
        return false
    }

    // Mock for `getImplementationDetails` closure in `EdgeHitProcessor`. Reassign variable in test to change behavior.
    private var mockGetImplementationDetails: () -> [String: Any]? = { return nil }

    // Mock for `getLocationHint` closure in `EdgeHitProcessor`. Reassign variable in test to change behavior.
    private var mockGetLocationHint: () -> String? = { return nil }

    // Default value for edge configuration containing required config ID
    private let defaultEdgeConfig: [String: String] = ["edge.configId": "test-config-id"]

    // Default value for identity map containing sample ECID
    private let defaultIdentityMap: [String: Any] =
        [
            "ECID": [
                ["id": "test-ecid", "authenticatedState": "ambiguous", "primary": false]
            ]
        ]

    override func setUp() {
        ServiceProvider.shared.networkService = mockNetworkService
        mockNetworkService.reset()
        networkService = EdgeNetworkService()
        networkResponseHandler = NetworkResponseHandler(updateLocationHint: { (_: String?, _: TimeInterval?) -> Void in  })
        hitProcessor = EdgeHitProcessor(networkService: networkService,
                                        networkResponseHandler: networkResponseHandler,
                                        sharedStateReader: SharedStateReader(getSharedState: {extensionName, event, _ in self.mockGetSharedState(extensionName, event)}),
                                        readyForEvent: {event in self.mockReadyForEvent(event)},
                                        getImplementationDetails: {self.mockGetImplementationDetails()},
                                        getLocationHint: {self.mockGetLocationHint()})
    }

    // MARK: - Tests

    /// Tests that when a `DataEntity` with bad data is passed, that it is not retried and is removed from the queue
    func testProcessHit_badHit_decodeFails() {
        // setup
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: nil) // entity data does not contain an `EdgeHit`

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    // MARK: - processHit with Experience Event

    /// Tests that when no edge config id is in configuration shared state that we drop the hit
    func testProcessHit_experienceEvent_noEdgeConfigId() {
        // setup
        let edgeEntity = getEdgeDataEntity(event: experienceEvent, configuration: ["edge.environment": "dev"], identityMap: defaultIdentityMap)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    /// Tests that when a good hit is processed that a network request is made and the request returns 200
    func testProcessHit_experienceEvent_happy_sendsNetworkRequest_returnsTrue() {
        // setup
        let edgeEntity = getEdgeDataEntity(event: experienceEvent, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
    }

    /// Tests that when a good hit is processed that a network request is made and the request returns 200
    func testProcessHit_experienceEvent_withDatastreamOverrideSet_sendsNetworkRequest_returnsTrue() {
        // setup
        let edgeEntity = getEdgeDataEntity(event: experienceEventWithDatastreamIdOverride, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
        let requestString = mockNetworkService.getNetworkRequestsWith(url: INTERACT_ENDPOINT_PROD, httpMethod: .post).first?.url.absoluteString ?? ""

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

        mockNetworkService.setExpectationForNetworkRequest(url: INTERACT_ENDPOINT_PROD, httpMethod: .post, expectedCount: Int32(recoverableNetworkErrorCodes.count))

        for (code, retryValueTuple) in zip(recoverableNetworkErrorCodes, retryValues) {
            let error = EdgeEventError(title: "test-title", detail: nil, status: code, type: "test-type", report: EdgeErrorReport(eventIndex: 0, errors: nil, requestId: nil, orgId: nil))
            let edgeResponse = EdgeResponse(requestId: "test-req-id", handle: nil, errors: [error], warnings: nil)
            let responseData = try? JSONEncoder().encode(edgeResponse)

            mockNetworkService.setMockResponse(
                url: INTERACT_ENDPOINT_PROD,
                httpMethod: .post,
                responseConnection: HttpConnection(
                    data: responseData,
                    response: HTTPURLResponse(url: url,
                                              statusCode: code,
                                              httpVersion: nil,
                                              headerFields: ["Retry-After": retryValueTuple.0]),
                    error: nil))

            let edgeEntity = getEdgeDataEntity(event: experienceEvent, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)
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
        mockNetworkService.assertAllNetworkRequestExpectations(ignoreUnexpectedRequests: false)
    }

    /// Tests that when the network request fails and does not have a recoverable response code that we invoke the response handler and do not retry the hit
    func testProcessHit_experienceEvent_whenUnrecoverableNetworkError_sendsNetworkRequest_returnsTrue() {
        // setup
        mockNetworkService.setMockResponse(
            url: INTERACT_ENDPOINT_PROD,
            httpMethod: .post,
            responseConnection: HttpConnection(
                data: "{}".data(using: .utf8),
                response: HTTPURLResponse(
                    url: url,
                    statusCode: -1,
                    httpVersion: nil,
                    headerFields: nil),
                error: nil))

        let edgeEntity = getEdgeDataEntity(event: experienceEvent, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
        let networkRequests = mockNetworkService.getNetworkRequestsWith(url: INTERACT_ENDPOINT_PROD, httpMethod: .post)
        XCTAssertEqual(1, networkRequests.count)
    }

    /// Tests that when the configurable edge endpoint is empty in configuration shared state that we fallback to production endpoint
    func testProcessHit_experienceEvent_whenConfigEndpointEmpty() {
        // setup
        mockNetworkService.setMockResponse(
            url: INTERACT_ENDPOINT_PROD,
            httpMethod: .post,
            responseConnection: HttpConnection(
                data: "{}".data(using: .utf8),
                response: HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil),
                error: nil))

        let edgeEntity = getEdgeDataEntity(event: experienceEvent, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
        let networkRequests = mockNetworkService.getNetworkRequestsWith(url: INTERACT_ENDPOINT_PROD, httpMethod: .post)
        XCTAssertEqual(1, networkRequests.count)
    }

    /// Tests that when the configurable edge endpoint is invalid in configuration shared state that we fallback to production endpoint
    func testProcessHit_experienceEvent_whenConfigEndpointInvalid() {
        mockNetworkService.setMockResponse(
            url: INTERACT_ENDPOINT_PROD,
            httpMethod: .post,
            responseConnection: HttpConnection(
                data: "{}".data(using: .utf8),
                response: HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil),
                error: nil))

        let edgeEntity = getEdgeDataEntity(event: experienceEvent,
                                           configuration: [self.EDGE_CONFIG_ID: "test-config-id", self.EDGE_ENV: "invalid-env"],
                                           identityMap: defaultIdentityMap)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
        let networkRequests = mockNetworkService.getNetworkRequestsWith(url: INTERACT_ENDPOINT_PROD, httpMethod: .post)
        XCTAssertEqual(1, networkRequests.count)
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
        mockNetworkService.setMockResponse(
            url: INTERACT_ENDPOINT_PROD,
            httpMethod: .post,
            responseConnection: HttpConnection(
                data: "{}".data(using: .utf8),
                response: HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil),
                error: nil))

        let event = Event(name: "test-consent-event", type: EventType.edge, source: EventSource.requestContent, data: nil)
        let edgeEntity = getEdgeDataEntity(event: event, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    func testProcessHit_experienceEvent_emptyPayloadDueToInvalidData_doesNotSendNetworkRequest_returnsTrue() {
        let event = Event(name: "test-experience-event", type: EventType.edge, source: EventSource.requestContent, data: [:])
        let edgeEntity = getEdgeDataEntity(event: event, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    func testProcessHit_experienceEvent_addsEventToWaitingEventsList() {
        let edgeEntity = getEdgeDataEntity(event: experienceEvent, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        let expectation = XCTestExpectation(description: "Callback should be invoked signaling if the hit was processed or not")
        // return recoverable error so the waiting event is not removed onComplete() before the assertion
        mockNetworkService.setMockResponse(
            url: INTERACT_ENDPOINT_PROD,
            httpMethod: .post,
            responseConnection: HttpConnection(
                data: "{}".data(using: .utf8),
                response: HTTPURLResponse(
                    url: url,
                    statusCode: 408,
                    httpVersion: nil,
                    headerFields: nil),
                error: nil))

        // test
        hitProcessor.processHit(entity: entity) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)

        guard let requestUrl = mockNetworkService.getNetworkRequestsWith(url: INTERACT_ENDPOINT_PROD, httpMethod: .post).first?.url else {
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
        mockNetworkService.setMockResponse(
            url: INTERACT_ENDPOINT_PROD,
            httpMethod: .post,
            responseConnection: HttpConnection(
                data: "{}".data(using: .utf8),
                response: HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil),
                error: nil))

        let edgeEntity = getEdgeDataEntity(event: consentUpdateEvent, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, urlString: CONSENT_ENDPOINT, sendsNetworkRequest: true, returns: true)
        let networkRequests = mockNetworkService.getNetworkRequestsWith(url: CONSENT_ENDPOINT, httpMethod: .post)
        XCTAssertEqual(1, networkRequests.count)
    }

    func testProcessHit_consentUpdateEvent_nilData_doesNotSendNetworkRequest_returnsTrue() {
        let event = Event(name: "test-consent-event", type: EventType.edge, source: EventSource.updateConsent, data: nil)
        let edgeEntity = getEdgeDataEntity(event: event, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))
        assertProcessHit(entity: entity, urlString: CONSENT_ENDPOINT, sendsNetworkRequest: false, returns: true)
    }

    func testProcessHit_consentUpdateEvent_emptyPayloadDueToInvalidData_doesNotSendNetworkRequest_returnsTrue() {
        let event = Event(name: "test-consent-event", type: EventType.edge, source: EventSource.updateConsent, data: ["some": "consent"])
        let edgeEntity = getEdgeDataEntity(event: event, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)

        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))
        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    func testProcessHit_consentUpdateEvent_addsEventToWaitingEventsList() {
        let edgeEntity = getEdgeDataEntity(event: consentUpdateEvent, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        let expectation = XCTestExpectation(description: "Callback should be invoked signaling if the hit was processed or not")
        // return recoverable error so the waiting event is not removed onComplete() before the assertion
        mockNetworkService.setMockResponse(
            url: CONSENT_ENDPOINT,
            httpMethod: .post,
            responseConnection: HttpConnection(
                data: "{}".data(using: .utf8),
                response: HTTPURLResponse(
                    url: url,
                    statusCode: 408,
                    httpVersion: nil,
                    headerFields: nil),
                error: nil))

        // test
        hitProcessor.processHit(entity: entity) { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        guard let requestUrl = mockNetworkService.getNetworkRequestsWith(url: CONSENT_ENDPOINT, httpMethod: .post).first?.url else {
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
        let edgeEntity = getEdgeDataEntity(event: event, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)

        XCTAssertTrue(storeResponsePayloadManager.getActiveStores().isEmpty)
    }

    // MARK: - Implementation Details

    // tests Implementation Details added to Experience Events
    func testProcessHit_experienceEvent_sendsNetworkRequest_withImplementationDetails() {
        self.mockGetImplementationDetails = {
            return [
                "name": "https://ns.adobe.com/experience/mobilesdk/ios",
                "environment": "app",
                "version": "3.3.1+1.0.0"
            ]
        }

        mockNetworkService.setMockResponse(
            url: INTERACT_ENDPOINT_PROD,
            httpMethod: .post,
            responseConnection: HttpConnection(
                data: "{}".data(using: .utf8),
                response: HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil),
                error: nil))

        let edgeEntity = getEdgeDataEntity(event: experienceEvent, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)

        guard let networkRequest = mockNetworkService.getNetworkRequestsWith(url: INTERACT_ENDPOINT_PROD, httpMethod: .post).first else {
            XCTFail("Unable to find valid network request.")
            return
        }

        let expectedJSON = """
            {
              "xdm": {
                "implementationDetails": {
                  "environment": "app",
                  "name": "https://ns.adobe.com/experience/mobilesdk/ios",
                  "version": "3.3.1+1.0.0"
                }
              }
            }
        """

        assertExactMatch(expected: expectedJSON, actual: networkRequest)
    }

    // tests Implementation Details is not added to event when nil
    func testProcessHit_experienceEvent_sendsNetworkRequest_withoutImplementationDetails_whenNil() {
        self.mockGetImplementationDetails = { return nil }

        mockNetworkService.setMockResponse(
            url: INTERACT_ENDPOINT_PROD,
            httpMethod: .post,
            responseConnection: HttpConnection(
                data: "{}".data(using: .utf8),
                response: HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil),
                error: nil))

        let edgeEntity = getEdgeDataEntity(event: experienceEvent, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)

        guard let networkRequest = mockNetworkService.getNetworkRequestsWith(url: INTERACT_ENDPOINT_PROD, httpMethod: .post).first else {
            XCTFail("Unable to find valid network request.")
            return
        }

        let expectedJSON = "{}"

        assertExactMatch(
            expected: expectedJSON,
            actual: networkRequest,
            pathOptions: KeyMustBeAbsent(paths:
                                            "xdm.implementationDetails.environment",
                                         "xdm.implementationDetails.name",
                                         "xdm.implementationDetails.version"))
    }

    // tests Implementation Details is not added to Consent events
    func testProcessHit_consentEvent_sendsNetworkRequest_withoutImplementationDetails() {
        self.mockGetImplementationDetails = {
            return [
                "name": "https://ns.adobe.com/experience/mobilesdk/ios",
                "environment": "app",
                "version": "3.3.1+1.0.0"
            ]
        }

        mockNetworkService.setMockResponse(
            url: CONSENT_ENDPOINT,
            httpMethod: .post,
            responseConnection: HttpConnection(
                data: "{}".data(using: .utf8),
                response: HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil),
                error: nil))

        let edgeEntity = getEdgeDataEntity(event: consentUpdateEvent, configuration: defaultEdgeConfig, identityMap: defaultIdentityMap)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, urlString: CONSENT_ENDPOINT, sendsNetworkRequest: true, returns: true)

        guard let networkRequest = mockNetworkService.getNetworkRequestsWith(url: CONSENT_ENDPOINT, httpMethod: .post).first else {
            XCTFail("Unable to find valid network request.")
            return
        }

        // Implementation Details are not added to Consent events
        let expectedJSON = "{}"

        assertExactMatch(
            expected: expectedJSON,
            actual: networkRequest,
            pathOptions: KeyMustBeAbsent(paths:
                                            "xdm.implementationDetails.environment",
                                         "xdm.implementationDetails.name",
                                         "xdm.implementationDetails.version"))
    }

    func assertProcessHit(entity: DataEntity, urlString: String? = nil, sendsNetworkRequest: Bool, returns: Bool, file: StaticString = #file, line: UInt = #line) {
        let expectation = XCTestExpectation(description: "Callback should be invoked signaling if the hit was processed or not")

        if sendsNetworkRequest {
            mockNetworkService.setExpectationForNetworkRequest(
                url: urlString ?? INTERACT_ENDPOINT_PROD,
                httpMethod: .post,
                file: file,
                line: line)
        }

        // test
        hitProcessor.processHit(entity: entity) { success in
            XCTAssertEqual(returns, success, "Expected callback to be called with \(returns), but it was \(success)", file: file, line: line)
            expectation.fulfill()
        }

        // verify
        wait(for: [expectation], timeout: 1)
        mockNetworkService.assertAllNetworkRequestExpectations(ignoreUnexpectedRequests: false, file: file, line: line)
    }

    private func assertNetworkRequestUrl(event: Event, environment: String?, domain: String?, expectedEndpoint: String, getLocationHint: @escaping () -> String? = { return nil }) {
        var config: [String: Any] = [self.EDGE_CONFIG_ID: "test-config-id"]
        if let env = environment {
            config[self.EDGE_ENV] = env
        }
        if let domain = domain {
            config[self.EDGE_DOMAIN] = domain
        }

        self.mockGetLocationHint = getLocationHint

        mockNetworkService.setMockResponse(
            url: expectedEndpoint,
            httpMethod: .post,
            responseConnection: HttpConnection(
                data: "{}".data(using: .utf8),
                response: HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil),
                error: nil))

        let edgeEntity = getEdgeDataEntity(event: event, configuration: config, identityMap: defaultIdentityMap)
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        // test
        assertProcessHit(entity: entity, urlString: expectedEndpoint, sendsNetworkRequest: true, returns: true)
        let actualUrl = mockNetworkService.getNetworkRequestsWith(url: expectedEndpoint, httpMethod: .post).first?.url.absoluteString ?? ""
        XCTAssertTrue( actualUrl.starts(with: expectedEndpoint))
    }

    /// Convenience helper to setup `EdgeDataEntity` for testing. Adds default values for Edge configuration and Identity Map.
    /// - Parameters:
    ///   - event: the test `Event`
    /// - Returns: an `EdgeDataEntity` initialized with the given `event` and default `edge.configId` and identity map with ECID.
    private func getEdgeDataEntity(event: Event) -> EdgeDataEntity {
        return EdgeDataEntity(event: event,
                              configuration: AnyCodable.from(dictionary: defaultEdgeConfig) ?? [:],
                              identityMap: AnyCodable.from(dictionary: defaultIdentityMap) ?? [:]
        )
    }

    /// Convenience helper to setup `EdgeDataEntity` for testing. Coverts parameters `configuration` and `identityMap` to `AnyCodable` before initializing `EdgeDataEntity`.
    /// - Parameters:
    ///   - event: the test `Event`
    ///   - configuration: the test Edge configuration as type`[String: Any]`
    ///   - identityMap: the test Identity Map as type `[String: Any]`
    /// - Returns: an `EdgeDataEntity` initialized with the given parameters
    private func getEdgeDataEntity(event: Event, configuration: [String: Any], identityMap: [String: Any]) -> EdgeDataEntity {
        return EdgeDataEntity(event: event,
                              configuration: AnyCodable.from(dictionary: configuration) ?? [:],
                              identityMap: AnyCodable.from(dictionary: identityMap) ?? [:]
        )
    }

    /// Helper to setup `EdgeDataEntity` for testing.
    /// - Parameters:
    ///   - event: the test `Event`
    ///   - configuration: the test Edge configuration as type`[String: AnyCodable]`
    ///   - identityMap: the test Identity Map as type `[String: AnyCodable]`
    /// - Returns: an `EdgeDataEntity` initialized with the given parameters
    private func getEdgeDataEntity(event: Event, configuration: [String: AnyCodable], identityMap: [String: AnyCodable]) -> EdgeDataEntity {
        return EdgeDataEntity(event: event, configuration: configuration, identityMap: identityMap)
    }

    // MARK: - Old (v5.0.0 or less) "readyForEvent" workflow tests

    /// Tests that when `readyForEvent` returns true, hit is sent
    func testProcessHit_readyForEventWorkflow_experienceEvent_readyForEventReturnsTrue_thenHitSent() {
        // Set EdgeDataEntity with empty configuration
        let edgeEntity = EdgeDataEntity(event: experienceEvent, configuration: [:], identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))
        self.mockReadyForEvent = {_ in return true }
        self.mockGetSharedState = {extensionName, _ in
            if extensionName == "com.adobe.module.configuration" {
                return SharedStateResult(status: .set, value: self.defaultEdgeConfig)
            }
            return nil
        }

        assertProcessHit(entity: entity, sendsNetworkRequest: true, returns: true)
    }

    /// Tests that when `readyForEvent` returns false that we retry the hit
    func testProcessHit_readyForEventWorkflow_experienceEvent_readyForEventReturnsFalse_thenRetryHit() {
        // Set EdgeDataEntity with empty configuration
        let edgeEntity = EdgeDataEntity(event: experienceEvent, configuration: [:], identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))
        self.mockReadyForEvent = {_ in return false }

        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: false)
    }

    /// Tests that when configuration shared state is nil that we drop the hit
    func testProcessHit_readyForEventWorkflow_experienceEvent_nilConfiguration_thenDropHit() {
        // setup
        let edgeEntity = EdgeDataEntity(event: experienceEvent, configuration: [:], identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        self.mockReadyForEvent = {_ in return true}
        self.mockGetSharedState = {extensionName, _ in
            if extensionName == "com.adobe.module.configuration" {
                return SharedStateResult(status: .set, value: nil)
            }
            return nil
        }

        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    /// Tests that when no edge config id is in configuration shared state that we drop the hit
    func testProcessHit_readyForEventWorkflow_experienceEvent_noEdgeConfigId_thenDropHit() {
        // setup
        let edgeEntity = EdgeDataEntity(event: experienceEvent, configuration: [:], identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        self.mockReadyForEvent = {_ in return true}
        self.mockGetSharedState = {extensionName, _ in
            if extensionName == "com.adobe.module.configuration" {
                return SharedStateResult(status: .set, value: [:])
            }
            return nil
        }

        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    /// Tests that when edge config id is empty string in configuration shared state that we drop the hit
    func testProcessHit_readyForEventWorkflow_experienceEvent_emptyEdgeConfigId_thenDropHit() {
        // setup
        let edgeEntity = EdgeDataEntity(event: experienceEvent, configuration: [:], identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        self.mockReadyForEvent = {_ in return true}
        self.mockGetSharedState = {extensionName, _ in
            if extensionName == "com.adobe.module.configuration" {
                return SharedStateResult(status: .set, value: ["edge.configId": ""])
            }
            return nil
        }

        assertProcessHit(entity: entity, sendsNetworkRequest: false, returns: true)
    }

    /// Tests that when `readyForEvent` returns true, hit is sent
    func testProcessHit_readyForEventWorkflow_consentUpdateEvent_readyForEventReturnsTrue_thenHitSent() {
        // Set EdgeDataEntity with empty configuration
        let edgeEntity = EdgeDataEntity(event: consentUpdateEvent, configuration: [:], identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))
        self.mockReadyForEvent = {_ in return true }
        self.mockGetSharedState = {extensionName, _ in
            if extensionName == "com.adobe.module.configuration" {
                return SharedStateResult(status: .set, value: self.defaultEdgeConfig)
            }
            return nil
        }

        assertProcessHit(entity: entity, urlString: CONSENT_ENDPOINT, sendsNetworkRequest: true, returns: true)
    }

    /// Tests that when `readyForEvent` returns false that we retry the hit
    func testProcessHit_readyForEventWorkflow_consentUpdateEvent_readyForEventReturnsFalse_thenRetryHit() {
        // Set EdgeDataEntity with empty configuration
        let edgeEntity = EdgeDataEntity(event: consentUpdateEvent, configuration: [:], identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))
        self.mockReadyForEvent = {_ in return false }

        assertProcessHit(entity: entity, urlString: CONSENT_ENDPOINT, sendsNetworkRequest: false, returns: false)
    }

    /// Tests that when no edge config id is in configuration shared state that we drop the hit
    func testProcessHit_readyForEventWorkflow_consentUpdateEvent_noEdgeConfigId_thenDropHit() {
        // setup
        let edgeEntity = EdgeDataEntity(event: consentUpdateEvent, configuration: [:], identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        self.mockReadyForEvent = {_ in return true}
        self.mockGetSharedState = {extensionName, _ in
            if extensionName == "com.adobe.module.configuration" {
                return SharedStateResult(status: .set, value: [:])
            }
            return nil
        }

        assertProcessHit(entity: entity, urlString: CONSENT_ENDPOINT, sendsNetworkRequest: false, returns: true)
    }

    /// Tests that when configuration shared state is nil that we drop the hit
    func testProcessHit_readyForEventWorkflow_consentUpdate_nilConfiguration_thenDropHit() {
        // setup
        let edgeEntity = EdgeDataEntity(event: consentUpdateEvent, configuration: [:], identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        self.mockReadyForEvent = {_ in return true}
        self.mockGetSharedState = {extensionName, _ in
            if extensionName == "com.adobe.module.configuration" {
                return SharedStateResult(status: .set, value: nil)
            }
            return nil
        }

        assertProcessHit(entity: entity, urlString: CONSENT_ENDPOINT, sendsNetworkRequest: false, returns: true)
    }

    /// Tests that when edge config id is empty string in configuration shared state that we drop the hit
    func testProcessHit_readyForEventWorkflow_consentUpdate_emptyEdgeConfigId_thenDropHit() {
        // setup
        let edgeEntity = EdgeDataEntity(event: consentUpdateEvent, configuration: [:], identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: "test-uuid", timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        self.mockReadyForEvent = {_ in return true}
        self.mockGetSharedState = {extensionName, _ in
            if extensionName == "com.adobe.module.configuration" {
                return SharedStateResult(status: .set, value: ["edge.configId": ""])
            }
            return nil
        }

        assertProcessHit(entity: entity, urlString: CONSENT_ENDPOINT, sendsNetworkRequest: false, returns: true)
    }
}

extension URL {
    subscript(queryParam: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParam })?.value
    }
}

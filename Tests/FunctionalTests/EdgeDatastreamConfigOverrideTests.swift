//
// Copyright 2023 Adobe. All rights reserved.
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
import AEPEdgeIdentity
import AEPServices
import Foundation
import XCTest

// swiftlint:disable type_body_length
/// Functional tests for the sendEvent API with datastreamIdOverride and datastreamConfigOverride features
class AEPEdgeDatastreamOverrideTests: TestBase {
    private let exEdgeInteractProdUrl = URL(string: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR)! // swiftlint:disable:this force_unwrapping
    private let responseBody = "{\"test\": \"json\"}"
#if os(iOS)
    private let EXPECTED_BASE_PATH = "https://ns.adobe.com/experience/mobilesdk/ios"
#elseif os(tvOS)
    private let EXPECTED_BASE_PATH = "https://ns.adobe.com/experience/mobilesdk/tvos"
#endif

    private let mockNetworkService: MockNetworkService = MockNetworkService()
    private let configOverrides: [String: Any] = [
        "com_adobe_experience_platform": [
          "datasets": [
            "event": [
              "datasetId": "eventDatasetIdOverride"
            ],
            "profile": [
              "datasetId": "profileDatasetIdOverride"
            ]
          ]
        ],
        "com_adobe_analytics": [
          "reportSuites": [
            "rsid1",
            "rsid2",
            "rsid3"
            ]
        ],
        "com_adobe_identity": [
          "idSyncContainerId": "1234567"
        ],
        "com_adobe_target": [
          "propertyToken": "samplePropertyToken"
        ]
    ]

    // Runs before each test case
    override func setUp() {
        ServiceProvider.shared.networkService = mockNetworkService

        super.setUp()

        continueAfterFailure = false
        TestBase.debugEnabled = true
        FileManager.default.clearCache()

        // hub shared state update for 1 extension versions (InstrumentedExtension (registered in TestBase), IdentityEdge, Edge) IdentityEdge XDM, Config, and Edge shared state updates
        setExpectationEvent(type: TestConstants.EventType.HUB, source: TestConstants.EventSource.SHARED_STATE, expectedCount: 4)

        // expectations for update config request&response events
        setExpectationEvent(type: TestConstants.EventType.CONFIGURATION, source: TestConstants.EventSource.REQUEST_CONTENT, expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.CONFIGURATION, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)

        // wait for async registration because the EventHub is already started in TestBase
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([Identity.self, Edge.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))
        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "originalDatastreamId"])

        assertExpectedEvents(ignoreUnexpectedEvents: false, timeout: 2)
        resetTestExpectations()
        mockNetworkService.reset()
    }

    // Runs after each test case
    override func tearDown() {
        super.tearDown()

        mockNetworkService.reset()
    }

    // MARK: test network request format

    func testSendEvent_withXDMDataAndCustomData_withDatastreamIdOverrideAndDatastreamConfigOverride_sendsExEdgeNetworkRequestWithOverridenDatastreamIdAndConfig() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["test": ["key": "value"]], data: ["key": "value"], datastreamIdOverride: "testDatastreamIdOverride", datastreamConfigOverride: configOverrides)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        let requestBody = resultNetworkRequests[0].getFlattenedBody()
        XCTAssertEqual(21, requestBody.count)

        XCTAssertEqual("value", requestBody["events[0].xdm.test.key"] as? String)
        XCTAssertEqual("value", requestBody["events[0].data.key"] as? String)
        XCTAssertEqual("app", requestBody["xdm.implementationDetails.environment"] as? String)
        XCTAssertEqual("\(MobileCore.extensionVersion)+\(Edge.extensionVersion)", requestBody["xdm.implementationDetails.version"] as? String)
        XCTAssertEqual(EXPECTED_BASE_PATH, requestBody["xdm.implementationDetails.name"] as? String)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))

        XCTAssertEqual("testDatastreamIdOverride", requestUrl.queryParam("configId"))

        // Verify top level metadata
        XCTAssertEqual(true, requestBody["meta.konductorConfig.streaming.enabled"] as? Bool)
        XCTAssertEqual("originalDatastreamId", requestBody["meta.sdkConfig.datastream.original"] as? String)
        XCTAssertEqual("eventDatasetIdOverride", requestBody["meta.configOverrides.com_adobe_experience_platform.datasets.event.datasetId"] as? String)
        XCTAssertEqual("profileDatasetIdOverride", requestBody["meta.configOverrides.com_adobe_experience_platform.datasets.profile.datasetId"] as? String)
        XCTAssertEqual("rsid1", requestBody["meta.configOverrides.com_adobe_analytics.reportSuites[0]"] as? String)
        XCTAssertEqual("rsid2", requestBody["meta.configOverrides.com_adobe_analytics.reportSuites[1]"] as? String)
        XCTAssertEqual("rsid3", requestBody["meta.configOverrides.com_adobe_analytics.reportSuites[2]"] as? String)
        XCTAssertEqual("1234567", requestBody["meta.configOverrides.com_adobe_identity.idSyncContainerId"] as? String)
        XCTAssertEqual("samplePropertyToken", requestBody["meta.configOverrides.com_adobe_target.propertyToken"] as? String)
    }

    func testSendEvent_withXDMDataAndCustomData_withDatastreamIdOverride_sendsExEdgeNetworkRequestWithOverridenDatastreamId() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["test": ["key": "value"]], data: ["key": "value"], datastreamIdOverride: "testDatastreamIdOverride")
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        let requestBody = resultNetworkRequests[0].getFlattenedBody()
        XCTAssertEqual(14, requestBody.count)
        XCTAssertEqual(true, requestBody["meta.konductorConfig.streaming.enabled"] as? Bool)
        XCTAssertEqual("value", requestBody["events[0].xdm.test.key"] as? String)
        XCTAssertEqual("value", requestBody["events[0].data.key"] as? String)
        XCTAssertEqual("app", requestBody["xdm.implementationDetails.environment"] as? String)
        XCTAssertEqual("\(MobileCore.extensionVersion)+\(Edge.extensionVersion)", requestBody["xdm.implementationDetails.version"] as? String)
        XCTAssertEqual(EXPECTED_BASE_PATH, requestBody["xdm.implementationDetails.name"] as? String)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))

        XCTAssertEqual("testDatastreamIdOverride", requestUrl.queryParam("configId"))

        XCTAssertEqual("originalDatastreamId", requestBody["meta.sdkConfig.datastream.original"] as? String)

        let requestPayload = try? JSONSerialization.jsonObject(with: resultNetworkRequests[0].connectPayload, options: []) as? [String: Any]
        let metaPayload = requestPayload?["meta"] as? [String: Any]
        XCTAssertNil(metaPayload?["configOverrides"])
    }

    func testSendEvent_withXDMDataAndCustomData_withDatastreamConfigOverride_sendsExEdgeNetworkRequestWithOverridenDatastreamConfig() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["test": ["key": "value"]], data: ["key": "value"], datastreamConfigOverride: configOverrides)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        let requestBody = resultNetworkRequests[0].getFlattenedBody()
        XCTAssertEqual(20, requestBody.count)
        XCTAssertEqual("value", requestBody["events[0].xdm.test.key"] as? String)
        XCTAssertEqual("value", requestBody["events[0].data.key"] as? String)
        XCTAssertEqual("app", requestBody["xdm.implementationDetails.environment"] as? String)
        XCTAssertEqual("\(MobileCore.extensionVersion)+\(Edge.extensionVersion)", requestBody["xdm.implementationDetails.version"] as? String)
        XCTAssertEqual(EXPECTED_BASE_PATH, requestBody["xdm.implementationDetails.name"] as? String)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))

        XCTAssertEqual("originalDatastreamId", requestUrl.queryParam("configId"))

        // Verify top level metadata
        XCTAssertEqual(true, requestBody["meta.konductorConfig.streaming.enabled"] as? Bool)
        XCTAssertEqual("eventDatasetIdOverride", requestBody["meta.configOverrides.com_adobe_experience_platform.datasets.event.datasetId"] as? String)
        XCTAssertEqual("profileDatasetIdOverride", requestBody["meta.configOverrides.com_adobe_experience_platform.datasets.profile.datasetId"] as? String)
        XCTAssertEqual("rsid1", requestBody["meta.configOverrides.com_adobe_analytics.reportSuites[0]"] as? String)
        XCTAssertEqual("rsid2", requestBody["meta.configOverrides.com_adobe_analytics.reportSuites[1]"] as? String)
        XCTAssertEqual("rsid3", requestBody["meta.configOverrides.com_adobe_analytics.reportSuites[2]"] as? String)
        XCTAssertEqual("1234567", requestBody["meta.configOverrides.com_adobe_identity.idSyncContainerId"] as? String)
        XCTAssertEqual("samplePropertyToken", requestBody["meta.configOverrides.com_adobe_target.propertyToken"] as? String)

        let requestPayload = try? JSONSerialization.jsonObject(with: resultNetworkRequests[0].connectPayload, options: []) as? [String: Any]
        let metaPayload = requestPayload?["meta"] as? [String: Any]
        XCTAssertNil(metaPayload?["sdkConfig"])
    }
}

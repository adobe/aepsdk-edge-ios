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
import AEPTestUtils
import Foundation
import XCTest

// swiftlint:disable type_body_length
/// Functional tests for the sendEvent API with datastreamIdOverride and datastreamConfigOverride features
class AEPEdgeDatastreamOverrideTests: TestBase, AnyCodableAsserts {
    private let TIMEOUT_SEC: TimeInterval = FunctionalTestConstants.Defaults.TIMEOUT_SEC
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
        loggingEnabled = true
        NamedCollectionDataStore.clear()

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
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: TIMEOUT_SEC))
        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "originalDatastreamId"])

        assertExpectedEvents(ignoreUnexpectedEvents: false, timeout: TIMEOUT_SEC)
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
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        // Validate URL
        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
        XCTAssertEqual("testDatastreamIdOverride", requestUrl.queryParam("configId"))

        let expectedJSON = createExpectedPayload(
            metaProperties:
            """
              "configOverrides": {
                "com_adobe_analytics": {
                  "reportSuites": [
                    "rsid1",
                    "rsid2",
                    "rsid3"
                  ]
                },
                "com_adobe_experience_platform": {
                  "datasets": {
                    "event": {
                      "datasetId": "eventDatasetIdOverride"
                    },
                    "profile": {
                      "datasetId": "profileDatasetIdOverride"
                    }
                  }
                },
                "com_adobe_identity": {
                  "idSyncContainerId": "1234567"
                },
                "com_adobe_target": {
                  "propertyToken": "samplePropertyToken"
                }
              },
              "sdkConfig": {
                "datastream": {
                  "original": "originalDatastreamId"
                }
              }
            """
        )

        assertExactMatch(
            expected: expectedJSON,
            actual: resultNetworkRequests[0],
            pathOptions:
                ValueTypeMatch(paths:
                   "events[0].xdm._id",
                   "events[0].xdm.timestamp",
                   "meta.konductorConfig.streaming.lineFeed",
                   "meta.konductorConfig.streaming.recordSeparator",
                   "xdm.identityMap.ECID[0].authenticatedState",
                   "xdm.identityMap.ECID[0].id",
                   "xdm.identityMap.ECID[0].primary"),
                CollectionEqualCount(scope: .subtree))
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
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        // Validate URL
        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
        XCTAssertEqual("testDatastreamIdOverride", requestUrl.queryParam("configId"))

        let expectedJSON = createExpectedPayload(
            metaProperties:
            """
             "sdkConfig": {
               "datastream": {
                 "original": "originalDatastreamId"
               }
             }
            """
        )

        assertExactMatch(
            expected: expectedJSON,
            actual: resultNetworkRequests[0],
            pathOptions:
                ValueTypeMatch(paths:
                   "events[0].xdm._id",
                   "events[0].xdm.timestamp",
                   "meta.konductorConfig.streaming.lineFeed",
                   "meta.konductorConfig.streaming.recordSeparator",
                   "xdm.identityMap.ECID[0].authenticatedState",
                   "xdm.identityMap.ECID[0].id",
                   "xdm.identityMap.ECID[0].primary"),
                CollectionEqualCount(scope: .subtree))
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
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        // Valdiate URL
        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))

        XCTAssertEqual("originalDatastreamId", requestUrl.queryParam("configId"))

        let expectedJSON = createExpectedPayload(
            metaProperties:
            """
              "configOverrides": {
                "com_adobe_analytics": {
                  "reportSuites": [
                    "rsid1",
                    "rsid2",
                    "rsid3"
                  ]
                },
                "com_adobe_experience_platform": {
                  "datasets": {
                    "event": {
                      "datasetId": "eventDatasetIdOverride"
                    },
                    "profile": {
                      "datasetId": "profileDatasetIdOverride"
                    }
                  }
                },
                "com_adobe_identity": {
                  "idSyncContainerId": "1234567"
                },
                "com_adobe_target": {
                  "propertyToken": "samplePropertyToken"
                }
              }
            """
        )

        assertExactMatch(
            expected: expectedJSON,
            actual: resultNetworkRequests[0],
            pathOptions:
                ValueTypeMatch(paths:
                   "events[0].xdm._id",
                   "events[0].xdm.timestamp",
                   "meta.konductorConfig.streaming.lineFeed",
                   "meta.konductorConfig.streaming.recordSeparator",
                   "xdm.identityMap.ECID[0].authenticatedState",
                   "xdm.identityMap.ECID[0].id",
                   "xdm.identityMap.ECID[0].primary"),
                CollectionEqualCount(scope: .subtree))
    }

    /// Generates a JSON string representing a network request payload. It
    /// allows the injection of custom content for the `meta` section of the payload.
    ///
    /// - Parameters:
    ///   - metaPayload: A JSON string to be included in the `meta` section of the payload. Defaults
    ///                  to an empty string, which means no additional content will be added to the `meta` section.
    /// - Returns: A JSON string representing the complete network request payload.
    private func createExpectedPayload(metaProperties: String = "") -> String {
        return """
        {
          "events": [
            {
              "data": {
                "key": "value"
              },
              "xdm": {
                "_id": "STRING_TYPE",
                "test": {
                  "key": "value"
                },
                "timestamp": "STRING_TYPE"
              }
            }
          ],
          "meta": {
            "konductorConfig": {
              "streaming": {
                "enabled": true,
                "lineFeed": "STRING_TYPE",
                "recordSeparator": "STRING_TYPE"
              }
            },
            \(metaProperties)
          },
          "xdm": {
            "identityMap": {
              "ECID": [
                {
                  "authenticatedState": "STRING_TYPE",
                  "id": "STRING_TYPE",
                  "primary": false
                }
              ]
            },
            "implementationDetails": {
              "environment": "app",
              "name": "\(self.EXPECTED_BASE_PATH)",
              "version": "\(MobileCore.extensionVersion)+\(Edge.extensionVersion)"
            }
          }
        }
        """
    }
}

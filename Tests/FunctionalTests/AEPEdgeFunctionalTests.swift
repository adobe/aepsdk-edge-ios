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
import AEPEdgeIdentity
import AEPServices
import AEPTestUtils
import Foundation
import XCTest

// swiftlint:disable type_body_length

/// End-to-end testing for the AEPEdge public APIs
class AEPEdgeFunctionalTests: TestBase, AnyCodableAsserts {
    private let TIMEOUT_SEC: TimeInterval = FunctionalTestConstants.Defaults.TIMEOUT_SEC
    private let event1 = Event(name: "e1", type: "eventType", source: "eventSource", data: nil)
    private let event2 = Event(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private let exEdgeInteractProdUrl = URL(string: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR)! // swiftlint:disable:this force_unwrapping
    private let exEdgeInteractPreProdUrl = URL(string: TestConstants.EX_EDGE_INTERACT_PRE_PROD_URL_STR)! // swiftlint:disable:this force_unwrapping
    private let exEdgeInteractIntegrationUrl = URL(string: TestConstants.EX_EDGE_INTERACT_INTEGRATION_URL_STR)! // swiftlint:disable:this force_unwrapping
    private let responseBody = "{\"test\": \"json\"}"
    #if os(iOS)
    private let EXPECTED_BASE_PATH = "https://ns.adobe.com/experience/mobilesdk/ios"
    #elseif os(tvOS)
    private let EXPECTED_BASE_PATH = "https://ns.adobe.com/experience/mobilesdk/tvos"
    #endif
    private var expectedRecordSeparatorString: String {
        if #available(iOS 17.2, tvOS 17.2, *) {
            return "\0"
        } else if #available(iOS 17, tvOS 17, *) {
            return ""
        } else {
            return "\u{0000}"
        }
    }

    private let mockNetworkService: MockNetworkService = MockNetworkService()

    // Runs before each test case
    override func setUp() {
        ServiceProvider.shared.networkService = mockNetworkService

        super.setUp()

        continueAfterFailure = true
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
        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])

        assertExpectedEvents(ignoreUnexpectedEvents: false, timeout: TIMEOUT_SEC)
        resetTestExpectations()
        mockNetworkService.reset()
    }

    // Runs after each test case
    override func tearDown() {
        super.tearDown()

        MobileCore.resetSDK()

        mockNetworkService.reset()
        resetTestExpectations()
    }

    func testUnregistered() {
        let waitForUnregistration = CountDownLatch(1)
        MobileCore.unregisterExtension(Edge.self, {
            print("Extension unregistration is complete")
            waitForUnregistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForUnregistration.await(timeout: TIMEOUT_SEC))
    }

    // MARK: test request event format

    func testSendEvent_withXDMData_sendsCorrectRequestEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.REQUEST_CONTENT)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm",
                                                    "testInt": 10,
                                                    "testBool": false,
                                                    "testDouble": 12.89,
                                                    "testArray": ["arrayElem1", 2, true],
                                                    "testDictionary": ["key": "val"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                   source: TestConstants.EventSource.REQUEST_CONTENT)

        let expectedJSON = #"""
        {
          "xdm": {
            "testArray": [
              "arrayElem1",
              2,
              true
            ],
            "testBool": false,
            "testDictionary": {
              "key": "val"
            },
            "testDouble": 12.89,
            "testInt": 10,
            "testString": "xdm"
          }
        }
        """#
        assertEqual(expected: expectedJSON, actual: resultEvents[0])
    }

    func testSendEvent_withXDMDataAndCustomData_sendsCorrectRequestEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.REQUEST_CONTENT)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: ["testDataString": "stringValue",
                                                                                 "testDataInt": 101,
                                                                                 "testDataBool": true,
                                                                                 "testDataDouble": 13.66,
                                                                                 "testDataArray": ["arrayElem1", 2, true],
                                                                                 "testDataDictionary": ["key": "val"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                   source: TestConstants.EventSource.REQUEST_CONTENT)

        let expectedJSON = #"""
        {
          "data": {
            "testDataArray": [
              "arrayElem1",
              2,
              true
            ],
            "testDataBool": true,
            "testDataDictionary": {
              "key": "val"
            },
            "testDataDouble": 13.66,
            "testDataInt": 101,
            "testDataString": "stringValue"
          },
          "xdm": {
            "testString": "xdm"
          }
        }
        """#
        assertEqual(expected: expectedJSON, actual: resultEvents[0])
    }

    func testSendEvent_withXDMDataAndNilData_sendsCorrectRequestEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.REQUEST_CONTENT)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                   source: TestConstants.EventSource.REQUEST_CONTENT)

        let expectedJSON = #"""
        {
          "xdm": {
            "testString": "xdm"
          }
        }
        """#
        assertEqual(expected: expectedJSON, actual: resultEvents[0])
    }

    func testSendEvent_withEmptyXDMDataAndNilData_DoesNotSendRequestEvent() {
        let experienceEvent = ExperienceEvent(xdm: [:], data: nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertUnexpectedEvents()
    }

    func testSendEvent_withEmptyXDMSchema_DoesNotSendRequestEvent() {
        let experienceEvent = ExperienceEvent(xdm: TestXDMSchema())
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertUnexpectedEvents()
    }

    func testSendEvent_withXDMDataAndQuery_sendsCorrectRequestEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.REQUEST_CONTENT)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        experienceEvent.query = ["testString": "query",
                                 "testInt": 10,
                                 "testBool": false,
                                 "testDouble": 12.89,
                                 "testArray": ["arrayElem1", 2, true],
                                 "testDictionary": ["key": "val"]]
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                   source: TestConstants.EventSource.REQUEST_CONTENT)

        let expectedJSON = #"""
        {
          "query": {
            "testArray": [
              "arrayElem1",
              2,
              true
            ],
            "testBool": false,
            "testDictionary": {
              "key": "val"
            },
            "testDouble": 12.89,
            "testInt": 10,
            "testString": "query"
          },
          "xdm": {
            "testString": "xdm"
          }
        }
        """#
        assertEqual(expected: expectedJSON, actual: resultEvents[0])
    }

    func testSendEvent_withXDMDataAndEmptyQuery_sendsCorrectRequestEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.REQUEST_CONTENT)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        experienceEvent.query = [:]
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                   source: TestConstants.EventSource.REQUEST_CONTENT)

        let expectedJSON = #"""
        {
          "xdm": {
            "testString": "xdm"
          }
        }
        """#
        assertEqual(expected: expectedJSON, actual: resultEvents[0])
    }

    func testSendEvent_withXDMDataAndNilQuery_sendsCorrectRequestEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.REQUEST_CONTENT)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        experienceEvent.query = nil
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                   source: TestConstants.EventSource.REQUEST_CONTENT)

        let expectedJSON = #"""
        {
          "xdm": {
            "testString": "xdm"
          }
        }
        """#
        assertEqual(expected: expectedJSON, actual: resultEvents[0])
    }

    // MARK: test network request format

    func testSendEvent_withXDMData_sendsExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm",
                                                    "testInt": 10,
                                                    "testBool": false,
                                                    "testDouble": 12.89,
                                                    "testArray": ["arrayElem1", 2, true],
                                                    "testDictionary": ["key": "val"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        // Note that `recordSeparator` is set in the format required by the JSON spec to be properly decoded,
        // not the various Swift formats
        let expectedJSON = createExpectedPayload(
            eventsPayload:
            #"""
            {
              "xdm": {
                "_id": "STRING_TYPE",
                "timestamp": "STRING_TYPE",
                "testString": "xdm",
                "testInt": 10,
                "testBool": false,
                "testDouble": 12.89,
                "testArray": [
                  "arrayElem1",
                  2,
                  true
                ],
                "testDictionary": {
                  "key": "val"
                }
              }
            }
            """#
        )

        assertExactMatch(
            expected: expectedJSON,
            actual: resultNetworkRequests[0],
            pathOptions:
                CollectionEqualCount(paths: nil, scope: .subtree),
                ValueTypeMatch(paths: "xdm.identityMap.ECID[0].id",
                           "xdm.identityMap.ECID[0].authenticatedState",
                           "xdm.identityMap.ECID[0].primary",
                           "events[0].xdm._id",
                           "events[0].xdm.timestamp",
                            "meta.konductorConfig.streaming.recordSeparator"))

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withXDMDataAndCustomData_sendsExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: ["testDataString": "stringValue",
                                                                                 "testDataInt": 101,
                                                                                 "testDataBool": true,
                                                                                 "testDataDouble": 13.66,
                                                                                 "testDataArray": ["arrayElem1", 2, true],
                                                                                 "testDataDictionary": ["key": "val"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        let expectedJSON = createExpectedPayload(
            eventsPayload:
            #"""
            {
              "data": {
                "testDataArray": [
                  "arrayElem1",
                  2,
                  true
                ],
                "testDataBool": true,
                "testDataDictionary": {
                  "key": "val"
                },
                "testDataDouble": 13.66,
                "testDataInt": 101,
                "testDataString": "stringValue"
              },
              "xdm": {
                "_id": "STRING_TYPE",
                "testString": "xdm",
                "timestamp": "STRING_TYPE"
              }
            }
            """#
        )

        assertExactMatch(
            expected: expectedJSON,
            actual: resultNetworkRequests[0],
            pathOptions:
                CollectionEqualCount(scope: .subtree),
                ValueTypeMatch(paths: "xdm.identityMap.ECID", scope: .subtree),
                ValueTypeMatch(paths: "events[0].xdm._id", "events[0].xdm.timestamp", "meta.konductorConfig.streaming.recordSeparator"))

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withXDMSchema_sendsExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        var xdmObject = TestXDMObject()
        xdmObject.innerKey = "testInnerObject"
        var xdmSchema = TestXDMSchema()
        xdmSchema.boolObject = true
        xdmSchema.intObject = 100
        xdmSchema.stringObject = "testWithXdmSchema"
        xdmSchema.doubleObject = 3.42
        xdmSchema.xdmObject = xdmObject

        let experienceEvent = ExperienceEvent(xdm: xdmSchema)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        let expectedJSON = createExpectedPayload(
            eventsPayload:
            #"""
            {
              "meta": {
                "collect": {
                  "datasetId": "abc123def"
                }
              },
              "xdm": {
                "_id": "STRING_TYPE",
                "timestamp": "STRING_TYPE",
                "boolObject": true,
                "intObject": 100,
                "stringObject": "testWithXdmSchema",
                "doubleObject": 3.42,
                "xdmObject": {
                  "innerKey": "testInnerObject"
                }
              }
            }
            """#
        )

        assertExactMatch(
            expected: expectedJSON,
            actual: resultNetworkRequests[0],
            pathOptions:
                CollectionEqualCount(scope: .subtree),
                ValueTypeMatch(paths: "xdm.identityMap.ECID", scope: .subtree),
                ValueTypeMatch(paths: "events[0].xdm._id", "events[0].xdm.timestamp", "meta.konductorConfig.streaming.recordSeparator"))

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withEmptyXDMSchema_doesNotSendExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)

        let experienceEvent = ExperienceEvent(xdm: TestXDMSchema())
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    func testSendEvent_withEmptyXDMSchemaAndEmptyData_doesNotSendExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)

        let experienceEvent = ExperienceEvent(xdm: TestXDMSchema(), data: [:])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    func testSendEvent_withEmptyXDMSchemaAndNilData_doesNotSendExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)

        let experienceEvent = ExperienceEvent(xdm: TestXDMSchema(), data: nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    func testSendEvent_withXDMDataAndQuery_sendsExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        experienceEvent.query = ["testString": "query",
                                 "testInt": 10,
                                 "testBool": false,
                                 "testDouble": 12.89,
                                 "testArray": ["arrayElem1", 2, true],
                                 "testDictionary": ["key": "val"]]
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        let expectedJSON = #"""
        {
          "events": [
            {
              "query": {
                "testArray": [
                  "arrayElem1",
                  2,
                  true
                ],
                "testBool": false,
                "testDictionary": {
                  "key": "val"
                },
                "testDouble": 12.89,
                "testInt": 10,
                "testString": "query"
              }
            }
          ]
        }
        """#
        assertExactMatch(expected: expectedJSON, actual: resultNetworkRequests[0])
    }

    func testDispatchEvent_sendCompleteEvent_sendsPairedCompleteEvent() {
        let edgeEvent = Event(
            name: "Edge Event Completion Request",
            type: EventType.edge,
            source: EventSource.requestContent,
            data: ["xdm": ["testString": "xdm"],
                   "request": [ "sendCompletion": true ]])

        let countDownLatch = CountDownLatch(1)

        MobileCore.dispatch(event: edgeEvent, timeout: TIMEOUT_SEC) { responseEvent in
            guard let responseEvent = responseEvent else {
                XCTFail("Dispatch with responseCallback returned nil event")
                return
            }
            XCTAssertEqual(TestConstants.EventName.CONTENT_COMPLETE, responseEvent.name)
            XCTAssertEqual(TestConstants.EventType.EDGE, responseEvent.type)
            XCTAssertEqual(TestConstants.EventSource.CONTENT_COMPLETE, responseEvent.source)
            XCTAssertEqual(edgeEvent.id, responseEvent.responseID)
            XCTAssertEqual(edgeEvent.id, responseEvent.parentID)
            XCTAssertNotNil(responseEvent.data)

            let expectedJSON = #"""
            {
              "requestId": "STRING_TYPE"
            }
            """#
            self.assertTypeMatch(
                expected: expectedJSON,
                actual: responseEvent,
                pathOptions: CollectionEqualCount(scope: .subtree))
            countDownLatch.countDown()
        }
        XCTAssertEqual(DispatchTimeoutResult.success, countDownLatch.await(timeout: TIMEOUT_SEC))
    }

    // MARK: Client-side store
    func testSendEvent_twoConsecutiveCalls_appendsReceivedClientSideStore() {
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        // swiftlint:disable:next line_length
        let storeResponseBody = "\u{0000}{\"requestId\": \"0000-4a4e-1111-bf5c-abcd\",\"handle\": [{\"payload\": [{\"key\": \"kndctr_testOrg_AdobeOrg_identity\",\"value\": \"hashed_value\",\"maxAge\": 34128000},{\"key\": \"kndctr_testOrg_AdobeOrg_consent_check\",\"value\": \"1\",\"maxAge\": 7200},{\"key\": \"expired_key\",\"value\": \"1\",\"maxAge\": 0}],\"type\": \"state:store\"}]}\n"
        let responseConnection: HttpConnection = HttpConnection(data: storeResponseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // first network call, no stored data
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        var resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(1, resultNetworkRequests.count)

        // Validating element count
        assertTypeMatch(
            expected: createExpectedPayload(),
            actual: resultNetworkRequests[0],
            pathOptions: CollectionEqualCount(scope: .subtree),
            ValueTypeMatch(paths: "meta.konductorConfig.streaming.recordSeparator", scope: .subtree))

        resetTestExpectations()
        mockNetworkService.reset()

        sleep(1)

        // send a new event, should contain previously stored store data
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        Edge.sendEvent(experienceEvent: experienceEvent)

        resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(1, resultNetworkRequests.count)

        let expectedJSON = createExpectedPayload(
            metaPayload: """
            "state": {
              "entries": [
                {
                  "key": "kndctr_testOrg_AdobeOrg_identity",
                  "maxAge": 34128000,
                  "value": "hashed_value"
                },
                {
                  "key": "kndctr_testOrg_AdobeOrg_consent_check",
                  "maxAge": 7200,
                  "value": "1"
                }
              ]
            }
            """
        )

        // NOTE: meta.state.entries can be in any order and can change between runs
        assertTypeMatch(
            expected: expectedJSON,
            actual: resultNetworkRequests[0],
            pathOptions:
                ValueExactMatch(paths: "meta.state.entries", scope: .subtree),
                AnyOrderMatch(paths: "meta.state.entries", scope: .subtree),
                CollectionEqualCount(scope: .subtree))

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_twoConsecutiveCalls_resetBefore_appendsReceivedClientSideStore() {
        // Send the reset event before
        let resetEvent = Event(name: "reset event", type: EventType.genericIdentity, source: EventSource.requestReset, data: nil)
        MobileCore.dispatch(event: resetEvent)

        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        // swiftlint:disable:next line_length
        let storeResponseBody = "\u{0000}{\"requestId\": \"0000-4a4e-1111-bf5c-abcd\",\"handle\": [{\"payload\": [{\"key\": \"kndctr_testOrg_AdobeOrg_identity\",\"value\": \"hashed_value\",\"maxAge\": 34128000},{\"key\": \"kndctr_testOrg_AdobeOrg_consent_check\",\"value\": \"1\",\"maxAge\": 7200},{\"key\": \"expired_key\",\"value\": \"1\",\"maxAge\": 0}],\"type\": \"state:store\"}]}\n"
        let responseConnection: HttpConnection = HttpConnection(data: storeResponseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // First network call, no stored data
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // Validate
        var resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(1, resultNetworkRequests.count)

        assertTypeMatch(
            expected: createExpectedPayload(),
            actual: resultNetworkRequests[0],
            pathOptions: CollectionEqualCount(scope: .subtree),
            ValueTypeMatch(paths: "meta.konductorConfig.streaming.recordSeparator", scope: .subtree))

        resetTestExpectations()
        mockNetworkService.reset()

        sleep(1)

        // Send a new event, should contain previously stored store data
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Validate
        resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(1, resultNetworkRequests.count)

        let expectedJSON = createExpectedPayload(
            metaPayload: """
            "state": {
              "entries": [
                {
                  "key": "kndctr_testOrg_AdobeOrg_identity",
                  "maxAge": 34128000,
                  "value": "hashed_value"
                },
                {
                  "key": "kndctr_testOrg_AdobeOrg_consent_check",
                  "maxAge": 7200,
                  "value": "1"
                }
              ]
            }
            """
        )
        assertTypeMatch(
            expected: expectedJSON,
            actual: resultNetworkRequests[0],
            pathOptions:
                ValueExactMatch(paths: "meta.state.entries", scope: .subtree),
                AnyOrderMatch(paths: "meta.state.entries", scope: .subtree),
                CollectionEqualCount(scope: .subtree))

        // Validate URL
        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_twoConsecutiveCalls_resetInBetween_doesNotAppendReceivedClientSideStore() {
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        // swiftlint:disable:next line_length
        let storeResponseBody = "\u{0000}{\"requestId\": \"0000-4a4e-1111-bf5c-abcd\",\"handle\": [{\"payload\": [{\"key\": \"kndctr_testOrg_AdobeOrg_identity\",\"value\": \"hashed_value\",\"maxAge\": 34128000},{\"key\": \"kndctr_testOrg_AdobeOrg_consent_check\",\"value\": \"1\",\"maxAge\": 7200},{\"key\": \"expired_key\",\"value\": \"1\",\"maxAge\": 0}],\"type\": \"state:store\"}]}\n"
        let responseConnection: HttpConnection = HttpConnection(data: storeResponseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        // first network call, no stored data
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Validate
        var resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(1, resultNetworkRequests.count)

        assertTypeMatch(
            expected: createExpectedPayload(),
            actual: resultNetworkRequests[0],
            pathOptions: CollectionEqualCount(scope: .subtree))

        resetTestExpectations()
        mockNetworkService.reset()

        sleep(1)

        // send the reset event between causing state store to be reset
        let resetEvent = Event(name: "reset event", type: EventType.genericIdentity, source: EventSource.requestReset, data: nil)
        MobileCore.dispatch(event: resetEvent)

        // send a new event, should NOT contain previously stored store data due to reset event
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Validate
        resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(1, resultNetworkRequests.count)

        assertTypeMatch(
            expected: createExpectedPayload(),
            actual: resultNetworkRequests[0],
            pathOptions: CollectionEqualCount(scope: .subtree),
            ValueTypeMatch(paths: "meta.konductorConfig.streaming.recordSeparator", scope: .subtree))
    }

    // MARK: Paired request-response events
    func testSendEvent_receivesResponseEventHandle_sendsResponseEvent_pairedWithTheRequestEventId() {
        setExpectationEvent(type: TestConstants.EventType.EDGE,
                            source: TestConstants.EventSource.REQUEST_CONTENT,
                            expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.EDGE,
                            source: "personalization:decisions",
                            expectedCount: 1)
        // swiftlint:disable:next line_length
        let responseBody = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a26\",\"handle\": [{\"payload\": [{\"id\": \"AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9\",\"scope\": \"buttonColor\",\"items\": [{                           \"schema\": \"https://ns.adobe.com/personalization/json-content-item\",\"data\": {\"content\": {\"value\": \"#D41DBA\"}}}]}],\"type\": \"personalization:decisions\",\"eventIndex\": 0}]}\n"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: httpConnection)

        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil))

        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        assertExpectedEvents(ignoreUnexpectedEvents: true)

        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        let requestId = resultNetworkRequests[0].url.queryParam("requestId")
        let requestEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                    source: TestConstants.EventSource.REQUEST_CONTENT)
        let requestEventUUID = requestEvents[0].id.uuidString
        let responseEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                     source: "personalization:decisions")

        let expectedJSON = #"""
        {
          "type": "personalization:decisions",
          "payload": [
            {
              "id": "AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9",
              "items": [
                {
                  "data": {
                    "content": {
                      "value": "#D41DBA"
                    }
                  },
                  "schema": "https://ns.adobe.com/personalization/json-content-item"
                }
              ],
              "scope": "buttonColor"
            }
          ],
          "requestId": "\#(requestId ?? "")",
          "requestEventId": "\#(requestEventUUID)"
        }
        """#
        assertEqual(expected: expectedJSON, actual: responseEvents[0])
    }

    func testSendEvent_receivesResponseEventWarning_sendsErrorResponseEvent_pairedWithTheRequestEventId() {
        setExpectationEvent(type: TestConstants.EventType.EDGE,
                            source: TestConstants.EventSource.REQUEST_CONTENT,
                            expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.EDGE,
                            source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT,
                            expectedCount: 1)
        let responseBody = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a26\",\"handle\": [],\"warnings\": [{\"status\": 0,\"title\": \"Failed due to unrecoverable system error\",\"report\":{\"eventIndex\":0}}]}\n"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: httpConnection)

        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil))

        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        assertExpectedEvents(ignoreUnexpectedEvents: true)

        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        let requestId = resultNetworkRequests[0].url.queryParam("requestId")
        let requestEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                    source: TestConstants.EventSource.REQUEST_CONTENT)
        let requestEventUUID = requestEvents[0].id.uuidString
        let errorResponseEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                          source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)

        let expectedJSON = #"""
        {
          "status": 0,
          "title": "Failed due to unrecoverable system error",
          "requestId": "\#(requestId ?? "")",
          "requestEventId": "\#(requestEventUUID)"
        }
        """#
        assertEqual(expected: expectedJSON, actual: errorResponseEvents[0])
    }

    // MARK: test persisted hits

    func testSendEvent_withXDMData_sendsExEdgeNetworkRequest_afterPersisting() {
        let error = EdgeEventError(title: nil, detail: "X service is temporarily unable to serve this request. Please try again later.", status: 503, type: "test-type", report: nil)
        let edgeResponse = EdgeResponse(requestId: "test-req-id", handle: nil, errors: [error], warnings: nil)
        let responseData = try? JSONEncoder().encode(edgeResponse)

        // bad connection, hits will be retried
        let responseConnection: HttpConnection = HttpConnection(data: responseData,
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 502,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm",
                                                    "testInt": 10,
                                                    "testBool": false,
                                                    "testDouble": 12.89,
                                                    "testArray": ["arrayElem1", 2, true],
                                                    "testDictionary": ["key": "val"]])
        Edge.sendEvent(experienceEvent: experienceEvent)
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        resetTestExpectations()
        mockNetworkService.reset()

        // good connection, hits sent
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: httpConnection)

        // Default retry time period is 5 sec - provide extra timeout buffer
        // Make sure this timeout is at least double the retry time period
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
    }

    func testSendEvent_withXDMData_sendsExEdgeNetworkRequest_afterPersistingMultipleHits() {
        let error = EdgeEventError(title: nil, detail: "X service is temporarily unable to serve this request. Please try again later.", status: 503, type: nil, report: nil)
        let edgeResponse = EdgeResponse(requestId: "test-req-id", handle: nil, errors: [error], warnings: nil)
        let responseData = try? JSONEncoder().encode(edgeResponse)

        // bad connection, hits will be retried
        let responseConnection: HttpConnection = HttpConnection(data: responseData,
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 502,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm",
                                                    "testInt": 10,
                                                    "testBool": false,
                                                    "testDouble": 12.89,
                                                    "testArray": ["arrayElem1", 2, true],
                                                    "testDictionary": ["key": "val"]])
        Edge.sendEvent(experienceEvent: experienceEvent)
        Edge.sendEvent(experienceEvent: experienceEvent)

        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        resetTestExpectations()
        mockNetworkService.reset()

        // good connection, hits sent
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 2)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: httpConnection)

        // Default retry time period is 5 sec - provide extra timeout buffer
        // Make sure this timeout is at least double the retry time period
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
    }

    func testSendEvent_multiStatusResponse_dispatchesEvents() {
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        // swiftlint:disable line_length
        let response = """
                            {"requestId":"72eaa048-207e-4dde-bf16-0cb2b21336d5","handle":[],"errors":[{"type":"https://ns.adobe.com/aep/errors/EXEG-0201-504","status":504,"title":"The 'com.adobe.experience.platform.ode' service is temporarily unable to serve this request. Please try again later.","report":{"eventIndex":0}}],"warnings":[{"type":"https://ns.adobe.com/aep/errors/EXEG-0204-200","status":200,"title":"A warning occurred while calling the 'com.adobe.audiencemanager' service for this request.","report":{"eventIndex":0,"cause":{"message":"Cannot read related customer for device id: ...","code":202}}}]}
                           """
        // swiftlint:enable line_length
        let responseConnection: HttpConnection = HttpConnection(data: response.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 207,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)

        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.REQUEST_CONTENT, expectedCount: 1) // the send event
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 2) // 2 error events

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        assertExpectedEvents(ignoreUnexpectedEvents: false)

        let resultEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                   source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)

        // Get original requestId and requestEventId
        guard let requestId = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: .post, timeout: TIMEOUT_SEC).first?.url.queryParam("requestId") else {
            XCTFail("Unable to get valid requestId.")
            return
        }
        guard let requestEventId = getDispatchedEventsWith(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.REQUEST_CONTENT).first?.id.uuidString else {
            XCTFail("Unable to get valid requestEventId.")
            return
        }

        let expectedJSON_firstError = """
        {
          "requestEventId": "\(requestEventId)",
          "requestId": "\(requestId)",
          "status": 504,
          "title": "The 'com.adobe.experience.platform.ode' service is temporarily unable to serve this request. Please try again later.",
          "type": "https://ns.adobe.com/aep/errors/EXEG-0201-504"
        }
        """

        assertEqual(expected: expectedJSON_firstError, actual: resultEvents[0])

        let expectedJSON_secondError = """
        {
          "report": {
            "cause": {
              "code": 202,
              "message": "Cannot read related customer for device id: ..."
            }
          },
          "requestEventId": "\(requestEventId)",
          "requestId": "\(requestId)",
          "status": 200,
          "title": "A warning occurred while calling the 'com.adobe.audiencemanager' service for this request.",
          "type": "https://ns.adobe.com/aep/errors/EXEG-0204-200"
        }
        """

        assertEqual(expected: expectedJSON_secondError, actual: resultEvents[1])
    }

    func testSendEvent_fatalError() {
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        let response = """
                            {
                              "type" : "https://ns.adobe.com/aep/errors/EXEG-0104-422",
                              "status": 422,
                              "title" : "Unprocessable Entity",
                              "detail": "Invalid request (report attached). Please check your input and try again.",
                              "report": {
                                "errors": [
                                  "Allowed Adobe version is 1.0 for standard 'Adobe' at index 0",
                                  "Allowed IAB version is 2.0 for standard 'IAB TCF' at index 1",
                                  "IAB consent string value must not be empty for standard 'IAB TCF' at index 1"
                                ],
                                "requestId": "0f8821e5-ed1a-4301-b445-5f336fb50ee8",
                                "orgId": "test@AdobeOrg"
                              }
                            }
                           """
        let responseConnection: HttpConnection = HttpConnection(data: response.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 422,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)

        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.REQUEST_CONTENT, expectedCount: 1) // the send event
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1) // 1 error events

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        assertExpectedEvents(ignoreUnexpectedEvents: false)

        let resultEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                   source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        guard let eventDataDict = resultEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }

        let jsonData = try! JSONSerialization.data(withJSONObject: eventDataDict)
        let expectedEdgeEventError = try? JSONDecoder().decode(EdgeEventError.self, from: response.data(using: .utf8)!)
        let edgeEventError = try? JSONDecoder().decode(EdgeEventError.self, from: jsonData)

        XCTAssertEqual(expectedEdgeEventError, edgeEventError)
    }

    func testSendEvent_fatalError400() {
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        let response = """
                            {
                               "type":"https://ns.adobe.com/aep/errors/EXEG-0003-400",
                               "status":400,
                               "title":"The referenced Config 'bad-edge-config:prod' doesn't exist. Update the reference and try again.",
                               "report":{
                                  "requestId":"FF9E7DBA-128B-4222-9563-F75131219257"
                               }
                            }
                           """
        let responseConnection: HttpConnection = HttpConnection(data: response.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 422,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)

        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.REQUEST_CONTENT, expectedCount: 1) // the send event
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1) // 1 error events

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        assertExpectedEvents(ignoreUnexpectedEvents: false)

        let resultEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                   source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        guard let eventDataDict = resultEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }

        let jsonData = try! JSONSerialization.data(withJSONObject: eventDataDict)
        let expectedEdgeEventError = try? JSONDecoder().decode(EdgeEventError.self, from: response.data(using: .utf8)!)
        let edgeEventError = try? JSONDecoder().decode(EdgeEventError.self, from: jsonData)

        XCTAssertEqual(expectedEdgeEventError, edgeEventError)
    }

    func testSendEvent_recoverableNetworkTransportError_retries() {
        let edgeResponse = EdgeResponse(requestId: "test-req-id", handle: nil, errors: nil, warnings: nil)
        let responseData = try? JSONEncoder().encode(edgeResponse)

        // no connection, hits will be retried
        let responseConnection: HttpConnection = HttpConnection(data: responseData,
                                                                response: nil,
                                                                error: URLError(URLError.notConnectedToInternet) as Error)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm",
                                                    "testInt": 10,
                                                    "testBool": false,
                                                    "testDouble": 12.89,
                                                    "testArray": ["arrayElem1", 2, true],
                                                    "testDictionary": ["key": "val"]])
        Edge.sendEvent(experienceEvent: experienceEvent)
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        resetTestExpectations()
        mockNetworkService.reset()

        // good connection, hits sent
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: httpConnection)

        // Default retry time period is 5 sec - provide extra timeout buffer
        // Make sure this timeout is at least double the retry time period
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
    }

    func testSendEvent_unrecoverableNetworkTransportError_noRetry() {
        let response = """
                            {
                               "title":"Unexpected Error",
                                "detail": "Request to Experience Edge failed with an unknown exception"
                            }
                           """

        // no connection, hits will be retried
        let responseConnection: HttpConnection = HttpConnection(data: response.data(using: .utf8),
                                                                response: nil,
                                                                error: URLError(URLError.cannotFindHost) as Error)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.REQUEST_CONTENT, expectedCount: 1) // the send event
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT, expectedCount: 1) // 1 error events

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        assertExpectedEvents(ignoreUnexpectedEvents: false)

        let resultEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                   source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        guard let eventDataDict = resultEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }

        let jsonData = try! JSONSerialization.data(withJSONObject: eventDataDict)
        let expectedEdgeEventError = try? JSONDecoder().decode(EdgeEventError.self, from: response.data(using: .utf8)!)
        let edgeEventError = try? JSONDecoder().decode(EdgeEventError.self, from: jsonData)

        XCTAssertEqual(expectedEdgeEventError, edgeEventError)
    }

    // MARK: Test Send Event with Configurable Endpoint
    func testSendEvent_withConfigurableEndpoint_withEmptyConfigEndpoint_UsesProduction() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withConfigurableEndpoint_withInvalidConfigEndpoint_UsesProduction() {
        // set to invalid endpoint
        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "invalid-endpoint"])

        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withConfigurableEndpoint_withProductionConfigEndpoint_UsesProduction() {
        // set to production endpoint
        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "prod"])

        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withConfigurableEndpoint_withPreProductionConfigEndpoint_UsesPreProduction() {
        // set to pre-production endpoint
        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "pre-prod"])

        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractPreProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PRE_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PRE_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PRE_PROD_URL_STR, httpMethod: HttpMethod.post)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PRE_PROD_URL_STR))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withConfigurableEndpoint_withIntegrationConfigEndpoint_UsesIntegration() {
        // set to integration endpoint
        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "int"])

        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractIntegrationUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_INTEGRATION_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_INTEGRATION_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_INTEGRATION_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_INTEGRATION_URL_STR))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_edgeNetworkResponseContainsLocationHint_nextSendEventIncludesLocationHint() {
        let hintResponseBody = "\u{0000}{\"requestId\": \"0000-4a4e-1111-bf5c-abcd\",\"handle\": [{\"payload\": [{\"scope\": \"EdgeNetwork\",\"hint\": \"or2\",\"ttlSeconds\": 1800}],\"type\": \"locationHint:result\"}]}\n"
        let responseConnection: HttpConnection = HttpConnection(data: hintResponseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR_OR2_LOC, httpMethod: HttpMethod.post, expectedCount: 1)

        // Send two requests
        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"])
        Edge.sendEvent(experienceEvent: experienceEvent)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        var resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(1, resultNetworkRequests.count)
        XCTAssertTrue(resultNetworkRequests[0].url.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))

        resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR_OR2_LOC, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(1, resultNetworkRequests.count)
        XCTAssertTrue(resultNetworkRequests[0].url.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR_OR2_LOC))
    }

    func testSendEvent_edgeNetworkResponseContainsLocationHint_sendEventDoesNotIncludeExpiredLocationHint() {
        let hintResponseBody = "\u{0000}{\"requestId\": \"0000-4a4e-1111-bf5c-abcd\",\"handle\": [{\"payload\": [{\"scope\": \"EdgeNetwork\",\"hint\": \"or2\",\"ttlSeconds\": 1}],\"type\": \"locationHint:result\"}]}\n"
        let responseConnection: HttpConnection = HttpConnection(data: hintResponseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 2)

        // Send two requests
        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"])
        let expectation = XCTestExpectation(description: "Send Event completion closure")
        Edge.sendEvent(experienceEvent: experienceEvent) {_ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT_SEC)

        usleep(1500000) // sleep test thread to expire received location hint
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(2, resultNetworkRequests.count)
        XCTAssertTrue(resultNetworkRequests[0].url.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertTrue(resultNetworkRequests[1].url.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
    }

    func getEdgeEventError(message: String, code: String) -> EdgeEventError {
        let data = """
             {
                "message": "\(message)",
                "code": "\(code)"
             }
         """.data(using: .utf8)
        let decoder = JSONDecoder()
        return try! decoder.decode(EdgeEventError.self, from: data!) // swiftlint:disable:this force_unwrapping
    }

    func getEdgeEventError(message: String, code: String, namespace: String, index: Int) -> EdgeEventError {
        let data = """
             {
                "message": "\(message)",
                "code": "\(code)",
                "namespace": "\(namespace)",
                "eventIndex": \(index)
             }
         """.data(using: .utf8)
        let decoder = JSONDecoder()
        return try! decoder.decode(EdgeEventError.self, from: data!) // swiftlint:disable:this force_unwrapping
    }

    /// Generates a JSON string representing a network request payload. It
    /// allows the injection of custom content for `events` and `meta` sections of the payload.
    ///
    /// - Parameters:
    ///   - eventsPayload: An optional JSON string to be included in the `events` section of the payload.
    ///                    If `nil`, a default JSON structure with placeholder values is used.
    ///   - metaPayload: A JSON string to be included in the `meta` section of the payload. Defaults
    ///                  to an empty string, which means no additional content will be added to the `meta` section.
    /// - Returns: A JSON string representing the complete network request payload.
    private func createExpectedPayload(eventsPayload: String? = nil, metaPayload: String = "") -> String {
        let eventsPayload = eventsPayload ?? """
        {
          "xdm": {
            "_id": "STRING_TYPE",
            "testString": "STRING_TYPE",
            "timestamp": "STRING_TYPE"
          }
        }
        """

        return #"""
        {
          "events": [
            \#(eventsPayload)
          ],
          "meta": {
            "konductorConfig": {
              "streaming": {
                "enabled": true,
                "recordSeparator": "STRING_TYPE",
                "lineFeed": "\n"
              }
            },
            \#(metaPayload)
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
              "version": "\#(MobileCore.extensionVersion)+\#(Edge.extensionVersion)",
              "name": "\#(EXPECTED_BASE_PATH)"
            }
          }
        }
        """#
    }
}

extension Int {
    init(_ val: Bool) {
        self = val ? 1 : 0
    }
}

extension EdgeEventHandle {
    func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
}

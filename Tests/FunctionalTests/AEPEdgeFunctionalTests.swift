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
import Foundation
import XCTest

// swiftlint:disable type_body_length

/// End-to-end testing for the AEPEdge public APIs
class AEPEdgeFunctionalTests: TestBase {
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
       if #available(iOS 17, tvOS 17, *) {
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
        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])

        assertExpectedEvents(ignoreUnexpectedEvents: false, timeout: 2)
        resetTestExpectations()
        mockNetworkService.reset()
    }

    // Runs after each test case
    override func tearDown() {
        super.tearDown()

        mockNetworkService.reset()
    }

    func testUnregistered() {
        let waitForUnregistration = CountDownLatch(1)
        MobileCore.unregisterExtension(Edge.self, {
            print("Extension unregistration is complete")
            waitForUnregistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForUnregistration.await(timeout: 2))
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
        guard let eventDataDict = resultEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict: eventDataDict)
        XCTAssertEqual(8, eventData.count)
        XCTAssertEqual("xdm", eventData["xdm.testString"] as? String)
        XCTAssertEqual(10, eventData["xdm.testInt"] as? Int)
        XCTAssertEqual(false, eventData["xdm.testBool"] as? Bool)
        XCTAssertEqual(12.89, eventData["xdm.testDouble"] as? Double)
        XCTAssertEqual("arrayElem1", eventData["xdm.testArray[0]"] as? String)
        XCTAssertEqual(2, eventData["xdm.testArray[1]"] as? Int)
        XCTAssertEqual(true, eventData["xdm.testArray[2]"] as? Bool)
        XCTAssertEqual("val", eventData["xdm.testDictionary.key"] as? String)
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
        guard let eventDataDict = resultEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict: eventDataDict)
        XCTAssertEqual(9, eventData.count)
        XCTAssertEqual("xdm", eventData["xdm.testString"] as? String)
        XCTAssertEqual("stringValue", eventData["data.testDataString"] as? String)
        XCTAssertEqual(101, eventData["data.testDataInt"] as? Int)
        XCTAssertEqual(true, eventData["data.testDataBool"] as? Bool)
        XCTAssertEqual(13.66, eventData["data.testDataDouble"] as? Double)
        XCTAssertEqual("arrayElem1", eventData["data.testDataArray[0]"] as? String)
        XCTAssertEqual(2, eventData["data.testDataArray[1]"] as? Int)
        XCTAssertEqual(true, eventData["data.testDataArray[2]"] as? Bool)
        XCTAssertEqual("val", eventData["data.testDataDictionary.key"] as? String)
    }

    func testSendEvent_withXDMDataAndNilData_sendsCorrectRequestEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.REQUEST_CONTENT)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                   source: TestConstants.EventSource.REQUEST_CONTENT)
        guard let eventDataDict = resultEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict: eventDataDict)
        XCTAssertEqual(1, eventData.count)
        XCTAssertEqual("xdm", eventData["xdm.testString"] as? String)
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
        guard let eventDataDict = resultEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict: eventDataDict)
        XCTAssertEqual(9, eventData.count)
        XCTAssertEqual("query", eventData["query.testString"] as? String)
        XCTAssertEqual(10, eventData["query.testInt"] as? Int)
        XCTAssertEqual(false, eventData["query.testBool"] as? Bool)
        XCTAssertEqual(12.89, eventData["query.testDouble"] as? Double)
        XCTAssertEqual("arrayElem1", eventData["query.testArray[0]"] as? String)
        XCTAssertEqual(2, eventData["query.testArray[1]"] as? Int)
        XCTAssertEqual(true, eventData["query.testArray[2]"] as? Bool)
        XCTAssertEqual("val", eventData["query.testDictionary.key"] as? String)
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
        guard let eventDataDict = resultEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict: eventDataDict)
        XCTAssertEqual(1, eventData.count)
        XCTAssertNil(eventDataDict["query"])
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
        guard let eventDataDict = resultEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict: eventDataDict)
        XCTAssertEqual(1, eventData.count)
        XCTAssertNil(eventDataDict["query"])
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
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        let requestBody = resultNetworkRequests[0].getFlattenedBody()
        XCTAssertEqual(19, requestBody.count)
        XCTAssertEqual(true, requestBody["meta.konductorConfig.streaming.enabled"] as? Bool)
        XCTAssertEqual(expectedRecordSeparatorString, requestBody["meta.konductorConfig.streaming.recordSeparator"] as? String)
        XCTAssertEqual("\n", requestBody["meta.konductorConfig.streaming.lineFeed"] as? String)
        XCTAssertNotNil(requestBody["xdm.identityMap.ECID[0].id"] as? String)
        XCTAssertNotNil(requestBody["xdm.identityMap.ECID[0].authenticatedState"] as? String)
        XCTAssertNotNil(requestBody["xdm.identityMap.ECID[0].primary"] as? Bool)
        XCTAssertNotNil(requestBody["events[0].xdm._id"] as? String)
        XCTAssertNotNil(requestBody["events[0].xdm.timestamp"] as? String)
        XCTAssertEqual("xdm", requestBody["events[0].xdm.testString"] as? String)
        XCTAssertEqual(10, requestBody["events[0].xdm.testInt"] as? Int)
        XCTAssertEqual(false, requestBody["events[0].xdm.testBool"] as? Bool)
        XCTAssertEqual(12.89, requestBody["events[0].xdm.testDouble"] as? Double)
        XCTAssertEqual("arrayElem1", requestBody["events[0].xdm.testArray[0]"] as? String)
        XCTAssertEqual(2, requestBody["events[0].xdm.testArray[1]"] as? Int)
        XCTAssertEqual(true, requestBody["events[0].xdm.testArray[2]"] as? Bool)
        XCTAssertEqual("val", requestBody["events[0].xdm.testDictionary.key"] as? String)
        XCTAssertEqual("app", requestBody["xdm.implementationDetails.environment"] as? String)
        XCTAssertEqual("\(MobileCore.extensionVersion)+\(Edge.extensionVersion)", requestBody["xdm.implementationDetails.version"] as? String)
        XCTAssertEqual(EXPECTED_BASE_PATH, requestBody["xdm.implementationDetails.name"] as? String)

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
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        let requestBody = resultNetworkRequests[0].getFlattenedBody()
        XCTAssertEqual(20, requestBody.count)
        XCTAssertEqual(true, requestBody["meta.konductorConfig.streaming.enabled"] as? Bool)
        XCTAssertEqual(expectedRecordSeparatorString, requestBody["meta.konductorConfig.streaming.recordSeparator"] as? String)
        XCTAssertNotNil(requestBody["xdm.identityMap.ECID[0].id"] as? String)
        XCTAssertNotNil(requestBody["xdm.identityMap.ECID[0].authenticatedState"] as? String)
        XCTAssertNotNil(requestBody["xdm.identityMap.ECID[0].primary"] as? Bool)
        XCTAssertNotNil(requestBody["events[0].xdm._id"] as? String)
        XCTAssertNotNil(requestBody["events[0].xdm.timestamp"] as? String)
        XCTAssertEqual("xdm", requestBody["events[0].xdm.testString"] as? String)
        XCTAssertEqual("stringValue", requestBody["events[0].data.testDataString"] as? String)
        XCTAssertEqual(101, requestBody["events[0].data.testDataInt"] as? Int)
        XCTAssertEqual(true, requestBody["events[0].data.testDataBool"] as? Bool)
        XCTAssertEqual(13.66, requestBody["events[0].data.testDataDouble"] as? Double)
        XCTAssertEqual("arrayElem1", requestBody["events[0].data.testDataArray[0]"] as? String)
        XCTAssertEqual(2, requestBody["events[0].data.testDataArray[1]"] as? Int)
        XCTAssertEqual(true, requestBody["events[0].data.testDataArray[2]"] as? Bool)
        XCTAssertEqual("val", requestBody["events[0].data.testDataDictionary.key"] as? String)
        XCTAssertEqual("app", requestBody["xdm.implementationDetails.environment"] as? String)
        XCTAssertEqual("\(MobileCore.extensionVersion)+\(Edge.extensionVersion)", requestBody["xdm.implementationDetails.version"] as? String)
        XCTAssertEqual(EXPECTED_BASE_PATH, requestBody["xdm.implementationDetails.name"] as? String)

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
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        let requestBody = resultNetworkRequests[0].getFlattenedBody()
        XCTAssertEqual(17, requestBody.count)
        XCTAssertEqual(true, requestBody["meta.konductorConfig.streaming.enabled"] as? Bool)
        XCTAssertEqual(expectedRecordSeparatorString, requestBody["meta.konductorConfig.streaming.recordSeparator"] as? String)
        XCTAssertEqual("\n", requestBody["meta.konductorConfig.streaming.lineFeed"] as? String)
        XCTAssertNotNil(requestBody["xdm.identityMap.ECID[0].id"] as? String)
        XCTAssertNotNil(requestBody["xdm.identityMap.ECID[0].authenticatedState"] as? String)
        XCTAssertNotNil(requestBody["xdm.identityMap.ECID[0].primary"] as? Bool)
        XCTAssertNotNil(requestBody["events[0].xdm._id"] as? String)
        XCTAssertNotNil(requestBody["events[0].xdm.timestamp"] as? String)
        XCTAssertEqual(true, requestBody["events[0].xdm.boolObject"] as? Bool)
        XCTAssertEqual(100, requestBody["events[0].xdm.intObject"] as? Int)
        XCTAssertEqual("testWithXdmSchema", requestBody["events[0].xdm.stringObject"] as? String)
        XCTAssertEqual(3.42, requestBody["events[0].xdm.doubleObject"] as? Double)
        XCTAssertEqual("testInnerObject", requestBody["events[0].xdm.xdmObject.innerKey"] as? String)
        XCTAssertEqual("abc123def", requestBody["events[0].meta.collect.datasetId"] as? String)
        XCTAssertEqual("app", requestBody["xdm.implementationDetails.environment"] as? String)
        XCTAssertEqual("\(MobileCore.extensionVersion)+\(Edge.extensionVersion)", requestBody["xdm.implementationDetails.version"] as? String)
        XCTAssertEqual(EXPECTED_BASE_PATH, requestBody["xdm.implementationDetails.name"] as? String)

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
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
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
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
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
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
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
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        let requestBody = resultNetworkRequests[0].getFlattenedBody()

        XCTAssertEqual("query", requestBody["events[0].query.testString"] as? String)
        XCTAssertEqual(10, requestBody["events[0].query.testInt"] as? Int)
        XCTAssertEqual(false, requestBody["events[0].query.testBool"] as? Bool)
        XCTAssertEqual(12.89, requestBody["events[0].query.testDouble"] as? Double)
        XCTAssertEqual("arrayElem1", requestBody["events[0].query.testArray[0]"] as? String)
        XCTAssertEqual(2, requestBody["events[0].query.testArray[1]"] as? Int)
        XCTAssertEqual(true, requestBody["events[0].query.testArray[2]"] as? Bool)
        XCTAssertEqual("val", requestBody["events[0].query.testDictionary.key"] as? String)
    }

    func testDispatchEvent_sendCompleteEvent_sendsPairedCompleteEvent() {
        let edgeEvent = Event(
            name: "Edge Event Completion Request",
            type: EventType.edge,
            source: EventSource.requestContent,
            data: ["xdm": ["testString": "xdm"],
                   "request": [ "sendCompletion": true ]])

        let countDownLatch = CountDownLatch(1)

        MobileCore.dispatch(event: edgeEvent, timeout: 2) { responseEvent in
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

            let flattenedData = flattenDictionary(dict: responseEvent.data ?? [:])
            XCTAssertEqual(1, flattenedData.count)
            XCTAssertNotNil(flattenedData["requestId"] as? String)
            countDownLatch.countDown()
        }
        XCTAssertEqual(DispatchTimeoutResult.success, countDownLatch.await(timeout: 3))
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
        var resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, resultNetworkRequests.count)
        var requestBody = resultNetworkRequests[0].getFlattenedBody()
        XCTAssertEqual(12, requestBody.count)
        resetTestExpectations()
        mockNetworkService.reset()

        sleep(1)

        // send a new event, should contain previously stored store data
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        Edge.sendEvent(experienceEvent: experienceEvent)

        resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, resultNetworkRequests.count)
        requestBody = resultNetworkRequests[0].getFlattenedBody()
        XCTAssertEqual(18, requestBody.count)

        guard let firstStore = requestBody["meta.state.entries[0].key"] as? String,
              let index = firstStore == "kndctr_testOrg_AdobeOrg_identity" ? false : true else {
            XCTFail("Client-side store not found")
            return
        }
        XCTAssertEqual("kndctr_testOrg_AdobeOrg_identity", requestBody["meta.state.entries[\(Int(index))].key"] as? String)
        XCTAssertEqual("hashed_value",
                       requestBody["meta.state.entries[\(Int(index))].value"] as? String)
        XCTAssertEqual(34128000, requestBody["meta.state.entries[\(Int(index))].maxAge"] as? Int)
        XCTAssertEqual("kndctr_testOrg_AdobeOrg_consent_check", requestBody["meta.state.entries[\(Int(!index))].key"] as? String)
        XCTAssertEqual("1", requestBody["meta.state.entries[\(Int(!index))].value"] as? String)
        XCTAssertEqual(7200, requestBody["meta.state.entries[\(Int(!index))].maxAge"] as? Int)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_twoConsecutiveCalls_resetBefore_appendsReceivedClientSideStore() {
        // send the reset event before
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

        // first network call, no stored data
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        var resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, resultNetworkRequests.count)
        var requestBody = resultNetworkRequests[0].getFlattenedBody()
        XCTAssertEqual(12, requestBody.count)
        resetTestExpectations()
        mockNetworkService.reset()

        sleep(1)

        // send a new event, should contain previously stored store data
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        Edge.sendEvent(experienceEvent: experienceEvent)

        resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, resultNetworkRequests.count)
        requestBody = resultNetworkRequests[0].getFlattenedBody()
        XCTAssertEqual(18, requestBody.count)

        guard let firstStore = requestBody["meta.state.entries[0].key"] as? String,
              let index = firstStore == "kndctr_testOrg_AdobeOrg_identity" ? false : true else {
            XCTFail("Client-side store not found")
            return
        }
        XCTAssertEqual("kndctr_testOrg_AdobeOrg_identity", requestBody["meta.state.entries[\(Int(index))].key"] as? String)
        XCTAssertEqual("hashed_value",
                       requestBody["meta.state.entries[\(Int(index))].value"] as? String)
        XCTAssertEqual(34128000, requestBody["meta.state.entries[\(Int(index))].maxAge"] as? Int)
        XCTAssertEqual("kndctr_testOrg_AdobeOrg_consent_check", requestBody["meta.state.entries[\(Int(!index))].key"] as? String)
        XCTAssertEqual("1", requestBody["meta.state.entries[\(Int(!index))].value"] as? String)
        XCTAssertEqual(7200, requestBody["meta.state.entries[\(Int(!index))].maxAge"] as? Int)

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
        Edge.sendEvent(experienceEvent: experienceEvent)

        // first network call, no stored data
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        var resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, resultNetworkRequests.count)
        var requestBody = resultNetworkRequests[0].getFlattenedBody()
        XCTAssertEqual(12, requestBody.count)
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

        resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, resultNetworkRequests.count)
        requestBody = resultNetworkRequests[0].getFlattenedBody()
        XCTAssertEqual(12, requestBody.count)

        XCTAssertNil(requestBody["meta.state"]) // no state should be appended
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

        mockNetworkService.assertAllNetworkRequestExpectations()
        assertExpectedEvents(ignoreUnexpectedEvents: true)

        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        let requestId = resultNetworkRequests[0].url.queryParam("requestId")
        let requestEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                    source: TestConstants.EventSource.REQUEST_CONTENT)
        let requestEventUUID = requestEvents[0].id.uuidString
        let responseEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                     source: "personalization:decisions")
        guard let eventDataDict = responseEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict: eventDataDict)
        XCTAssertEqual(7, eventData.count)
        XCTAssertEqual("personalization:decisions", eventData["type"] as? String)
        XCTAssertEqual("AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9", eventData["payload[0].id"] as? String)
        XCTAssertEqual("#D41DBA", eventData["payload[0].items[0].data.content.value"] as? String)
        XCTAssertEqual("https://ns.adobe.com/personalization/json-content-item", eventData["payload[0].items[0].schema"] as? String)
        XCTAssertEqual("buttonColor", eventData["payload[0].scope"] as? String)
        XCTAssertEqual("buttonColor", eventData["payload[0].scope"] as? String)
        XCTAssertEqual(requestId, eventData["requestId"] as? String)
        XCTAssertEqual(requestEventUUID, eventData["requestEventId"] as? String)
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

        mockNetworkService.assertAllNetworkRequestExpectations()
        assertExpectedEvents(ignoreUnexpectedEvents: true)

        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        let requestId = resultNetworkRequests[0].url.queryParam("requestId")
        let requestEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                    source: TestConstants.EventSource.REQUEST_CONTENT)
        let requestEventUUID = requestEvents[0].id.uuidString
        let errorResponseEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                          source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        guard let eventDataDict = errorResponseEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict: eventDataDict)
        XCTAssertEqual(4, eventData.count)
        XCTAssertEqual(0, eventData["status"] as? Int)
        XCTAssertEqual("Failed due to unrecoverable system error", eventData["title"] as? String)
        XCTAssertEqual(requestId, eventData["requestId"] as? String)
        XCTAssertEqual(requestEventUUID, eventData["requestEventId"] as? String)
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
        mockNetworkService.assertAllNetworkRequestExpectations()
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

        mockNetworkService.assertAllNetworkRequestExpectations()
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

        mockNetworkService.assertAllNetworkRequestExpectations()
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

        mockNetworkService.assertAllNetworkRequestExpectations()
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

        mockNetworkService.assertAllNetworkRequestExpectations()
        assertExpectedEvents(ignoreUnexpectedEvents: false)

        let resultEvents = getDispatchedEventsWith(type: TestConstants.EventType.EDGE,
                                                   source: TestConstants.EventSource.ERROR_RESPONSE_CONTENT)
        guard let eventDataDict = resultEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict: eventDataDict)
        XCTAssertEqual(5, eventData.count)
        XCTAssertEqual(eventData["status"] as? Int, 504)
        XCTAssertEqual(eventData["type"] as? String, "https://ns.adobe.com/aep/errors/EXEG-0201-504")
        XCTAssertEqual(eventData["title"] as? String, "The 'com.adobe.experience.platform.ode' service is temporarily unable to serve this request. Please try again later.")

        guard let eventDataDict1 = resultEvents[1].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData1 = flattenDictionary(dict: eventDataDict1)
        XCTAssertEqual(7, eventData1.count)
        XCTAssertEqual(eventData1["status"] as? Int, 200)
        XCTAssertEqual(eventData1["type"] as? String, "https://ns.adobe.com/aep/errors/EXEG-0204-200")
        XCTAssertEqual(eventData1["title"] as? String, "A warning occurred while calling the 'com.adobe.audiencemanager' service for this request.")
        XCTAssertEqual(eventData1["report.cause.message"] as? String, "Cannot read related customer for device id: ...")
        XCTAssertEqual(eventData1["report.cause.code"] as? Int, 202)
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

        mockNetworkService.assertAllNetworkRequestExpectations()
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

        mockNetworkService.assertAllNetworkRequestExpectations()
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
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)

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
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)

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
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)

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
        mockNetworkService.assertAllNetworkRequestExpectations()
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
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_INTEGRATION_URL_STR, httpMethod: HttpMethod.post)

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
        mockNetworkService.assertAllNetworkRequestExpectations()
        var resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, resultNetworkRequests.count)
        XCTAssertTrue(resultNetworkRequests[0].url.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_INTERACT_PROD_URL_STR))

        resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR_OR2_LOC, httpMethod: HttpMethod.post)
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
        wait(for: [expectation], timeout: 2)

        usleep(1500000) // sleep test thread to expire received location hint
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post)
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

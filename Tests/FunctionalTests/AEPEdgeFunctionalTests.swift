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
import AEPIdentity
import AEPServices
import Foundation
import XCTest

/// End-to-end testing for the AEPEdge public APIs
class AEPEdgeFunctionalTests: FunctionalTestBase {
    private let event1 = Event(name: "e1", type: "eventType", source: "eventSource", data: nil)
    private let event2 = Event(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private let exEdgeInteractUrlString = "https://edge.adobedc.net/ee/v1/interact"
    private let exEdgeInteractUrl = URL(string: "https://edge.adobedc.net/ee/v1/interact")! // swiftlint:disable:this force_unwrapping
    private let responseBody = "{\"test\": \"json\"}"

    class TestResponseHandler: EdgeResponseHandler {
        var onResponseReceivedData: [String: Any] = [:] // latest data received in the onResponse callback
        var countDownLatch: CountDownLatch

        init(expectedCount: Int32) {
            countDownLatch = CountDownLatch(expectedCount)
        }

        func onResponse(data: [String: Any]) {
            onResponseReceivedData = data
            countDownLatch.countDown()
        }

        func await() {
            _ = countDownLatch.await()
        }
    }

    public class override func setUp() {
        super.setUp()
        FunctionalTestBase.debugEnabled = true
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        FileManager.default.clearCache()

        // hub shared state update for 2 extension versions (InstrumentedExtension (registered in FunctionalTestBase), Identity, Edge), Identity and Config shared state updates
        setExpectationEvent(type: FunctionalTestConst.EventType.HUB, source: FunctionalTestConst.EventSource.SHARED_STATE, expectedCount: 4)

        // expectations for update config request&response events
        setExpectationEvent(type: FunctionalTestConst.EventType.CONFIGURATION, source: FunctionalTestConst.EventSource.REQUEST_CONTENT, expectedCount: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.CONFIGURATION, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT, expectedCount: 1)

        // expectations for Identity force sync
        setExpectationEvent(type: FunctionalTestConst.EventType.IDENTITY, source: FunctionalTestConst.EventSource.RESPONSE_IDENTITY, expectedCount: 2)

        // wait for async registration because the EventHub is already started in FunctionalTestBase
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([Identity.self, Edge.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))
        MobileCore.updateConfigurationWith(configDict: ["global.privacy": "optedin",
                                                        "experienceCloud.org": "testOrg@AdobeOrg",
                                                        "edge.configId": "12345-example"])

        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
    }

    // MARK: test request event format

    func testSendEvent_withXDMData_sendsCorrectRequestEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.REQUEST_CONTENT)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm",
                                                    "testInt": 10,
                                                    "testBool": false,
                                                    "testDouble": 12.89,
                                                    "testArray": ["arrayElem1", 2, true],
                                                    "testDictionary": ["key": "val"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE,
                                                   source: FunctionalTestConst.EventSource.REQUEST_CONTENT)
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
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.REQUEST_CONTENT)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: ["testDataString": "stringValue",
                                                                                 "testDataInt": 101,
                                                                                 "testDataBool": true,
                                                                                 "testDataDouble": 13.66,
                                                                                 "testDataArray": ["arrayElem1", 2, true],
                                                                                 "testDataDictionary": ["key": "val"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE,
                                                   source: FunctionalTestConst.EventSource.REQUEST_CONTENT)
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
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE, source: FunctionalTestConst.EventSource.REQUEST_CONTENT)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE,
                                                   source: FunctionalTestConst.EventSource.REQUEST_CONTENT)
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

    // MARK: test network request format

    func testSendEvent_withXDMData_sendsExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm",
                                                    "testInt": 10,
                                                    "testBool": false,
                                                    "testDouble": 12.89,
                                                    "testArray": ["arrayElem1", 2, true],
                                                    "testDictionary": ["key": "val"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertNetworkRequestsCount()
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)
        let requestBody = getFlattenNetworkRequestBody(resultNetworkRequests[0])
        XCTAssertEqual(14, requestBody.count)
        XCTAssertEqual(true, requestBody["meta.konductorConfig.streaming.enabled"] as? Bool)
        XCTAssertEqual("\u{0000}", requestBody["meta.konductorConfig.streaming.recordSeparator"] as? String)
        XCTAssertEqual("\n", requestBody["meta.konductorConfig.streaming.lineFeed"] as? String)
        XCTAssertNotNil(requestBody["xdm.identityMap.ECID[0].id"] as? String)
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

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(exEdgeInteractUrlString))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withXDMDataAndCustomData_sendsExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: ["testDataString": "stringValue",
                                                                                 "testDataInt": 101,
                                                                                 "testDataBool": true,
                                                                                 "testDataDouble": 13.66,
                                                                                 "testDataArray": ["arrayElem1", 2, true],
                                                                                 "testDataDictionary": ["key": "val"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertNetworkRequestsCount()
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)
        let requestBody = getFlattenNetworkRequestBody(resultNetworkRequests[0])
        XCTAssertEqual(15, requestBody.count)
        XCTAssertEqual(true, requestBody["meta.konductorConfig.streaming.enabled"] as? Bool)
        XCTAssertEqual("\u{0000}", requestBody["meta.konductorConfig.streaming.recordSeparator"] as? String)
        XCTAssertEqual("\n", requestBody["meta.konductorConfig.streaming.lineFeed"] as? String)
        XCTAssertNotNil(requestBody["xdm.identityMap.ECID[0].id"] as? String)
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

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(exEdgeInteractUrlString))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withXDMSchema_sendsExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)

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
        assertNetworkRequestsCount()
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)
        let requestBody = getFlattenNetworkRequestBody(resultNetworkRequests[0])
        XCTAssertEqual(12, requestBody.count)
        XCTAssertEqual(true, requestBody["meta.konductorConfig.streaming.enabled"] as? Bool)
        XCTAssertEqual("\u{0000}", requestBody["meta.konductorConfig.streaming.recordSeparator"] as? String)
        XCTAssertEqual("\n", requestBody["meta.konductorConfig.streaming.lineFeed"] as? String)
        XCTAssertNotNil(requestBody["xdm.identityMap.ECID[0].id"] as? String)
        XCTAssertNotNil(requestBody["events[0].xdm._id"] as? String)
        XCTAssertNotNil(requestBody["events[0].xdm.timestamp"] as? String)
        XCTAssertEqual(true, requestBody["events[0].xdm.boolObject"] as? Bool)
        XCTAssertEqual(100, requestBody["events[0].xdm.intObject"] as? Int)
        XCTAssertEqual("testWithXdmSchema", requestBody["events[0].xdm.stringObject"] as? String)
        XCTAssertEqual(3.42, requestBody["events[0].xdm.doubleObject"] as? Double)
        XCTAssertEqual("testInnerObject", requestBody["events[0].xdm.xdmObject.innerKey"] as? String)
        XCTAssertEqual("abc123def", requestBody["events[0].meta.collect.datasetId"] as? String)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(exEdgeInteractUrlString))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withEmptyXDMSchema_doesNotSendExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)

        let experienceEvent = ExperienceEvent(xdm: TestXDMSchema())
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    func testSendEvent_withEmptyXDMSchemaAndEmptyData_doesNotSendExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)

        let experienceEvent = ExperienceEvent(xdm: TestXDMSchema(), data: [:])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    func testSendEvent_withEmptyXDMSchemaAndNilData_doesNotSendExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)

        let experienceEvent = ExperienceEvent(xdm: TestXDMSchema(), data: nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    // MARK: Client-side store
    func testSendEvent_twoConsecutiveCalls_appendsReceivedClientSideStore() {
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)
        // swiftlint:disable:next line_length
        let storeResponseBody = "\u{0000}{\"requestId\": \"0000-4a4e-1111-bf5c-abcd\",\"handle\": [{\"payload\": [{\"key\": \"kndctr_testOrg_AdobeOrg_identity\",\"value\": \"hashed_value\",\"maxAge\": 34128000},{\"key\": \"kndctr_testOrg_AdobeOrg_consent_check\",\"value\": \"1\",\"maxAge\": 7200},{\"key\": \"expired_key\",\"value\": \"1\",\"maxAge\": 0}],\"type\": \"state:store\"}]}\n"
        let responseConnection: HttpConnection = HttpConnection(data: storeResponseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm"], data: nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // first network call, no stored data
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)
        var resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, resultNetworkRequests.count)
        var requestBody = getFlattenNetworkRequestBody(resultNetworkRequests[0])
        XCTAssertEqual(7, requestBody.count)
        resetTestExpectations()

        sleep(1)

        // send a new event, should contain previously stored store data
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        Edge.sendEvent(experienceEvent: experienceEvent)

        resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, resultNetworkRequests.count)
        requestBody = getFlattenNetworkRequestBody(resultNetworkRequests[0])
        XCTAssertEqual(13, requestBody.count)

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
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(exEdgeInteractUrlString))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    // MARK: Paired request-response events
    func testSendEvent_receivesResponseEventHandle_sendsResponseEvent_pairedWithTheRequestEventId() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE,
                            source: FunctionalTestConst.EventSource.REQUEST_CONTENT,
                            expectedCount: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE,
                            source: FunctionalTestConst.EventSource.RESPONSE_CONTENT,
                            expectedCount: 1)
        // swiftlint:disable:next line_length
        let responseBody = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a26\",\"handle\": [{\"payload\": [{\"id\": \"AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9\",\"scope\": \"buttonColor\",\"items\": [{                           \"schema\": \"https://ns.adobe.com/personalization/json-content-item\",\"data\": {\"content\": {\"value\": \"#D41DBA\"}}}]}],\"type\": \"personalization:decisions\",\"eventIndex\": 0}]}\n"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil))

        assertNetworkRequestsCount()
        assertExpectedEvents(ignoreUnexpectedEvents: true)

        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)
        let requestId = resultNetworkRequests[0].url.queryParam("requestId")
        let requestEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE,
                                                    source: FunctionalTestConst.EventSource.REQUEST_CONTENT)
        let requestEventUUID = requestEvents[0].id.uuidString
        let responseEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE,
                                                     source: FunctionalTestConst.EventSource.RESPONSE_CONTENT)
        guard let eventDataDict = responseEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict: eventDataDict)
        XCTAssertEqual(8, eventData.count)
        XCTAssertEqual("personalization:decisions", eventData["type"] as? String)
        XCTAssertEqual("AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9", eventData["payload[0].id"] as? String)
        XCTAssertEqual("#D41DBA", eventData["payload[0].items[0].data.content.value"] as? String)
        XCTAssertEqual("https://ns.adobe.com/personalization/json-content-item", eventData["payload[0].items[0].schema"] as? String)
        XCTAssertEqual("buttonColor", eventData["payload[0].scope"] as? String)
        XCTAssertEqual(0, eventData["eventIndex"] as? Int)
        XCTAssertEqual("buttonColor", eventData["payload[0].scope"] as? String)
        XCTAssertEqual(requestId, eventData["requestId"] as? String)
        XCTAssertEqual(requestEventUUID, eventData["requestEventId"] as? String)
    }

    func testSendEvent_receivesResponseEventWarning_sendsErrorResponseEvent_pairedWithTheRequestEventId() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE,
                            source: FunctionalTestConst.EventSource.REQUEST_CONTENT,
                            expectedCount: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE,
                            source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT,
                            expectedCount: 1)
        let responseBody = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a26\",\"handle\": [],\"warnings\": [{\"eventIndex\": 0,\"code\": \"personalization:0\",\"message\": \"Failed due to unrecoverable system error\"}]}\n"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil))

        assertNetworkRequestsCount()
        assertExpectedEvents(ignoreUnexpectedEvents: true)

        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)
        let requestId = resultNetworkRequests[0].url.queryParam("requestId")
        let requestEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE,
                                                    source: FunctionalTestConst.EventSource.REQUEST_CONTENT)
        let requestEventUUID = requestEvents[0].id.uuidString
        let errorResponseEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.EDGE,
                                                          source: FunctionalTestConst.EventSource.ERROR_RESPONSE_CONTENT)
        guard let eventDataDict = errorResponseEvents[0].data else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict: eventDataDict)
        XCTAssertEqual(5, eventData.count)
        XCTAssertEqual("personalization:0", eventData["code"] as? String)
        XCTAssertEqual("Failed due to unrecoverable system error", eventData["message"] as? String)
        XCTAssertEqual(0, eventData["eventIndex"] as? Int)
        XCTAssertEqual(requestId, eventData["requestId"] as? String)
        XCTAssertEqual(requestEventUUID, eventData["requestEventId"] as? String)
    }

    func testSendEvent_receivesResponseEventHandle_callsResponseHandler() {
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE,
                            source: FunctionalTestConst.EventSource.REQUEST_CONTENT,
                            expectedCount: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.EDGE,
                            source: FunctionalTestConst.EventSource.RESPONSE_CONTENT,
                            expectedCount: 1)
        // swiftlint:disable:next line_length
        let responseBody = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a26\",\"handle\": [{\"payload\": [{\"id\": \"AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9\",\"scope\": \"buttonColor\",\"items\": [{                           \"schema\": \"https://ns.adobe.com/personalization/json-content-item\",\"data\": {\"content\": {\"value\": \"#D41DBA\"}}}]}],\"type\": \"personalization:decisions\",\"eventIndex\": 0}]}\n"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)
        let responseHandler = TestResponseHandler(expectedCount: 1)

        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                        data: nil),
                       responseHandler: responseHandler)

        assertNetworkRequestsCount()
        assertExpectedEvents(ignoreUnexpectedEvents: true)
        responseHandler.await()

        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)
        XCTAssertEqual(1, resultNetworkRequests.count)
        let data = flattenDictionary(dict: responseHandler.onResponseReceivedData)
        XCTAssertEqual(6, data.count)
        XCTAssertEqual("personalization:decisions", data["type"] as? String)
        XCTAssertEqual("AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9", data["payload[0].id"] as? String)
        XCTAssertEqual("#D41DBA", data["payload[0].items[0].data.content.value"] as? String)
        XCTAssertEqual("https://ns.adobe.com/personalization/json-content-item", data["payload[0].items[0].schema"] as? String)
        XCTAssertEqual("buttonColor", data["payload[0].scope"] as? String)
        XCTAssertEqual(0, data["eventIndex"] as? Int)
        XCTAssertEqual("buttonColor", data["payload[0].scope"] as? String)
    }

    // MARK: test persisted hits

    func testSendEvent_withXDMData_sendsExEdgeNetworkRequest_afterPersisting() {
        let edgeResponse = EdgeResponse(requestId: "test-req-id", handle: nil, errors: nil, warnings: [EdgeEventError(eventIndex: 0, message: nil, code: "502", namespace: nil)])
        let responseData = try? JSONEncoder().encode(edgeResponse)

        let responseConnection: HttpConnection = HttpConnection(data: responseData,
                                                                response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                          statusCode: 502,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm",
                                                    "testInt": 10,
                                                    "testBool": false,
                                                    "testDouble": 12.89,
                                                    "testArray": ["arrayElem1", 2, true],
                                                    "testDictionary": ["key": "val"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // reset event hub to mimic a shutdown
        EventHub.reset()
        resetTestExpectations()

        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        // after starting the SDK again, the previously queued hit should be sent out
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([Identity.self, Edge.self], {
            waitForRegistration.countDown()
        })

        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))
        self.assertNetworkRequestsCount()
    }

    func testSendEvent_withXDMData_sendsExEdgeNetworkRequest_afterPersistingMultipleHits() {
        let edgeResponse = EdgeResponse(requestId: "test-req-id", handle: nil, errors: nil, warnings: [EdgeEventError(eventIndex: 0, message: nil, code: "502", namespace: nil)])
        let responseData = try? JSONEncoder().encode(edgeResponse)

        let responseConnection: HttpConnection = HttpConnection(data: responseData,
                                                                response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                          statusCode: 502,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)

        let experienceEvent = ExperienceEvent(xdm: ["testString": "xdm",
                                                    "testInt": 10,
                                                    "testBool": false,
                                                    "testDouble": 12.89,
                                                    "testArray": ["arrayElem1", 2, true],
                                                    "testDictionary": ["key": "val"]])
        Edge.sendEvent(experienceEvent: experienceEvent)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // reset event hub to mimic a shutdown
        EventHub.reset()
        resetTestExpectations()

        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 2)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        // after starting the SDK again, the previously queued hit should be sent out
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([Identity.self, Edge.self], {
            waitForRegistration.countDown()
        })

        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))
        sleep(1)
        self.assertNetworkRequestsCount()
    }
}

extension Int {
    init(_ val: Bool) {
        self = val ? 1 : 0
    }
}

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

import ACPCore
import AEPExperiencePlatform
import Foundation
import XCTest

/// This Test class is an example of usages of the FunctionalTestBase APIs
class AEPExperiencePlatformFunctionalTests: FunctionalTestBase {
    private let event1 = try! ACPExtensionEvent(name: "e1", type: "eventType", source: "eventSource", data: nil)
    private let event2 = try! ACPExtensionEvent(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private let exEdgeInteractUrl = "https://edge.adobedc.net/ee/v1/interact"
    private let responseBody = "{\"test\": \"json\"}"

    class TestResponseHandler: ExperiencePlatformResponseHandler {
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
            countDownLatch.await()
        }
    }

    public class override func setUp() {
        super.setUp()
        FunctionalTestBase.debugEnabled = true
    }

    override func setUp() {
        super.setUp()
        FunctionalTestUtils.resetUserDefaults()
        continueAfterFailure = false
        if FunctionalTestBase.isFirstRun {
            let startLatch: CountDownLatch = CountDownLatch(1)
            setExpectationEvent(type: FunctionalTestConst.EventType.eventHub, source: FunctionalTestConst.EventSource.booted, count: 1)

            // hub shared state update for 1 extension versions, Identity and Config shared state updates
            setExpectationEvent(type: FunctionalTestConst.EventType.eventHub, source: FunctionalTestConst.EventSource.sharedState, count: 3)
            setExpectationEvent(type: FunctionalTestConst.EventType.identity, source: FunctionalTestConst.EventSource.responseIdentity, count: 2)

            // expectations for update config request&response events
            setExpectationEvent(type: FunctionalTestConst.EventType.configuration, source: FunctionalTestConst.EventSource.requestContent, count: 1)
            setExpectationEvent(type: FunctionalTestConst.EventType.configuration, source: FunctionalTestConst.EventSource.responseContent, count: 1)

            ACPIdentity.registerExtension()
            ExperiencePlatform.registerExtension()

            ACPCore.start {
                ACPCore.updateConfiguration(["global.privacy": "optedin",
                                             "experienceCloud.org": "testOrg@AdobeOrg",
                                             "edge.configId": "12345-example"])
                startLatch.countDown()
            }

            XCTAssertEqual(DispatchTimeoutResult.success, startLatch.await(timeout: 2))

            assertExpectedEvents(ignoreUnexpectedEvents: false)
            resetTestExpectations()
        }
    }

    override func tearDown() {
        // to revisit when AMSDK-10169 is available
        // wait .2 seconds in case there are unexpected events that were in the dispatch process during cleanup
        usleep(200000)
        super.tearDown()
    }

    // MARK: sample tests for the FunctionalTest framework usage

    func testSample_AssertUnexpectedEvents() {
        // set event expectations specifying the event type, source and the count (count should be > 0)
        setExpectationEvent(type: "eventType", source: "eventSource", count: 2)
        try? ACPCore.dispatchEvent(event1)
        try? ACPCore.dispatchEvent(event1)

        // assert that no unexpected event was received
        assertUnexpectedEvents()
    }

    func testSample_AssertExpectedEvents() {
        setExpectationEvent(type: "eventType", source: "eventSource", count: 2)
        try? ACPCore.dispatchEvent(event1)
        try? ACPCore.dispatchEvent(try! ACPExtensionEvent(name: "e1", type: "unexpectedType", source: "unexpectedSource", data: ["test": "withdata"]))
        try? ACPCore.dispatchEvent(event1)

        // assert all expected events were received and ignore any unexpected events
        // when ignoreUnexpectedEvents is set on false, an extra assertUnexpectedEvents step is performed
        assertExpectedEvents(ignoreUnexpectedEvents: true)
    }

    func testSample_DispatchedEvents() {
        try? ACPCore.dispatchEvent(event1)
        try? ACPCore.dispatchEvent(try! ACPExtensionEvent(name: "e1", type: "otherEventType", source: "otherEventSource", data: ["test": "withdata"]))
        try? ACPCore.dispatchEvent(try! ACPExtensionEvent(name: "e1", type: "eventType", source: "eventSource", data: ["test": "withdata"]))

        // assert on count and data for events of a certain type, source
        let dispatchedEvents = getDispatchedEventsWith(type: "eventType", source: "eventSource")

        XCTAssertEqual(2, dispatchedEvents.count)
        guard let event2data = dispatchedEvents[1].eventData as? [String: Any] else {
            XCTFail("Invalid event data for event 2")
            return
        }
        XCTAssertEqual(1, flattenDictionary(dict: event2data).count)
    }

    func testSample_AssertNetworkRequestsCount() {
        let responseBody = "{\"test\": \"json\"}"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 2)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["test1": "xdm"], data: nil))
        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["test2": "xdm"], data: nil))

        assertNetworkRequestsCount()
    }

    func testSample_AssertNetworkRequestAndResponseEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.requestContent, count: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.responseContent, count: 1)
        let responseBody = "\u{0000}{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}}]}]}\n"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 1)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["eventType": "testType", "test": "xdm"], data: nil))

        let requests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)

        XCTAssertEqual(1, requests.count)
        let flattenRequestBody = getFlattenNetworkRequestBody(requests[0])
        XCTAssertEqual("testType", flattenRequestBody["events[0].xdm.eventType"] as? String)

        assertExpectedEvents(ignoreUnexpectedEvents: true)
    }

    /// Keeping these tests in here because there is no way to currently reset the core in between tests
    // MARK: test request event format

    func testSendEvent_withXDMData_sendsCorrectRequestEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.requestContent)

        let experienceEvent = ExperiencePlatformEvent(xdm: ["testString": "xdm",
                                                            "testInt": 10,
                                                            "testBool": false,
                                                            "testDouble": 12.89,
                                                            "testArray": ["arrayElem1", 2, true],
                                                            "testDictionary": ["key": "val"]])
        ExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.experiencePlatform,
                                                   source: FunctionalTestConst.EventSource.requestContent)
        guard let eventDataDict = resultEvents[0].eventData as? [String: Any] else {
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
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.requestContent)

        let experienceEvent = ExperiencePlatformEvent(xdm: ["testString": "xdm"], data: ["testDataString": "stringValue",
                                                                                         "testDataInt": 101,
                                                                                         "testDataBool": true,
                                                                                         "testDataDouble": 13.66,
                                                                                         "testDataArray": ["arrayElem1", 2, true],
                                                                                         "testDataDictionary": ["key": "val"]])
        ExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.experiencePlatform,
                                                   source: FunctionalTestConst.EventSource.requestContent)
        guard let eventDataDict = resultEvents[0].eventData as? [String: Any] else {
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
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.requestContent)

        let experienceEvent = ExperiencePlatformEvent(xdm: ["testString": "xdm"], data: nil)
        ExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)

        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.experiencePlatform,
                                                   source: FunctionalTestConst.EventSource.requestContent)
        guard let eventDataDict = resultEvents[0].eventData as? [String: Any] else {
            XCTFail("Failed to convert event data to [String: Any]")
            return
        }
        let eventData = flattenDictionary(dict: eventDataDict)
        XCTAssertEqual(1, eventData.count)
        XCTAssertEqual("xdm", eventData["xdm.testString"] as? String)
    }

    func testSendEvent_withEmptyXDMDataAndNilData_DoesNotSendRequestEvent() {
        let experienceEvent = ExperiencePlatformEvent(xdm: [:], data: nil)
        ExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)

        // verify
        assertUnexpectedEvents()
    }

    func testSendEvent_withEmptyXDMSchema_DoesNotSendRequestEvent() {
        let experienceEvent = ExperiencePlatformEvent(xdm: TestXDMSchema())
        ExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)

        // verify
        assertUnexpectedEvents()
    }

    // MARK: test network request format

    func testSendEvent_withXDMData_sendsExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 1)

        let experienceEvent = ExperiencePlatformEvent(xdm: ["testString": "xdm",
                                                            "testInt": 10,
                                                            "testBool": false,
                                                            "testDouble": 12.89,
                                                            "testArray": ["arrayElem1", 2, true],
                                                            "testDictionary": ["key": "val"]])
        ExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)

        // verify
        assertNetworkRequestsCount()
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
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
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(exEdgeInteractUrl))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withXDMDataAndCustomData_sendsExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 1)

        let experienceEvent = ExperiencePlatformEvent(xdm: ["testString": "xdm"], data: ["testDataString": "stringValue",
                                                                                         "testDataInt": 101,
                                                                                         "testDataBool": true,
                                                                                         "testDataDouble": 13.66,
                                                                                         "testDataArray": ["arrayElem1", 2, true],
                                                                                         "testDataDictionary": ["key": "val"]])
        ExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)

        // verify
        assertNetworkRequestsCount()
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
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
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(exEdgeInteractUrl))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withXDMSchema_sendsExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 1)

        var xdmObject = TestXDMObject()
        xdmObject.innerKey = "testInnerObject"
        var xdmSchema = TestXDMSchema()
        xdmSchema.boolObject = true
        xdmSchema.intObject = 100
        xdmSchema.stringObject = "testWithXdmSchema"
        xdmSchema.doubleObject = 3.42
        xdmSchema.xdmObject = xdmObject

        let experienceEvent = ExperiencePlatformEvent(xdm: xdmSchema)
        ExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)

        // verify
        assertNetworkRequestsCount()
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
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
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(exEdgeInteractUrl))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    func testSendEvent_withEmptyXDMSchema_doesNotSendExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)

        let experienceEvent = ExperiencePlatformEvent(xdm: TestXDMSchema())
        ExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)

        // verify
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    func testSendEvent_withEmptyXDMSchemaAndEmptyData_doesNotSendExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)

        let experienceEvent = ExperiencePlatformEvent(xdm: TestXDMSchema(), data: [:])
        ExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)

        // verify
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    func testSendEvent_withEmptyXDMSchemaAndNilData_doesNotSendExEdgeNetworkRequest() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)

        let experienceEvent = ExperiencePlatformEvent(xdm: TestXDMSchema(), data: nil)
        ExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)

        // verify
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    // MARK: Client-side store
    func testSendEvent_twoConsecutiveCalls_appendsReceivedClientSideStore() {
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 1)
        let storeResponseBody = "\u{0000}{\"requestId\": \"0000-4a4e-1111-bf5c-abcd\",\"handle\": [{\"payload\": [{\"key\": \"kndctr_testOrg_AdobeOrg_identity\",\"value\": \"CiY4OTgzOTEzMzE0NDAwMjUyOTA2NzcwMTY0NDE3Nzc4MzUwMTUzMFINCJHdjrCzLhAAGAEgB6ABnd2OsLMuqAGV8N6h277mkagB8AGR3Y6wsy4=\",\"maxAge\": 34128000},{\"key\": \"kndctr_testOrg_AdobeOrg_consent_check\",\"value\": \"1\",\"maxAge\": 7200},{\"key\": \"expired_key\",\"value\": \"1\",\"maxAge\": 0}],\"type\": \"state:store\"}]}\n"
        let responseConnection: HttpConnection = HttpConnection(data: storeResponseBody.data(using: .utf8),
                                                                response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)

        let experienceEvent = ExperiencePlatformEvent(xdm: ["testString": "xdm"], data: nil)
        ExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)

        // first network call, no stored data
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 1)
        var resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
        var requestBody = getFlattenNetworkRequestBody(resultNetworkRequests[0])
        XCTAssertEqual(7, requestBody.count)
        resetTestExpectations()

        // send a new event, should contain previously stored store data
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 1)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        ExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)

        resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
        requestBody = getFlattenNetworkRequestBody(resultNetworkRequests[0])
        XCTAssertEqual(13, requestBody.count)

        guard let firstStore = requestBody["meta.state.entries[0].key"] as? String,
            let index = firstStore == "kndctr_testOrg_AdobeOrg_identity" ? false : true else {
                XCTFail("Client-side store not found")
                return
        }
        XCTAssertEqual("kndctr_testOrg_AdobeOrg_identity", requestBody["meta.state.entries[\(Int(index))].key"] as? String)
        XCTAssertEqual("CiY4OTgzOTEzMzE0NDAwMjUyOTA2NzcwMTY0NDE3Nzc4MzUwMTUzMFINCJHdjrCzLhAAGAEgB6ABnd2OsLMuqAGV8N6h277mkagB8AGR3Y6wsy4=",
                       requestBody["meta.state.entries[\(Int(index))].value"] as? String)
        XCTAssertEqual(34128000, requestBody["meta.state.entries[\(Int(index))].maxAge"] as? Int)
        XCTAssertEqual("kndctr_testOrg_AdobeOrg_consent_check", requestBody["meta.state.entries[\(Int(!index))].key"] as? String)
        XCTAssertEqual("1", requestBody["meta.state.entries[\(Int(!index))].value"] as? String)
        XCTAssertEqual(7200, requestBody["meta.state.entries[\(Int(!index))].maxAge"] as? Int)

        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(exEdgeInteractUrl))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }

    // MARK: Paired request-response events
    func testSendEvent_receivesResponseEventHandle_sendsResponseEvent_pairedWithTheRequestEventId() {
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform,
                            source: FunctionalTestConst.EventSource.requestContent,
                            count: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform,
                            source: FunctionalTestConst.EventSource.responseContent,
                            count: 1)
        let responseBody = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a26\",\"handle\": [{\"payload\": [{\"id\": \"AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9\",\"scope\": \"buttonColor\",\"items\": [{                           \"schema\": \"https://ns.adobe.com/personalization/json-content-item\",\"data\": {\"content\": {\"value\": \"#D41DBA\"}}}]}],\"type\": \"personalization:decisions\",\"eventIndex\": 0}]}\n"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 1)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                                                      data: nil))

        assertNetworkRequestsCount()
        assertExpectedEvents(ignoreUnexpectedEvents: true)

        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
        let requestId = resultNetworkRequests[0].url.queryParam("requestId")
        let requestEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.experiencePlatform,
                                                    source: FunctionalTestConst.EventSource.requestContent)
        let requestEventUUID = requestEvents[0].eventUniqueIdentifier
        let responseEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.experiencePlatform,
                                                     source: FunctionalTestConst.EventSource.responseContent)
        guard let eventDataDict = responseEvents[0].eventData as? [String: Any] else {
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
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform,
                            source: FunctionalTestConst.EventSource.requestContent,
                            count: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform,
                            source: FunctionalTestConst.EventSource.errorResponseContent,
                            count: 1)
        let responseBody = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a26\",\"handle\": [],\"warnings\": [{\"eventIndex\": 0,\"code\": \"personalization:0\",\"message\": \"Failed due to unrecoverable system error\"}]}\n"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 1)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                                                      data: nil))

        assertNetworkRequestsCount()
        assertExpectedEvents(ignoreUnexpectedEvents: true)

        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
        let requestId = resultNetworkRequests[0].url.queryParam("requestId")
        let requestEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.experiencePlatform,
                                                    source: FunctionalTestConst.EventSource.requestContent)
        let requestEventUUID = requestEvents[0].eventUniqueIdentifier
        let errorResponseEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.experiencePlatform,
                                                          source: FunctionalTestConst.EventSource.errorResponseContent)
        guard let eventDataDict = errorResponseEvents[0].eventData as? [String: Any] else {
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

    // TODO: Failing due to AMSDK-10295, re-enable after the bug fix is released
    func disable_testSendEvent_receivesResponseEventHandle_callsResponseHandler() {
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.requestContent, count: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.responseContent, count: 1)
        let responseBody = "\u{0000}{\"requestId\": \"0ee43289-4a4e-469a-bf5c-1d8186919a26\",\"handle\": [{\"payload\": [{\"id\": \"AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9\",\"scope\": \"buttonColor\",\"items\": [{                           \"schema\": \"https://ns.adobe.com/personalization/json-content-item\",\"data\": {\"content\": {\"value\": \"#D41DBA\"}}}]}],\"type\": \"personalization:decisions\",\"eventIndex\": 0}]}\n"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 1)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)
        let responseHandler = TestResponseHandler(expectedCount: 1)

        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["eventType": "personalizationEvent", "test": "xdm"],
                                                                                      data: nil),
                                     responseHandler: responseHandler)

        assertNetworkRequestsCount()
        assertExpectedEvents(ignoreUnexpectedEvents: true)
        responseHandler.await()

        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
        let requestId = resultNetworkRequests[0].url.queryParam("requestId")
        let requestEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.experiencePlatform,
                                                    source: FunctionalTestConst.EventSource.requestContent)
        let requestEventUUID = requestEvents[0].eventUniqueIdentifier
        let data = flattenDictionary(dict: responseHandler.onResponseReceivedData)
        XCTAssertEqual(8, data.count)
        XCTAssertEqual("personalization:decisions", data["type"] as? String)
        XCTAssertEqual("AT:eyJhY3Rpdml0eUlkIjoiMTE3NTg4IiwiZXhwZXJpZW5jZUlkIjoiMSJ9", data["payload[0].id"] as? String)
        XCTAssertEqual("#D41DBA", data["payload[0].items[0].data.content.value"] as? String)
        XCTAssertEqual("https://ns.adobe.com/personalization/json-content-item", data["payload[0].items[0].schema"] as? String)
        XCTAssertEqual("buttonColor", data["payload[0].scope"] as? String)
        XCTAssertEqual(0, data["eventIndex"] as? Int)
        XCTAssertEqual("buttonColor", data["payload[0].scope"] as? String)
        XCTAssertEqual(requestId, data["requestId"] as? String)
        XCTAssertEqual(requestEventUUID, data["requestEventId"] as? String)
    }
}

extension Int {
    init(_ val: Bool) {
        self = val ? 1 : 0
    }
}

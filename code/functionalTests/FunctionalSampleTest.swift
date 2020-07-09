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

import Foundation
import ACPCore
import AEPExperiencePlatform
import XCTest

/// This Test class is an example of usages of the FunctionalTestBase APIs
class FunctionalSampleTest: FunctionalTestBase {
    private let e1 = try! ACPExtensionEvent(name: "e1", type: "eventType", source: "eventSource", data: nil)
    private let e2 = try! ACPExtensionEvent(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private static var firstRun : Bool = true
    private let exEdgeInteractUrl = "https://edge.adobedc.net/ee/v1/interact"
    private let responseBody = "{\"test\": \"json\"}"
    
    public class override func setUp() {
        super.setUp()
        FunctionalTestUtils.resetUserDefaults()
        FunctionalTestBase.debugEnabled = true
    }
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        if FunctionalSampleTest.firstRun {
            // hub shared state update for 2 extension versions, Identity and Config shared state updates
            setExpectationEvent(type: FunctionalTestConst.EventType.eventHub, source: FunctionalTestConst.EventSource.sharedState, count:4)
            setExpectationEvent(type: FunctionalTestConst.EventType.identity, source: FunctionalTestConst.EventSource.responseIdentity, count:2)
            
            // expectations for update config request&response events
            setExpectationEvent(type: FunctionalTestConst.EventType.configuration, source: FunctionalTestConst.EventSource.requestContent, count: 1)
            setExpectationEvent(type: FunctionalTestConst.EventType.configuration, source: FunctionalTestConst.EventSource.responseContent, count: 1)
            
            ACPIdentity.registerExtension()
            ExperiencePlatform.registerExtension()
            ACPCore.updateConfiguration(["global.privacy": "optedin",
                                         "experienceCloud.org": "testOrg@AdobeOrg",
                                         "experiencePlatform.configId": "12345-example"])
            
            assertExpectedEvents(ignoreUnexpectedEvents: false)
            resetTestExpectations()
            
            // Note: core already started in the FunctionalTestBase
        }
        
        FunctionalSampleTest.firstRun = false
    }
    
    /// MARK sample tests for the FunctionalTest framework usage
    
    func testSample_AssertUnexpectedEvents() {
        // set event expectations specifying the event type, source and the count (count should be > 0)
        setExpectationEvent(type: "eventType", source: "eventSource", count: 2)
        try? ACPCore.dispatchEvent(e1)
        try? ACPCore.dispatchEvent(e1)
        
        // assert that no unexpected event was received
        assertUnexpectedEvents()
    }
    
    func testSample_AssertExpectedEvents() {
        setExpectationEvent(type: "eventType", source: "eventSource", count: 2)
        try? ACPCore.dispatchEvent(e1)
        try? ACPCore.dispatchEvent(try! ACPExtensionEvent(name: "e1", type: "unexpectedType", source: "unexpectedSource", data: ["test":"withdata"]))
        try? ACPCore.dispatchEvent(e1)
        
        // assert all expected events were received and ignore any unexpected events
        // when ignoreUnexpectedEvents is set on false, an extra assertUnexpectedEvents step is performed
        assertExpectedEvents(ignoreUnexpectedEvents: true)
    }
    
    func testSample_DispatchedEvents() {
        try? ACPCore.dispatchEvent(e1)
        try? ACPCore.dispatchEvent(try! ACPExtensionEvent(name: "e1", type: "otherEventType", source: "otherEventSource", data: ["test":"withdata"]))
        try? ACPCore.dispatchEvent(try! ACPExtensionEvent(name: "e1", type: "eventType", source: "eventSource", data: ["test":"withdata"]))
        
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
        let url = "https://edge.adobedc.net/ee/v1/interact"
        let responseBody = "{\"test\": \"json\"}"
        let httpConnection : HttpConnection = HttpConnection(data: responseBody.data(using: .utf8), response: HTTPURLResponse(url: URL(string: url)!, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)
        setExpectationNetworkRequest(url: url, httpMethod: HttpMethod.post, count: 2)
        setNetworkResponseFor(url: url, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)
        
        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["test1": "xdm"], data: nil))
        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["test2": "xdm"], data: nil))
        
        assertNetworkRequestsCount()
    }
    
    func testSample_AssertNetworkRequestAndResponseEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.requestContent, count: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.responseContent, count: 1)
        let url = "https://edge.adobedc.net/ee/v1/interact"
        let responseBody = "\u{0000}{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}}]}]}\n"
        let httpConnection : HttpConnection = HttpConnection(data: responseBody.data(using: .utf8), response: HTTPURLResponse(url: URL(string: url)!, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)
        setExpectationNetworkRequest(url: url, httpMethod: HttpMethod.post, count: 1)
        setNetworkResponseFor(url: url, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)
        
        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["eventType": "testType", "test": "xdm"], data: nil))
        
        let requests = getNetworkRequestsWith(url: url, httpMethod: HttpMethod.post)
        
        XCTAssertEqual(1, requests.count)
        let flattenRequestBody = getFlattenNetworkRequestBody(requests[0])
        XCTAssertEqual("testType", flattenRequestBody["events[0].xdm.eventType"] as? String)
        
        assertExpectedEvents(ignoreUnexpectedEvents: true)
    }
    
    /// Keeping these tests in here because there is no way to currently reset the core in between tests
    /// MARK test request event format
    
    func testSendEvent_withXDMData_sendsCorrectRequestEvent() {
        setExpectationEvent(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.requestContent)
        
        let experienceEvent = ExperiencePlatformEvent(xdm: ["testString":"xdm",
                                                            "testInt": 10,
                                                            "testBool": false,
                                                            "testDouble": 12.89,
                                                            "testArray": ["arrayElem1", 2, true],
                                                            "testDictionary": ["key":"val"]])
        ACPExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)
        
        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.requestContent)
        let eventData = flattenDictionary(dict: resultEvents[0].eventData as! [String: Any])
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
        
        let experienceEvent = ExperiencePlatformEvent(xdm: ["testString":"xdm"], data: ["testDataString": "stringValue",
                                                                                        "testDataInt": 101,
                                                                                        "testDataBool": true,
                                                                                        "testDataDouble": 13.66,
                                                                                        "testDataArray": ["arrayElem1", 2, true],
                                                                                        "testDataDictionary": ["key":"val"]])
        ACPExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)
        
        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.requestContent)
        let eventData = flattenDictionary(dict: resultEvents[0].eventData as! [String: Any])
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
        
        let experienceEvent = ExperiencePlatformEvent(xdm: ["testString":"xdm"], data: nil)
        ACPExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)
        
        // verify
        assertExpectedEvents(ignoreUnexpectedEvents: false)
        let resultEvents = getDispatchedEventsWith(type: FunctionalTestConst.EventType.experiencePlatform, source: FunctionalTestConst.EventSource.requestContent)
        let eventData = flattenDictionary(dict: resultEvents[0].eventData as! [String: Any])
        XCTAssertEqual(1, eventData.count)
        XCTAssertEqual("xdm", eventData["xdm.testString"] as? String)
    }
    
    func testSendEvent_withEmptyXDMDataAndNilData_DoesNotSendRequestEvent() {
        let experienceEvent = ExperiencePlatformEvent(xdm: [:], data: nil)
        ACPExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)
        
        // verify
        assertUnexpectedEvents()
    }
    
    func testSendEvent_withEmptyXDMSchema_DoesNotSendRequestEvent() {
        let experienceEvent = ExperiencePlatformEvent(xdm: TestXDMSchema())
        ACPExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)
        
        // verify
        assertUnexpectedEvents()
    }
    
    /// MARK test network request format
    
    func testSendEvent_withXDMData_sendsExEdgeNetworkRequest() {
        let responseConnection : HttpConnection = HttpConnection(data: responseBody.data(using: .utf8), response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 1)
        
        let experienceEvent = ExperiencePlatformEvent(xdm: ["testString":"xdm",
                                                            "testInt": 10,
                                                            "testBool": false,
                                                            "testDouble": 12.89,
                                                            "testArray": ["arrayElem1", 2, true],
                                                            "testDictionary": ["key":"val"]])
        ACPExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)
        
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
        let responseConnection : HttpConnection = HttpConnection(data: responseBody.data(using: .utf8), response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, count: 1)
        
        let experienceEvent = ExperiencePlatformEvent(xdm: ["testString":"xdm"], data: ["testDataString": "stringValue",
                                                                                        "testDataInt": 101,
                                                                                        "testDataBool": true,
                                                                                        "testDataDouble": 13.66,
                                                                                        "testDataArray": ["arrayElem1", 2, true],
                                                                                        "testDataDictionary": ["key":"val"]])
        ACPExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)
        
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
        let responseConnection : HttpConnection = HttpConnection(data: responseBody.data(using: .utf8), response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)
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
        ACPExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)
        
        // verify
        assertNetworkRequestsCount()
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
        let requestBody = getFlattenNetworkRequestBody(resultNetworkRequests[0])
        XCTAssertEqual(11, requestBody.count)
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
        
        let requestUrl = resultNetworkRequests[0].url
        XCTAssertTrue(requestUrl.absoluteURL.absoluteString.hasPrefix(exEdgeInteractUrl))
        XCTAssertEqual("12345-example", requestUrl.queryParam("configId"))
        XCTAssertNotNil(requestUrl.queryParam("requestId"))
    }
    
    func testSendEvent_withEmptyXDMSchema_doesNotSendExEdgeNetworkRequest() {
        let responseConnection : HttpConnection = HttpConnection(data: responseBody.data(using: .utf8), response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        
        let experienceEvent = ExperiencePlatformEvent(xdm: TestXDMSchema())
        ACPExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)
        
        // verify
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }
    
    func testSendEvent_withEmptyXDMSchemaAndEmptyData_doesNotSendExEdgeNetworkRequest() {
        let responseConnection : HttpConnection = HttpConnection(data: responseBody.data(using: .utf8), response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        
        let experienceEvent = ExperiencePlatformEvent(xdm: TestXDMSchema(), data: [:])
        ACPExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)
        
        // verify
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }
    
    func testSendEvent_withEmptyXDMSchemaAndNilData_doesNotSendExEdgeNetworkRequest() {
        let responseConnection : HttpConnection = HttpConnection(data: responseBody.data(using: .utf8), response: HTTPURLResponse(url: URL(string: exEdgeInteractUrl)!, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrl, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        
        let experienceEvent = ExperiencePlatformEvent(xdm: TestXDMSchema(), data: nil)
        ACPExperiencePlatform.sendEvent(experiencePlatformEvent: experienceEvent)
        
        // verify
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrl, httpMethod: HttpMethod.post)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }
}

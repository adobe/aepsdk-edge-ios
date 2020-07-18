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
class FunctionalSampleTest: FunctionalTestBase {
    private let e1 = try! ACPExtensionEvent(name: "e1", type: "eventType", source: "eventSource", data: nil)
    private let e2 = try! ACPExtensionEvent(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private static var firstRun: Bool = true

    public class override func setUp() {
        super.setUp()
        FunctionalTestUtils.resetUserDefaults()
        FunctionalTestBase.debugEnabled = true
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        if FunctionalSampleTest.firstRun {
            let startLatch: CountDownLatch = CountDownLatch(1)
            setExpectationEvent(type: FunctionalTestConst.EventType.eventHub, source: FunctionalTestConst.EventSource.booted, count: 1)
            
            // hub shared state update for 1 extension versions, Identity and Config shared state updates
            setExpectationEvent(type: FunctionalTestConst.EventType.eventHub, source: FunctionalTestConst.EventSource.sharedState, count:3)
            setExpectationEvent(type: FunctionalTestConst.EventType.identity, source: FunctionalTestConst.EventSource.responseIdentity, count:2)
            
            // expectations for update config request&response events
            setExpectationEvent(type: FunctionalTestConst.EventType.configuration, source: FunctionalTestConst.EventSource.requestContent, count: 1)
            setExpectationEvent(type: FunctionalTestConst.EventType.configuration, source: FunctionalTestConst.EventSource.responseContent, count: 1)

            ACPIdentity.registerExtension()
            ExperiencePlatform.registerExtension()
            
            ACPCore.start {
                ACPCore.updateConfiguration(["global.privacy": "optedin",
                                             "experienceCloud.org": "testOrg@AdobeOrg",
                                             "experiencePlatform.configId": "12345-example"])
                startLatch.countDown()
            }
            
            XCTAssertEqual(DispatchTimeoutResult.success, startLatch.await(timeout: 2))
            assertExpectedEvents(ignoreUnexpectedEvents: false)
            resetTestExpectations()
        }

        FunctionalSampleTest.firstRun = false
    }

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
        try? ACPCore.dispatchEvent(try! ACPExtensionEvent(name: "e1", type: "unexpectedType", source: "unexpectedSource", data: ["test": "withdata"]))
        try? ACPCore.dispatchEvent(e1)

        // assert all expected events were received and ignore any unexpected events
        // when ignoreUnexpectedEvents is set on false, an extra assertUnexpectedEvents step is performed
        assertExpectedEvents(ignoreUnexpectedEvents: true)
    }

    func testSample_DispatchedEvents() {
        try? ACPCore.dispatchEvent(e1)
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
        let url = "https://edge.adobedc.net/ee/v1/interact"
        let responseBody = "{\"test\": \"json\"}"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8), response: HTTPURLResponse(url: URL(string: url)!, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)
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
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8), response: HTTPURLResponse(url: URL(string: url)!, statusCode: 200, httpVersion: nil, headerFields: nil), error: nil)
        setExpectationNetworkRequest(url: url, httpMethod: HttpMethod.post, count: 1)
        setNetworkResponseFor(url: url, httpMethod: HttpMethod.post, responseHttpConnection: httpConnection)

        ExperiencePlatform.sendEvent(experiencePlatformEvent: ExperiencePlatformEvent(xdm: ["eventType": "testType", "test": "xdm"], data: nil))

        let requests = getNetworkRequestsWith(url: url, httpMethod: HttpMethod.post)

        XCTAssertEqual(1, requests.count)
        let flattenRequestBody = getFlattenNetworkRequestBody(requests[0])
        XCTAssertEqual("testType", flattenRequestBody["events[0].xdm.eventType"] as? String)

        assertExpectedEvents(ignoreUnexpectedEvents: true)
    }
}

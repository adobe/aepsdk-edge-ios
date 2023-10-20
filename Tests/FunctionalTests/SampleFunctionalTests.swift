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

import AEPCore
import AEPEdge
import AEPEdgeIdentity
import AEPServices
import Foundation
import XCTest

/// This Test class is an example of usages of the TestBase APIs
class SampleFunctionalTests: TestBase {
    private let event1 = Event(name: "e1", type: "eventType", source: "eventSource", data: nil)
    private let event2 = Event(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private let exEdgeInteractUrlString = "https://edge.adobedc.net/ee/v1/interact"
    private let exEdgeInteractUrl = URL(string: "https://edge.adobedc.net/ee/v1/interact")! // swiftlint:disable:this force_unwrapping
    private let responseBody = "{\"test\": \"json\"}"

    private let mockNetworkService: MockNetworkService = MockNetworkService()

    override func setUp() {
        ServiceProvider.shared.networkService = mockNetworkService

        super.setUp()

        continueAfterFailure = false
        TestBase.debugEnabled = true

        // hub shared state update for extension versions (InstrumentedExtension (registered in TestBase), IdentityEdge, Edge), Edge extension, IdentityEdge XDM shared state and Config shared state updates
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

        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
        mockNetworkService.reset()
    }

    // Runs after each test case
    override func tearDown() {
        super.tearDown()

        mockNetworkService.reset()
    }

    // MARK: sample tests for the FunctionalTest framework usage

    func testSample_AssertUnexpectedEvents() {
        // set event expectations specifying the event type, source and the count (count should be > 0)
        setExpectationEvent(type: "eventType", source: "eventSource", expectedCount: 2)
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: event1)

        // assert that no unexpected event was received
        assertUnexpectedEvents()
    }

    func testSample_AssertExpectedEvents() {
        setExpectationEvent(type: "eventType", source: "eventSource", expectedCount: 2)
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: Event(name: "e1", type: "unexpectedType", source: "unexpectedSource", data: ["test": "withdata"]))
        MobileCore.dispatch(event: event1)

        // assert all expected events were received and ignore any unexpected events
        // when ignoreUnexpectedEvents is set on false, an extra assertUnexpectedEvents step is performed
        assertExpectedEvents(ignoreUnexpectedEvents: true)
    }

    func testSample_DispatchedEvents() {
        MobileCore.dispatch(event: event1)
        MobileCore.dispatch(event: Event(name: "e1", type: "otherEventType", source: "otherEventSource", data: ["test": "withdata"]))
        MobileCore.dispatch(event: Event(name: "e1", type: "eventType", source: "eventSource", data: ["test": "withdata"]))

        // assert on count and data for events of a certain type, source
        let dispatchedEvents = getDispatchedEventsWith(type: "eventType", source: "eventSource")

        XCTAssertEqual(2, dispatchedEvents.count)
        guard let event2data = dispatchedEvents[1].data else {
            XCTFail("Invalid event data for event 2")
            return
        }
        XCTAssertEqual(1, flattenDictionary(dict: event2data).count)
    }

    func testSample_AssertNetworkRequestsCount() {
        let responseBody = "{\"test\": \"json\"}"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        mockNetworkService.setExpectationForNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 2)
        mockNetworkService.setMockResponse(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseConnection: httpConnection)

        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["test1": "xdm"], data: nil))
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["test2": "xdm"], data: nil))

        mockNetworkService.assertAllNetworkRequestExpectations()
    }

    func testSample_AssertNetworkRequestAndResponseEvent() {
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: TestConstants.EventSource.REQUEST_CONTENT, expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.EDGE, source: "identity:exchange", expectedCount: 1)
        // swiftlint:disable:next line_length
        let responseBody = "\u{0000}{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}}]}]}\n"
        let httpConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                            response: HTTPURLResponse(url: exEdgeInteractUrl,
                                                                                      statusCode: 200,
                                                                                      httpVersion: nil,
                                                                                      headerFields: nil),
                                                            error: nil)
        mockNetworkService.setExpectationForNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)
        mockNetworkService.setMockResponse(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseConnection: httpConnection)

        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["eventType": "testType", "test": "xdm"], data: nil))

        let requests = mockNetworkService.getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post)

        XCTAssertEqual(1, requests.count)
        let flattenRequestBody = requests[0].getFlattenedBody()
        XCTAssertEqual("testType", flattenRequestBody["events[0].xdm.eventType"] as? String)

        assertExpectedEvents(ignoreUnexpectedEvents: true)
    }
}

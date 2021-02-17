//
// Copyright 2021 Adobe. All rights reserved.
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
import AEPIdentityEdge
import AEPServices
import Foundation
import XCTest

class AEPEdgePrivacyStatusChangeTests: FunctionalTestBase {
    private let EXPECTED_COUNT: Int32 = 5
    private let exEdgeInteractUrlString = "https://edge.adobedc.net/ee/v1/interact"
    private let experienceEvent = ExperienceEvent(xdm: ["test": "xdm"])
    private let responseBody = "\u{0000}{" +
        "      \"requestId\": \"e94835b0-e0b1-4038-b943-80d98fd9e2c7\"," +
        "      \"handle\": [" +
        "        {" +
        "          \"payload\": [" +
        "            {" +
        "              \"key\": \"kndctr_example_AdobeOrg_consent\"," +
        "              \"value\": \"\"," +
        "              \"maxAge\": 5552000" +
        "            }," +
        "            {" +
        "              \"key\": \"kndctr_example_AdobeOrg_identity\"," +
        "              \"value\": \"abcd\"," +
        "              \"maxAge\": 34128000" +
        "            }," +
        "            {" +
        "              \"key\": \"kndctr_example_AdobeOrg_consent_check\"," +
        "              \"value\": \"1\"," +
        "              \"maxAge\": 7200" +
        "            }" +
        "          ]," +
        "          \"type\": \"state:store\"" +
        "        }" +
        "      ]" +
        "    }\n"

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

        // wait for async registration because the EventHub is already started in FunctionalTestBase
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([Identity.self, Edge.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))

        MobileCore.updateConfigurationWith(configDict: ["global.privacy": "optunknown",
                                                        "experienceCloud.org": "testOrg@AdobeOrg",
                                                        "edge.configId": "12345-example"])

        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
    }

    func testPrivacyStatus_whenOptedOut_thenHits_hitsCleared() {
        // test
        MobileCore.setPrivacyStatus(PrivacyStatus.optedOut)
        getPrivacyStatusSync()
        fireManyEvents()

        // verify
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, timeout: 2)
        XCTAssertTrue(resultNetworkRequests.isEmpty)
    }

    func testPrivacyStatus_whenOptedIn_thenHits_hitsSent() {
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 5)

        // test
        MobileCore.setPrivacyStatus(PrivacyStatus.optedIn)
        getPrivacyStatusSync()
        fireManyEvents()

        // verify
        assertNetworkRequestsCount()
    }

    func testPrivacyStatus_whenOptUnknown_thenHits_thenOptedIn_hitsSent() {
        // test
        MobileCore.setPrivacyStatus(PrivacyStatus.unknown)
        getPrivacyStatusSync()
        fireManyEvents()

        //verify
        var resultNetworkRequests = self.getNetworkRequestsWith(url: self.exEdgeInteractUrlString, httpMethod: HttpMethod.post, timeout: 2)
        XCTAssertEqual(0, resultNetworkRequests.count)

        // test
        MobileCore.setPrivacyStatus(PrivacyStatus.optedIn)

        // verify
        resultNetworkRequests = self.getNetworkRequestsWith(url: self.exEdgeInteractUrlString, httpMethod: HttpMethod.post, timeout: 2)
        XCTAssertEqual(5, resultNetworkRequests.count)
    }

    func testPrivacyStatus_whenOptUnknown_thenHits_thenOptedOut_hitsCleared() {
        // test
        MobileCore.setPrivacyStatus(PrivacyStatus.unknown)
        getPrivacyStatusSync()
        fireManyEvents()
        MobileCore.setPrivacyStatus(PrivacyStatus.optedOut)

        // verify
        let resultNetworkRequests = getNetworkRequestsWith(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, timeout: 2)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    func testPrivacyStatus_whenOptIn_thenUnknown_thenHits_thenOut_hitsCleared() {
        // test
        MobileCore.setPrivacyStatus(PrivacyStatus.optedIn)
        MobileCore.setPrivacyStatus(PrivacyStatus.unknown)
        getPrivacyStatusSync()
        self.fireManyEvents()
        MobileCore.setPrivacyStatus(PrivacyStatus.optedOut)

        // verify
        let resultNetworkRequests = self.getNetworkRequestsWith(url: self.exEdgeInteractUrlString, httpMethod: HttpMethod.post, timeout: 2)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    func testPrivacyStatus_whenOptOut_thenUnknown_thenHits_thenOut_hitsCleared() {
        // test
        MobileCore.setPrivacyStatus(PrivacyStatus.optedOut)
        MobileCore.setPrivacyStatus(PrivacyStatus.unknown)
        getPrivacyStatusSync()
        self.fireManyEvents()
        MobileCore.setPrivacyStatus(PrivacyStatus.optedOut)

        // verify
        let resultNetworkRequests = self.getNetworkRequestsWith(url: self.exEdgeInteractUrlString, httpMethod: HttpMethod.post, timeout: 2)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    func testPrivacyStatus_whenOptOut_thenUnknown_thenHits_thenIn_hitsSent() {
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 5)

        // test
        MobileCore.setPrivacyStatus(PrivacyStatus.optedOut)
        MobileCore.setPrivacyStatus(PrivacyStatus.unknown)
        getPrivacyStatusSync()
        self.fireManyEvents()
        MobileCore.setPrivacyStatus(PrivacyStatus.optedIn)

        // verify
        assertNetworkRequestsCount()
    }

    func testPrivacyStatus_whenOptedIn_thenOptedOut_thenOptedIn_correctPersistence() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                // swiftlint:disable:next force_unwrapping
                                                                response: HTTPURLResponse(url: URL(string: exEdgeInteractUrlString)!,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: EXPECTED_COUNT)

        MobileCore.setPrivacyStatus(PrivacyStatus.optedIn)
        getPrivacyStatusSync()
        fireManyEvents()
        assertNetworkRequestsCount()
        resetTestExpectations()
        var storePayloads = ServiceProvider.shared.namedKeyValueService.get(
            collectionName: FunctionalTestConst.DataStoreKeys.STORE_NAME,
            key: FunctionalTestConst.DataStoreKeys.STORE_PAYLOADS) as? [String: Any]
        XCTAssertEqual(3, storePayloads?.count)

        MobileCore.setPrivacyStatus(PrivacyStatus.optedOut)
        getPrivacyStatusSync()
        usleep(100000) //.1sec - wait for privacy update event to be processed
        storePayloads = ServiceProvider.shared.namedKeyValueService.get(
            collectionName: FunctionalTestConst.DataStoreKeys.STORE_NAME,
            key: FunctionalTestConst.DataStoreKeys.STORE_PAYLOADS) as? [String: Any]
        XCTAssertNil(storePayloads)

        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: EXPECTED_COUNT)
        MobileCore.setPrivacyStatus(PrivacyStatus.optedIn)
        getPrivacyStatusSync()
        fireManyEvents()
        assertNetworkRequestsCount()
        storePayloads = ServiceProvider.shared.namedKeyValueService.get(
            collectionName: FunctionalTestConst.DataStoreKeys.STORE_NAME,
            key: FunctionalTestConst.DataStoreKeys.STORE_PAYLOADS) as? [String: Any]
        XCTAssertEqual(3, storePayloads?.count)
    }

    func testPrivacyStatus_whenOptedIn_thenOptedOut_delayedResponse_correctPersistence() {
        let responseConnection: HttpConnection = HttpConnection(data: responseBody.data(using: .utf8),
                                                                // swiftlint:disable:next force_unwrapping
                                                                response: HTTPURLResponse(url: URL(string: exEdgeInteractUrlString)!,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)
        MobileCore.setPrivacyStatus(PrivacyStatus.optedIn)
        getPrivacyStatusSync()
        Edge.sendEvent(experienceEvent: experienceEvent)
        assertNetworkRequestsCount()
        resetTestExpectations()

        // delay next request
        setNetworkResponseFor(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: exEdgeInteractUrlString, httpMethod: HttpMethod.post, expectedCount: 1)
        enableNetworkResponseDelay(delaySec: 1) // delay response with 1 sec

        Edge.sendEvent(experienceEvent: experienceEvent)
        usleep(200000) //.2sec - wait for the experience event network request to be initiated
        MobileCore.setPrivacyStatus(PrivacyStatus.optedOut)
        usleep(1300000) //1.3sec - wait for the experience event network response to be processed after privacy status

        assertNetworkRequestsCount()

        let storePayloads = ServiceProvider.shared.namedKeyValueService.get(
            collectionName: FunctionalTestConst.DataStoreKeys.STORE_NAME,
            key: FunctionalTestConst.DataStoreKeys.STORE_PAYLOADS) as? [String: Any]
        XCTAssertNil(storePayloads)
    }

    private func fireManyEvents() {
        Edge.sendEvent(experienceEvent: experienceEvent)
        Edge.sendEvent(experienceEvent: experienceEvent)
        Edge.sendEvent(experienceEvent: experienceEvent)
        Edge.sendEvent(experienceEvent: experienceEvent)
        Edge.sendEvent(experienceEvent: experienceEvent)
    }

    private func getPrivacyStatusSync() {
        let expectation = XCTestExpectation(description: "getPrivacyReturned")
        MobileCore.getPrivacyStatus {_ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
}

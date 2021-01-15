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
import AEPIdentity
import AEPServices
import Foundation
import XCTest

class AEPEdgePrivacyStatusChangeTests: FunctionalTestBase {
    private let exEdgeInteractUrlString = "https://edge.adobedc.net/ee/v1/interact"
    private let experienceEvent = ExperienceEvent(xdm: ["test": "xdm"])

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

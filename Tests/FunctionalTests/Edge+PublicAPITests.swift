//
// Copyright 2022 Adobe. All rights reserved.
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
import XCTest

class EdgePublicAPITests: FunctionalTestBase {
    private let exEdgeInteractProdUrlLocHint = URL(string: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR_OR2_LOC)! // swiftlint:disable:this force_unwrapping
    private let responseBody = "{\"test\": \"json\"}"

    public class override func setUp() {
        super.setUp()
        FunctionalTestBase.debugEnabled = true
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = true
        FileManager.default.clearCache()

        // hub shared state update for 1 extension versions (InstrumentedExtension (registered in FunctionalTestBase), IdentityEdge, Edge) IdentityEdge XDM, Config, and Edge shared state updates
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
        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])

        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
    }

    func testSetLocationHint_sendEvent_sendsNetworkRequestWithLocationHint() {
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR_OR2_LOC, httpMethod: HttpMethod.post, expectedCount: 1)

        Edge.setLocationHint(FunctionalTestConst.OR2_LOC)
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertNetworkRequestsCount()
    }

    func testSetLocationHint_withNilHint_sendEvent_sendsNetworkRequestWithoutLocationHint() {
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])

        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR_OR2_LOC, httpMethod: HttpMethod.post, expectedCount: 1)
        Edge.setLocationHint(FunctionalTestConst.OR2_LOC)
        Edge.sendEvent(experienceEvent: experienceEvent)
        assertNetworkRequestsCount()

        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        Edge.setLocationHint(nil)
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertNetworkRequestsCount()
    }

    func testSetLocationHint_withEmptyHint_sendEvent_sendsNetworkRequestWithoutLocationHint() {
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])

        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR_OR2_LOC, httpMethod: HttpMethod.post, expectedCount: 1)
        Edge.setLocationHint(FunctionalTestConst.OR2_LOC)
        Edge.sendEvent(experienceEvent: experienceEvent)
        assertNetworkRequestsCount()

        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)
        Edge.setLocationHint("")
        Edge.sendEvent(experienceEvent: experienceEvent)

        // verify
        assertNetworkRequestsCount()
    }

    func testGetLocationHint_withoutSet_returnsNilHint() {
        let expectation = XCTestExpectation(description: "Request Location Hint")
        expectation.assertForOverFulfill = true
        Edge.getLocationHint({ hint, error in
            XCTAssertNil(hint)
            XCTAssertNil(error)
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testGetLocationHint_withSet_returnsHint() {
        Edge.setLocationHint(FunctionalTestConst.OR2_LOC)
        let expectation = XCTestExpectation(description: "Request Location Hint")
        expectation.assertForOverFulfill = true
        Edge.getLocationHint({ hint, error in
            XCTAssertEqual(FunctionalTestConst.OR2_LOC, hint)
            XCTAssertNil(error)
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testGetLocationHint_clearHint_returnsNilHint() {
        Edge.setLocationHint(FunctionalTestConst.OR2_LOC)
        Edge.setLocationHint(nil)
        let expectation = XCTestExpectation(description: "Request Location Hint")
        expectation.assertForOverFulfill = true
        Edge.getLocationHint({ hint, error in
            XCTAssertNil(hint)
            XCTAssertNil(error)
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: 1)
    }
}

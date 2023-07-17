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

@testable import AEPCore
@testable import AEPEdge
import XCTest

class EdgePublicAPITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
        EventHub.shared.start()
        usleep(250000) // sleep 0.25 seconds to allow EventHub to start
    }

    override func tearDown() {
        EventHub.reset()
    }

    // MARK: Public APIs
    func testSendEvent_xdmData_DispatchesEdgeRequest() {
        let expectation = XCTestExpectation(description: "edge requestContent event dispatched")
        expectation.assertForOverFulfill = true
        MobileCore.registerEventListener(type: EventType.edge, source: EventSource.requestContent) { event in
            let data = flattenDictionary(dict: event.data ?? [:])
            XCTAssertEqual(1, data.count)
            XCTAssertEqual("xdm", data["xdm.test"] as? String)
            expectation.fulfill()
        }
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["test": "xdm"]))

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testSendEvent_xdmDataAndData_DispatchesEdgeRequest() {
        let expectation = XCTestExpectation(description: "edge requestContent event dispatched")
        expectation.assertForOverFulfill = true
        MobileCore.registerEventListener(type: EventType.edge, source: EventSource.requestContent) { event in
            let data = flattenDictionary(dict: event.data ?? [:])
            XCTAssertEqual(2, data.count)
            XCTAssertEqual("xdm", data["xdm.test"] as? String)
            XCTAssertEqual("example", data["data.rawdata"] as? String)
            expectation.fulfill()
        }
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["test": "xdm"], data: ["rawdata": "example"]))

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testSendEvent_xdmDataAndDatasetId_DispatchesEdgeRequest() {
        let expectation = XCTestExpectation(description: "edge requestContent event dispatched")
        expectation.assertForOverFulfill = true
        MobileCore.registerEventListener(type: EventType.edge, source: EventSource.requestContent) { event in
            let data = flattenDictionary(dict: event.data ?? [:])
            XCTAssertEqual(2, data.count)
            XCTAssertEqual("xdm", data["xdm.test"] as? String)
            XCTAssertEqual("123", data["datasetId"] as? String)
            expectation.fulfill()
        }
        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: ["test": "xdm"], datasetIdentifier: "123"))

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testSendEvent_xdmDataEmptyAndData_DoesNotDispatch() {
        MobileCore.registerEventListener(type: EventType.edge, source: EventSource.requestContent) { _ in
            XCTFail("Unexpected - event dispatched with empty xdm data")
        }

        Edge.sendEvent(experienceEvent: ExperienceEvent(xdm: [:], data: ["rawdata": "example"]))
        sleep(1)
    }

    func testSetLocationHint_valueHint_dispatchesEdgeUpdateIdentity() {
        let expectation = XCTestExpectation(description: "Edge Update Identity Event Dispatched")
        expectation.assertForOverFulfill = true
        MobileCore.registerEventListener(type: EventType.edge, source: EventSource.updateIdentity) { event in
            let data = event.data ?? [:]
            XCTAssertEqual(1, data.count)
            XCTAssertEqual("or2", data["locationHint"] as? String)
            expectation.fulfill()
        }
        Edge.setLocationHint("or2")

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testSetLocationHint_nilHint_dispatchesEdgeUpdateIdentity() {
        let expectation = XCTestExpectation(description: "Edge Update Identity Event Dispatched")
        expectation.assertForOverFulfill = true
        MobileCore.registerEventListener(type: EventType.edge, source: EventSource.updateIdentity) { event in
            let data = event.data ?? [:]
            XCTAssertEqual(1, data.count)
            XCTAssertEqual("", data["locationHint"] as? String) // expect to convert nil to empty string
            expectation.fulfill()
        }
        Edge.setLocationHint(nil)

        // verify
        wait(for: [expectation], timeout: 1)
    }

    func testSetLocationHint_emptyHint_dispatchesEdgeUpdateIdentity() {
        let expectation = XCTestExpectation(description: "Edge Update Identity Event Dispatched")
        expectation.assertForOverFulfill = true
        MobileCore.registerEventListener(type: EventType.edge, source: EventSource.updateIdentity) { event in
            let data = event.data ?? [:]
            XCTAssertEqual(1, data.count)
            XCTAssertEqual("", data["locationHint"] as? String)
            expectation.fulfill()
        }
        Edge.setLocationHint("")

        // verify
        wait(for: [expectation], timeout: 1)
    }

    // Test getLocationHint when valid Hint of OR2 is returned
    func testGetLocationHint_dispatchesEdgeRequestIdentity_receivesResponseIdentity_withValidHint() {
        let expectation = XCTestExpectation(description: "Edge Get Location Hint")
        expectation.assertForOverFulfill = true
        MobileCore.registerEventListener(type: EventType.edge, source: EventSource.requestIdentity) { event in
            XCTAssertTrue(event.data?[EdgeConstants.EventDataKeys.LOCATION_HINT] as? Bool ?? false)
            let responseEvent = event.createResponseEvent(name: "Test Response Location Hint",
                                                          type: EventType.edge,
                                                          source: EventSource.responseIdentity,
                                                          data: ["locationHint": "or2"])
            MobileCore.dispatch(event: responseEvent)
        }
        Edge.getLocationHint({ hint, error in
            XCTAssertEqual("or2", hint)
            XCTAssertNil(error)
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: 1)
    }

    // Test getLocationHint when no data is returned which signifies no or expired Hint value
    func testGetLocationHint_dispatchesEdgeRequestIdentity_receivesResponseIdentity_withEmptyHint() {
        let expectation = XCTestExpectation(description: "Edge Get Location Hint")
        expectation.assertForOverFulfill = true
        MobileCore.registerEventListener(type: EventType.edge, source: EventSource.requestIdentity) { event in
            XCTAssertTrue(event.data?[EdgeConstants.EventDataKeys.LOCATION_HINT] as? Bool ?? false)
            let responseEvent = event.createResponseEvent(name: "Test Response Location Hint",
                                                          type: EventType.edge,
                                                          source: EventSource.responseIdentity,
                                                          data: [:])
            MobileCore.dispatch(event: responseEvent)
        }
        Edge.getLocationHint({ hint, error in
            XCTAssertNil(hint)
            XCTAssertNil(error)
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: 1)
    }

    // Test getLocationHint with invalid Hint and unexpected error returned
    func testGetLocationHint_dispatchesEdgeRequestIdentity_receivesResponseIdentity_withInvalidHint() {
        let expectation = XCTestExpectation(description: "Edge Get Location Hint")
        expectation.assertForOverFulfill = true
        MobileCore.registerEventListener(type: EventType.edge, source: EventSource.requestIdentity) { event in
            XCTAssertTrue(event.data?[EdgeConstants.EventDataKeys.LOCATION_HINT] as? Bool ?? false)
            let responseEvent = event.createResponseEvent(name: "Test Response Location Hint",
                                                          type: EventType.edge,
                                                          source: EventSource.responseIdentity,
                                                          data: ["locationHint": 5]) // correct key but wrong type
            MobileCore.dispatch(event: responseEvent)
        }
        Edge.getLocationHint({ hint, error in
            XCTAssertNil(hint)
            XCTAssertEqual(AEPError.unexpected.rawValue, (error as? AEPError)?.rawValue)
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: 1)
    }

    // Test getLocationHint with no response and callback timeout error returned
    func testGetLocationHint_dispatchesEdgeRequestIdentity_receivesResponseIdentity_withNoData() {
        let expectation = XCTestExpectation(description: "Edge Get Location Hint")
        expectation.assertForOverFulfill = true

        // No listener registered, no response event returned
        Edge.getLocationHint({ hint, error in
            XCTAssertNil(hint)
            XCTAssertEqual(AEPError.callbackTimeout.rawValue, (error as? AEPError)?.rawValue)
            expectation.fulfill()
        })

        // verify
        wait(for: [expectation], timeout: 2)
    }

}

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
}

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
@testable import AEPExperiencePlatform
import XCTest

/// Functional test suite for tests which require no SDK configuration and nil/pending configuration shared state.
class NoConfigFunctionalTests: FunctionalTestBase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false // fail so nil checks stop execution
        FunctionalTestBase.debugEnabled = false

        // 2 event hub shared states for registered extensions (TestableExperiencePlatform and InstrumentedExtension registered in FunctionalTestBase)
        setExpectationEvent(type: FunctionalTestConst.EventType.HUB, source: FunctionalTestConst.EventSource.SHARED_STATE, expectedCount: 2)

        MobileCore.registerExtensions([TestableExperiencePlatform.self])

        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
    }

    func testHandleExperienceEventRequest_withPendingConfigurationState_expectEventsQueueIsBlocked() {
        // NOTE: Configuration shared state must be PENDING (nil) for this test to be valid
        let configState = getSharedStateFor(FunctionalTestConst.SharedState.CONFIGURATION)
        XCTAssertNil(configState)

        // set expectations
        let handleExperienceEventRequestExpectation = XCTestExpectation(description: "handleExperienceEventRequest Called")
        handleExperienceEventRequestExpectation.isInverted = true
        TestableExperiencePlatform.handleExperienceEventRequestExpectation = handleExperienceEventRequestExpectation

        let readyForEventExpectation = XCTestExpectation(description: "readyForEvent Called")
        TestableExperiencePlatform.readyForEventExpectation = readyForEventExpectation

        // Dispatch request event which will block request queue as Configuration state is nil
        let requestEvent = Event(name: "Request Test",
                                 type: FunctionalTestConst.EventType.EXPERIENCE_PLATFORM,
                                 source: FunctionalTestConst.EventSource.REQUEST_CONTENT,
                                 data: ["key": "value"])
        MobileCore.dispatch(event: requestEvent)

        // Expected readyForEvent is called
        wait(for: [readyForEventExpectation], timeout: 1.0)

        // Expected handleExperienceEventRequest not called
        wait(for: [handleExperienceEventRequestExpectation], timeout: 1.0)
    }

    // todo: rewrite the test related to handling the response event
    // steps:
    // - set valid configs
    // - mock network response - multiple chuncks as a response for event1
    // - send xdm event1
    // - set invalid config (pending/nil)
    // - send xdm event2
    // - check callback is invoked correcly for event1, check xdm event2 not processed
    //    func testHandleResponseEvent_withPendingConfigurationState_expectResponseEventHandled() {
    //    }
}

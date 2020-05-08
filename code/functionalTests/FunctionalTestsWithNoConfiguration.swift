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


import XCTest
import ACPCore
@testable import ACPExperiencePlatform

/// Functional test suite for tests which require no SDK configuration and nil/pending configuration shared state.
/// This test suite cannot be run in same target as other tests which provide an SDK configuration to ACPCore
/// as all the tests in the same target use the same ACPCore instance.
class FunctionalTestsWithNoConfiguration: XCTestCase {

    override func setUp() {
        continueAfterFailure = false // fail so nil checks stop execution
        FunctionalTestUtils.resetUserDefaults()
        
        do {
            MonitorExtension.debug = false
            try ACPCore.registerExtension(MonitorExtension.self)
            try ACPCore.registerExtension(TestableExperiencePlatformInternal.self)
            ACPCore.start(nil)
        } catch {
            XCTFail("Failed test setUp: \(error.localizedDescription)")
        }
    }

    func testHandleResponseEvent_withPendingConfigurationState_expectResponseEventHandled() {
        // NOTE: Configuration shared state must be PENDING (nil) for this test to be valid
        let configState = MonitorExtension.getSharedStateFor(ExperiencePlatformConstants.SharedState.Configuration.stateOwner)
        XCTAssertNil(configState)
        
        let handleAddEventExpectation = XCTestExpectation(description: "Handle Add Event Called")
        TestableExperiencePlatformInternal.handleAddEventExpectation = handleAddEventExpectation
        
        let handleResponseEventExpectation = XCTestExpectation(description: "Handle Response Event Called")
        TestableExperiencePlatformInternal.handleResponseEventExpectation = handleResponseEventExpectation
        
        // Dispatch request event which will block request queue as Configuration state is nil
        let requestEvent = try? ACPExtensionEvent(name: "Request Test",
                                                  type: ExperiencePlatformConstants.eventTypeExperiencePlatform,
                                                  source: ExperiencePlatformConstants.eventSourceExtensionRequestContent,
                                                  data: ["key" : "value"])
        
        XCTAssertNotNil(requestEvent)
        
        XCTAssertNotNil(try? ACPCore.dispatchEvent(requestEvent!))
        
        // Expected handleAddEvent is called
        wait(for: [handleAddEventExpectation], timeout: 1.0)
        
        // Dispatch response event which will get processed in separate response queue
        let responseEvent = try? ACPExtensionEvent(name: "Response Test",
                                                   type: ExperiencePlatformConstants.eventTypeExperiencePlatform,
                                                   source: ExperiencePlatformConstants.eventSourceExtensionResponseContent,
                                                   data: ["key" : "value"])
        XCTAssertNotNil(responseEvent)
        
        XCTAssertNotNil(try? ACPCore.dispatchEvent(responseEvent!))
        
        // Expected handleResponseEvent is called
        wait(for: [handleResponseEventExpectation], timeout: 1.0)
    }


}

class TestableExperiencePlatformInternal : ExperiencePlatformInternal {
    
    static public var processAddEventExpectation: XCTestExpectation? = nil
    static public var processEventQueueExpectation: XCTestExpectation? = nil
    static public var handleAddEventExpectation: XCTestExpectation? = nil
    static public var processPlatformResponseEventExpectation: XCTestExpectation? = nil
    static public var handleResponseEventExpectation: XCTestExpectation? = nil
    
    override func processAddEvent(_ event: ACPExtensionEvent) {
        if let expectation = TestableExperiencePlatformInternal.processAddEventExpectation {
            expectation.fulfill()
        }
        super.processAddEvent(event)
    }
    
    override func processEventQueue(_ event: ACPExtensionEvent) {
        if let expectation = TestableExperiencePlatformInternal.processEventQueueExpectation {
            expectation.fulfill()
        }
        super.processEventQueue(event)
    }
    
    override func handleAddEvent(event: ACPExtensionEvent) -> Bool {
        if let expectation = TestableExperiencePlatformInternal.handleAddEventExpectation {
            expectation.fulfill()
        }
        return super.handleAddEvent(event: event)
    }
    
    override func processPlatformResponseEvent(_ event: ACPExtensionEvent){
        if let expectation = TestableExperiencePlatformInternal.processPlatformResponseEventExpectation {
            expectation.fulfill()
        }
        super.processPlatformResponseEvent(event)
    }
    
    override func handleResponseEvent(event: ACPExtensionEvent) -> Bool {
        if let expectation = TestableExperiencePlatformInternal.handleResponseEventExpectation {
            expectation.fulfill()
        }
        return super.handleResponseEvent(event: event)
    }
}

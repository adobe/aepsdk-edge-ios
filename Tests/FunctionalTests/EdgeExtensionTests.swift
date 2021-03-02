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
@testable import AEPServices
import XCTest

class EdgeExtensionTests: XCTest {
    var mockRuntime: TestableExtensionRuntime!
    var edge: Edge!

    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        edge = Edge(runtime: mockRuntime)
        edge.onRegistered()
    }

    override func tearDown() {
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    // MARK: Bootup scenarios
    func testBootup_whenNoConsentSharedState_usesDefaultYes() {
        // consent XDM shared state not set

        // dummy event to invoke readyForEvent
        _ = edge.readyForEvent(Event(name: "Dummy event", type: EventType.custom, source: EventSource.none, data: nil))

        // verify
        XCTAssertEqual(ConsentStatus.yes, edge.state?.currentCollectConsent)
    }

    func testBootup_whenConsentSharedState_usesPostedConsentStatus() {
        let consentXDMSharedState = ["consents":
                                        ["collect": ["val": "n"],
                                         "adID": ["val": "y"],
                                         "metadata": ["time": Date().getISO8601Date()]
                                        ]]
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME, data: (consentXDMSharedState, .set))

        // dummy event to invoke readyForEvent
        _ = edge.readyForEvent(Event(name: "Dummy event", type: EventType.custom, source: EventSource.none, data: nil))

        // verify
        XCTAssertEqual(ConsentStatus.no, edge.state?.currentCollectConsent)
    }

    func testBootup_whenConsentSharedStateWithNilData_usesDefaultPending() {
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME, data: (nil, .set))

        // dummy event to invoke readyForEvent
        _ = edge.readyForEvent(Event(name: "Dummy event", type: EventType.custom, source: EventSource.none, data: nil))

        // verify
        XCTAssertEqual(ConsentStatus.pending, edge.state?.currentCollectConsent)
    }

    func testBootup_executesOnlyOnce() {
        var consentXDMSharedState = ["consents": ["collect": ["val": "y"]]]
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME, data: (consentXDMSharedState, .set))

        // dummy event to invoke readyForEvent
        _ = edge.readyForEvent(Event(name: "Dummy event", type: EventType.custom, source: EventSource.none, data: nil))
        XCTAssertTrue(edge.state?.hasBooted ?? false)

        consentXDMSharedState = ["consents": ["collect": ["val": "p"]]]
        mockRuntime.simulateXDMSharedState(for: EdgeConstants.SharedState.Consent.SHARED_OWNER_NAME, data: (consentXDMSharedState, .set))
        _ = edge.readyForEvent(Event(name: "Dummy event", type: EventType.custom, source: EventSource.none, data: nil))

        // verify
        XCTAssertEqual(ConsentStatus.yes, edge.state?.currentCollectConsent)
    }
}

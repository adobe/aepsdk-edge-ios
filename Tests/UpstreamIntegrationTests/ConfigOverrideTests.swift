//
// Copyright 2023 Adobe. All rights reserved.
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
import AEPEdge
import AEPEdgeIdentity
import AEPServices
import AEPTestUtils
import Foundation
import XCTest

/// Performs validation on integration with the Edge Network upstream service
class ConfigOverrideTests: TestBase, AnyCodableAsserts {
    private let TIMEOUT_SEC: TimeInterval = 45
    private var edgeLocationHint: String? = TestEnvironment.defaultLocationHint
    private var networkService: RealNetworkService = RealNetworkService()

    let LOG_SOURCE = "ConfigOverrideTests"

    // Run before each test case
    override func setUp() {
        super.setUp()
        ServiceProvider.shared.networkService = networkService

        continueAfterFailure = true
        loggingEnabled = true

        MobileCore.setLogLevel(.trace)
        // Set tags mobile property ID for specific Edge Network environment
        MobileCore.configureWith(appId: TestEnvironment.defaultTagsMobilePropertyId)

        // Use expectation to guarantee Configuration shared state availability
        // Required primarily by `createInteractURL`
        setExpectationEvent(type: EventType.configuration, source: EventSource.responseContent)
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([Identity.self, Edge.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: TIMEOUT_SEC))
        assertExpectedEvents(ignoreUnexpectedEvents: true, timeout: TIMEOUT_SEC)

        // Set Edge location hint value if one is set for the test target
        setInitialLocationHint(edgeLocationHint)

        resetTestExpectations()
        networkService.reset()
    }

    override func tearDown() {
        EventHub.shared.shutdown()

        super.tearDown()

        resetTestExpectations()
        networkService.reset()
    }

    // MARK: Datastream config overrides test

    // Test configOverrides with valid data
    func testSendEvent_withValidConfigOverrides_receivesExpectedNetworkResponse() {
        // Setup
        let interactNetworkRequest = NetworkRequest(urlString: createInteractUrl(with: nil), httpMethod: .post)!
        networkService.setExpectation(for: interactNetworkRequest, expectedCount: 1)

        let configOverrides = ["com_adobe_experience_platform": [
                                    "datasets": [
                                        "event": [
                                            "datasetId": "6515e1dbfeb3b128d19bb1e4"
                                        ]
                                    ]
                                ],
                                "com_adobe_analytics": [
                                    "reportSuites": [
                                        "mobile5.e2e.rsid2"
                                    ]
                                ]]
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]], datastreamConfigOverride: configOverrides)

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // Network response assertions
        networkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let matchingResponses = networkService.getResponses(for: interactNetworkRequest)

        XCTAssertEqual(1, matchingResponses?.count)
        XCTAssertEqual(200, matchingResponses?.first?.responseCode)
    }

    // TODO: Enable after PDCL-11131 issue is fixed
    // Test configOverrides with dummy data
    func testSendEvent_withInvalidConfigOverrides_receivesExpectedNetworkResponseError() {
        // Setup
        let interactNetworkRequest = NetworkRequest(urlString: createInteractUrl(with: edgeLocationHint), httpMethod: .post)!

        networkService.setExpectation(for: interactNetworkRequest, expectedCount: 1)

        let expectedErrorJSON = """
        {
            "status": 400,
            "title": "Invalid request",
            "type": "https://ns.adobe.com/aep/errors/EXEG-0113-400"
        }
        """

        let configOverrides = ["test": ["key": "value"]]

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]], datastreamConfigOverride: configOverrides)

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // Network response assertions
        networkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let matchingResponses = networkService.getResponses(for: interactNetworkRequest)

        XCTAssertEqual(1, matchingResponses?.count)
        assertExactMatch(expected: expectedErrorJSON,
                        actual: matchingResponses?.first?.responseString)

        // Event assertions
        let errorEvents = getEdgeResponseErrors()
        XCTAssertEqual(1, errorEvents.count)
    }

    // TODO: Enable after PDCL-11131 issue is fixed
    // Tests ConfigOverrides with dataset not added in the datastream config and RSID not added to override setting in the Analytics upstream config
    func testSendEvent_withInvalidConfigOverrides_notConfiguredValues_receivesExpectedNetworkResponseError() {
        // Setup
        let interactNetworkRequest = NetworkRequest(urlString: createInteractUrl(with: edgeLocationHint), httpMethod: .post)!
        networkService.setExpectation(for: interactNetworkRequest, expectedCount: 1)

        let expectedErrorJSON = """
        {
            "status": 400,
            "title": "Invalid request",
            "type": "https://ns.adobe.com/aep/errors/EXEG-0113-400"
        }
        """

        let configOverrides = ["com_adobe_experience_platform": [
                                    "datasets": [
                                        "event": [
                                            "datasetId": "6515e1f6296d1e28d3209b9f"
                                        ]
                                    ]
                                ],
                                "com_adobe_analytics": [
                                    "reportSuites": [
                                        "mobile5e2e.rsid3"
                                    ]
                                ]]
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]], datastreamConfigOverride: configOverrides)

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // Network response assertions
        networkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let matchingResponses = networkService.getResponses(for: interactNetworkRequest)

        XCTAssertEqual(1, matchingResponses?.count)
        assertExactMatch(expected: expectedErrorJSON,
                        actual: matchingResponses?.first?.responseString)

        // Event assertions
        let errorEvents = getEdgeResponseErrors()
        XCTAssertEqual(1, errorEvents.count)
    }

    // TODO: Enable after PDCL-11131 issue is fixed
    func testSendEvent_withInvalidConfigOverrides_dummyValues_receivesExpectedNetworkResponseError() {
        // Setup
        let interactNetworkRequest = NetworkRequest(urlString: createInteractUrl(with: edgeLocationHint), httpMethod: .post)!
        networkService.setExpectation(for: interactNetworkRequest, expectedCount: 1)

        let expectedErrorJSON = """
        {
            "status": 400,
            "title": "Invalid request",
            "type": "https://ns.adobe.com/aep/errors/EXEG-0113-400"
        }
        """

        let configOverrides = ["com_adobe_experience_platform": [
                                    "datasets": [
                                        "event": [
                                            "datasetId": "DummyDataset"
                                        ]
                                    ]
                                ],
                                "com_adobe_analytics": [
                                    "reportSuites": [
                                        "DummyRSID1",
                                        "DummyRSID2"
                                    ]
                                ]]
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]], datastreamConfigOverride: configOverrides)

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // Network response assertions
        networkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let matchingResponses = networkService.getResponses(for: interactNetworkRequest)

        XCTAssertEqual(1, matchingResponses?.count)
        assertExactMatch(expected: expectedErrorJSON,
                        actual: matchingResponses?.first?.responseString)

        // Event assertions
        let errorEvents = getEdgeResponseErrors()
        XCTAssertEqual(1, errorEvents.count)
    }

    // TODO: Enable after PDCL-11131 issue is fixed
    // test configOverrides with valid dataset ID, one valid and one dummy value for RSIDs
    func testSendEvent_withInvalidConfigOverrides_containingValidAndDummyValues_receivesExpectedNetworkResponseError() {
        // Setup
        let interactNetworkRequest = NetworkRequest(urlString: createInteractUrl(with: edgeLocationHint), httpMethod: .post)!
        networkService.setExpectation(for: interactNetworkRequest, expectedCount: 1)

        let expectedErrorJSON = """
        {
            "status": 400,
            "title": "Invalid request",
            "type": "https://ns.adobe.com/aep/errors/EXEG-0113-400"
        }
        """

        let configOverrides = ["com_adobe_experience_platform": [
                                    "datasets": [
                                        "event": [
                                            "datasetId": "6515e1dbfeb3b128d19bb1e4"
                                        ]
                                    ]
                                ],
                                "com_adobe_analytics": [
                                    "reportSuites": [
                                        "mobile5.e2e.rsid2",
                                        "DummyRSID2"
                                    ]
                                ]]
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]], datastreamConfigOverride: configOverrides)

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // Network response assertions
        networkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let matchingResponses = networkService.getResponses(for: interactNetworkRequest)

        XCTAssertEqual(1, matchingResponses?.count)
        assertExactMatch(expected: expectedErrorJSON,
                        actual: matchingResponses?.first?.responseString)

        // Event assertions
        let errorEvents = getEdgeResponseErrors()
        XCTAssertEqual(1, errorEvents.count)
    }

    // Test datastream ID override with valid ID string
    func testSendEvent_withValidDatastreamIDOverride_receivesExpectedNetworkResponse() {
        // Setup
        let interactNetworkRequest = NetworkRequest(urlString: createInteractUrl(with: edgeLocationHint), httpMethod: .post)!
        networkService.setExpectation(for: interactNetworkRequest, expectedCount: 1)

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]], datastreamIdOverride: "15d7bce0-3e2c-447b-bbda-129c57c60820")

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // Network response assertions
        networkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let matchingResponses = networkService.getResponses(for: interactNetworkRequest)

        XCTAssertEqual(1, matchingResponses?.count)
        XCTAssertEqual(200, matchingResponses?.first?.responseCode)
    }

    // Test datastream ID override with dummy string
    func testSendEvent_withDummyDatastreamIDOverride_receivesExpectedNetworkResponseError() {
        // Setup
        let interactNetworkRequest = NetworkRequest(urlString: createInteractUrl(with: nil), httpMethod: .post)!
        networkService.setExpectation(for: interactNetworkRequest, expectedCount: 1)

        let expectedErrorJSON = """
        {
            "status": 400,
            "title": "Invalid datastream ID",
            "type": "https://ns.adobe.com/aep/errors/EXEG-0003-400"
        }
        """

        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"], data: ["data": ["test": "data"]], datastreamIdOverride: "DummyDatastreamID")

        // Test
        Edge.sendEvent(experienceEvent: experienceEvent)

        // Verify
        // Network response assertions
        networkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let matchingResponses = networkService.getResponses(for: interactNetworkRequest)

        XCTAssertEqual(1, matchingResponses?.count)
        assertExactMatch(expected: expectedErrorJSON,
                        actual: matchingResponses?.first?.responseString)

        // Event assertions
        let errorEvents = getEdgeResponseErrors()
        XCTAssertEqual(1, errorEvents.count)
    }
}

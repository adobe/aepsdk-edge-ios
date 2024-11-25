//
// Copyright 2024 Adobe. All rights reserved.
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
import AEPEdgeIdentity
@testable import AEPServices
import AEPTestUtils
import Foundation
import XCTest

class EdgeQueuedEntityFunctionalTests: TestBase, AnyCodableAsserts {
    private let TIMEOUT_SEC: TimeInterval = FunctionalTestConstants.Defaults.TIMEOUT_SEC
    private let exEdgeInteractProdUrl = URL(string: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR)! // swiftlint:disable:this force_unwrapping

    private let mockNetworkService: MockNetworkService = MockNetworkService()

    override func setUp() {
        ServiceProvider.shared.networkService = mockNetworkService

        super.setUp()

        continueAfterFailure = true
        loggingEnabled = true
        NamedCollectionDataStore.clear()
    }

    override func tearDown() {
        super.tearDown()

        mockNetworkService.reset()
        resetTestExpectations()
    }

    // Tests a queued data entity which does not contain Edge configuration is processed using "old" path which
    // sets the Edge configuration when hit is processed instead of when hit is queued.
    // Requires Edge version 5.0.1
    func testQueuedDataEntity_withoutEdgeConfiguration_isSentWhenEdgeStarts_usesConfigIdFromSharedState() {
        // Add EdgeDataEntity without configuration to data queue
        // Simulates hit queued from previous session
        guard let dataQueue = getDataQueue() else {
            XCTFail("Failed to get DataQueue.")
            return
        }

        mockQueuedEvent(dataQueue: dataQueue, edgeConfig: [:]) // Add DataEntity without configuration

        // Setup network response and expected network requests
        let responseConnection: HttpConnection = HttpConnection(data: "{\"test\": \"json\"}".data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // Start SDK, which will then process queue
        startMobileSDK()

        // Wait for expected network requests
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        // Validate result - hit uses configId from Configuration shared state
        XCTAssertEqual(1, resultNetworkRequests.count)
        XCTAssertEqual("12345-example", resultNetworkRequests[0].url.queryParam("configId"))

    }

    // Tests two queued data entities, one without an Edge Configuration and one with an Edge Configuration.
    // Validates the queued entity uses the configId from the Configuration shared state while
    // the other uses the configId contained in the data entity.
    // Requires Edge version 5.0.1
    func testQueuedDataEntity_withAndWithoutEdgeConfiguration_isSentWhenEdgeStart_usesCorrectConfigId() {
        // Add EdgeDataEntity to data queue
        // Simulates hit queued from previous session
        guard let dataQueue = getDataQueue() else {
            XCTFail("Failed to get DataQueue.")
            return
        }

        // Add DataEntity without configuration
        mockQueuedEvent(dataQueue: dataQueue, edgeConfig: [:], entityId: "entity-uuid")
        // Add DataEntity with configuration
        mockQueuedEvent(dataQueue: dataQueue, edgeConfig: ["edge.configId": "sample-configId"], entityId: "entity-uuid-2")

        // Setup network response and expected network requests
        let responseConnection: HttpConnection = HttpConnection(data: "{\"test\": \"json\"}".data(using: .utf8),
                                                                response: HTTPURLResponse(url: exEdgeInteractProdUrl,
                                                                                          statusCode: 200,
                                                                                          httpVersion: nil,
                                                                                          headerFields: nil),
                                                                error: nil)
        mockNetworkService.setMockResponse(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 2)

        // Start SDK, which will then process queue
        startMobileSDK()

        // Wait for expected network requests
        mockNetworkService.assertAllNetworkRequestExpectations(timeout: TIMEOUT_SEC)
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)

        // Validate result
        XCTAssertEqual(2, resultNetworkRequests.count)
        // First hit uses configId from Configuration shared state
        XCTAssertEqual("12345-example", resultNetworkRequests[0].url.queryParam("configId"))
        // Second hit uses configId from EdgeDataEntity
        XCTAssertEqual("sample-configId", resultNetworkRequests[1].url.queryParam("configId"))
    }

    /// Register's the Mobile SDK with Edge and Identity extenions while setting Configuration shared state with `edge.configId = 12345-example`.
    private func startMobileSDK() {
        // hub shared state update for 1 extension versions (InstrumentedExtension (registered in TestBase), IdentityEdge, Edge) IdentityEdge XDM, Config, and Edge shared state updates
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
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: TIMEOUT_SEC))
        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])

        assertExpectedEvents(ignoreUnexpectedEvents: true, timeout: TIMEOUT_SEC)
    }

    /// Add a `DataEntity` into the given `DataQueue`.
    /// - Parameters:
    ///   - dataQueue: the `DataQueue` to add the new entity
    ///   - edgeConfig: the Edge configuration to include with the `EdgeDataEntity`
    ///   - entityId: the UUID to identify the `DataEntity`
    private func mockQueuedEvent(dataQueue: DataQueue, edgeConfig: [String: AnyCodable], entityId: String = "entity-uuid") {
        let experienceEvent = Event(name: "queued event", type: EventType.edge, source: EventSource.requestContent, data: ["xdm": ["test": "data"]])
        let edgeEntity = EdgeDataEntity(event: experienceEvent, configuration: edgeConfig, identityMap: [:])
        let entity = DataEntity(uniqueIdentifier: entityId, timestamp: Date(), data: try? JSONEncoder().encode(edgeEntity))

        dataQueue.add(dataEntity: entity)
    }

    /// Get the `DataQueue` used by the `Edge` extension.
    /// - Returns: the `SQLiteDataQueue` for the `Edge` extension
    private func getDataQueue() -> DataQueue? {
        let serialQueue = DispatchQueue(label: "com.adobe.marketing.mobile.dataqueueservice")
        return SQLiteDataQueue(databaseName: EdgeConstants.EXTENSION_NAME, serialQueue: serialQueue)
    }

}

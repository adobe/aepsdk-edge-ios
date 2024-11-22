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
@testable import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
import AEPServices
import AEPTestUtils
import Foundation
import XCTest

class EdgeConsentTests: TestBase, AnyCodableAsserts {
    private let TIMEOUT_SEC: TimeInterval = FunctionalTestConstants.Defaults.TIMEOUT_SEC
    private let EVENTS_COUNT: Int32 = 5
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

    private var expectedRecordSeparatorString: String {
        if #available(iOS 17.2, tvOS 17.2, *) {
            return "\0"
        } else if #available(iOS 17, tvOS 17, *) {
            return ""
        } else {
            return "\u{0000}"
        }
    }
    private let mockNetworkService: MockNetworkService = MockNetworkService()

    // Runs before each test case
    override func setUp() {
        ServiceProvider.shared.networkService = mockNetworkService

        super.setUp()

        continueAfterFailure = false
        loggingEnabled = true
        NamedCollectionDataStore.clear()

        // hub shared state update for 5 extensions (InstrumentedExtension (registered in TestBase), Configuration, Edge, Consent, Edge Identity)
        setExpectationEvent(type: TestConstants.EventType.HUB, source: TestConstants.EventSource.SHARED_STATE, expectedCount: 5)
        setExpectationEvent(type: TestConstants.EventType.CONSENT, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)

        // expectations for update config request&response events
        setExpectationEvent(type: TestConstants.EventType.CONFIGURATION, source: TestConstants.EventSource.REQUEST_CONTENT, expectedCount: 1)
        setExpectationEvent(type: TestConstants.EventType.CONFIGURATION, source: TestConstants.EventSource.RESPONSE_CONTENT, expectedCount: 1)

        // wait for async registration because the EventHub is already started in TestBase
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([Identity.self, Edge.self, Consent.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: TIMEOUT_SEC))

        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])

        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
        mockNetworkService.reset()
    }

    // Runs after each test case
    override func tearDown() {

        super.tearDown()

        mockNetworkService.reset()
    }

    // MARK: test experience events handling based on collect consent value
    func testCollectConsent_whenNo_thenHits_hitsCleared() {
        // setup
        updateCollectConsent(status: ConsentStatus.no)
        getConsentsSync()
        resetTestExpectations()
        mockNetworkService.reset()

        // test
        fireManyEvents()

        // verify
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertTrue(resultNetworkRequests.isEmpty)
    }

    func testCollectConsent_whenYes_thenHits_hitsSent() {
        // setup
        updateCollectConsent(status: ConsentStatus.yes)
        getConsentsSync()
        resetTestExpectations()
        mockNetworkService.reset()

        // test
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: EVENTS_COUNT)
        fireManyEvents()

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
    }

    func testCollectConsent_whenPending_thenHits_thenYes_hitsSent() {
        // initial pending
        updateCollectConsent(status: ConsentStatus.pending)
        getConsentsSync()
        fireManyEvents()

        // verify
        var resultNetworkRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(0, resultNetworkRequests.count)

        // test - change to yes
        updateCollectConsent(status: ConsentStatus.yes)
        getConsentsSync()

        // verify
        resultNetworkRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(Int(EVENTS_COUNT), resultNetworkRequests.count)
    }

    func testCollectConsent_whenPending_thenHits_thenNo_hitsCleared() {
        // initial pending
        updateCollectConsent(status: ConsentStatus.pending)
        getConsentsSync()
        fireManyEvents()

        // test - change to no
        updateCollectConsent(status: ConsentStatus.no)
        getConsentsSync()

        // verify
        let resultNetworkRequests = mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertTrue(resultNetworkRequests.isEmpty)
    }

    func testCollectConsent_whenYes_thenPending_thenHits_thenNo_hitsCleared() {
        // initial yes, pending
        updateCollectConsent(status: ConsentStatus.yes)
        updateCollectConsent(status: ConsentStatus.pending)
        getConsentsSync()
        fireManyEvents()

        // test - change to no
        updateCollectConsent(status: ConsentStatus.no)
        getConsentsSync()

        // verify
        let resultNetworkRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    func testCollectConsent_whenNo_thenPending_thenHits_thenNo_hitsCleared() {
        // initial no, pending
        updateCollectConsent(status: ConsentStatus.no)
        updateCollectConsent(status: ConsentStatus.pending)
        getConsentsSync()
        fireManyEvents()

        // test - change to no
        updateCollectConsent(status: ConsentStatus.no)

        // verify
        let resultNetworkRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    func testCollectConsent_whenNo_thenPending_thenHits_thenYes_hitsSent() {
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 5)

        // initial no, pending
        updateCollectConsent(status: ConsentStatus.no)
        updateCollectConsent(status: ConsentStatus.pending)
        getConsentsSync()
        fireManyEvents()

        // test - change to yes
        updateCollectConsent(status: ConsentStatus.yes)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
    }

    // MARK: test consent events are being sent to Edge Network
    func testCollectConsentNo_sendsRequestToEdgeNetwork() {
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // test
        updateCollectConsent(status: ConsentStatus.no)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let interactRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(0, interactRequests.count)
        let consentRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(HttpMethod.post, consentRequests[0].httpMethod)

        let expectedJSON = #"""
        {
          "query": {
            "consent": {
              "operation": "update"
            }
          },
          "identityMap": {
            "ECID": [
              {
                "id": "STRING_TYPE",
                "authenticatedState": "ambiguous",
                "primary": false
              }
            ]
          },
          "consent": [
            {
              "standard": "Adobe",
              "version": "2.0",
              "value": {
                "collect": {
                  "val": "n"
                },
                "metadata": {
                  "time": "STRING_TYPE"
                }
              }
            }
          ],
          "meta": {
            "konductorConfig": {
              "streaming": {
                "enabled": true,
                "recordSeparator": "STRING_TYPE",
                "lineFeed": "\n"
              }
            }
          }
        }
        """#

        assertExactMatch(
            expected: expectedJSON,
            actual: consentRequests[0],
            pathOptions:
                CollectionEqualCount(scope: .subtree),
                ValueTypeMatch(paths: "identityMap.ECID[0].id", "consent[0].value.metadata.time", "meta.konductorConfig.streaming.recordSeparator"))
    }

    func testCollectConsentYes_sendsRequestToEdgeNetwork() {
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // test
        updateCollectConsent(status: ConsentStatus.yes)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let interactRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(0, interactRequests.count)
        let consentRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(HttpMethod.post, consentRequests[0].httpMethod)

        let expectedJSON = #"""
        {
          "query": {
            "consent": {
              "operation": "update"
            }
          },
          "identityMap": {
            "ECID": [
              {
                "id": "STRING_TYPE",
                "authenticatedState": "ambiguous",
                "primary": false
              }
            ]
          },
          "consent": [
            {
              "standard": "Adobe",
              "version": "2.0",
              "value": {
                "collect": {
                  "val": "y"
                },
                "metadata": {
                  "time": "STRING_TYPE"
                }
              }
            }
          ],
          "meta": {
            "konductorConfig": {
              "streaming": {
                "enabled": true,
                "recordSeparator": "STRING_TYPE",
                "lineFeed": "\n"
              }
            }
          }
        }
        """#
        assertExactMatch(
            expected: expectedJSON,
            actual: consentRequests[0],
            pathOptions:
                CollectionEqualCount(scope: .subtree),
                ValueTypeMatch(paths: "identityMap.ECID[0].id", "consent[0].value.metadata.time", "meta.konductorConfig.streaming.recordSeparator"))
    }

    func testCollectConsentOtherThanYesNo_doesNotSendRequestToEdgeNetwork() {
        // test
        updateCollectConsent(status: ConsentStatus.pending)
        updateCollectConsent(status: "u")
        updateCollectConsent(status: "some value")

        // verify
        let interactRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(0, interactRequests.count)
        let consentRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(0, consentRequests.count)
    }

    // MARK: Configurable Endpoint

    func testCollectConsent_withConfigurableEndpoint_withEmptyConfigEndpoint_UsesProduction() {
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // test
        updateCollectConsent(status: ConsentStatus.yes)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let consentRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(HttpMethod.post, consentRequests[0].httpMethod)
        XCTAssertTrue(consentRequests[0].url.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_CONSENT_PROD_URL_STR))
    }

    func testCollectConsent_withConfigurableEndpoint_withInvalidConfigEndpoint_UsesProduction() {
        // set to invalid endpoint
        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "invalid-endpoint"])
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // test
        updateCollectConsent(status: ConsentStatus.yes)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let consentRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(HttpMethod.post, consentRequests[0].httpMethod)
        XCTAssertTrue(consentRequests[0].url.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_CONSENT_PROD_URL_STR))
    }

    func testCollectConsent_withConfigurableEndpoint_withProductionConfigEndpoint_UsesProduction() {
        // set to prod endpoint
        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "prod"])
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // test
        updateCollectConsent(status: ConsentStatus.yes)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let consentRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(HttpMethod.post, consentRequests[0].httpMethod)
        XCTAssertTrue(consentRequests[0].url.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_CONSENT_PROD_URL_STR))
    }

    func testCollectConsent_withConfigurableEndpoint_withPreProductionConfigEndpoint_UsesPreProduction() {
        // set to pre-prod endpoint
        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "pre-prod"])
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_CONSENT_PRE_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // test
        updateCollectConsent(status: ConsentStatus.yes)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let consentRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_CONSENT_PRE_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(HttpMethod.post, consentRequests[0].httpMethod)
        XCTAssertTrue(consentRequests[0].url.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_CONSENT_PRE_PROD_URL_STR))
    }

    func testCollectConsent_withConfigurableEndpoint_withIntegrationConfigEndpoint_UsesIntegration() {
        // set to integration endpoint
        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "int"])
        mockNetworkService.setExpectationForNetworkRequest(url: TestConstants.EX_EDGE_CONSENT_INTEGRATION_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // test
        updateCollectConsent(status: ConsentStatus.yes)

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let consentRequests = self.mockNetworkService.getNetworkRequestsWith(url: TestConstants.EX_EDGE_CONSENT_INTEGRATION_URL_STR, httpMethod: HttpMethod.post, timeout: TIMEOUT_SEC)
        XCTAssertEqual(HttpMethod.post, consentRequests[0].httpMethod)
        XCTAssertTrue(consentRequests[0].url.absoluteURL.absoluteString.hasPrefix(TestConstants.EX_EDGE_CONSENT_INTEGRATION_URL_STR))
    }

    private func fireManyEvents() {
        for _ in 1 ... EVENTS_COUNT {
            Edge.sendEvent(experienceEvent: experienceEvent)
        }
    }

    private func updateCollectConsent(status: ConsentStatus) {
        Consent.update(with: ["consents": ["collect": ["val": status.rawValue]]])
    }

    private func updateCollectConsent(status: String) {
        Consent.update(with: ["consents": ["collect": ["val": status]]])
    }

    private func getConsentsSync() {
        let expectation = XCTestExpectation(description: "getConsents returned")
        Consent.getConsents {_, _  in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: TIMEOUT_SEC)
    }
}

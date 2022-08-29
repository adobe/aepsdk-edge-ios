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
import Foundation
import XCTest

class EdgeConsentTests: FunctionalTestBase {
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

    public class override func setUp() {
        super.setUp()
        FunctionalTestBase.debugEnabled = true
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        FileManager.default.clearCache()

        // hub shared state update for 5 extensions (InstrumentedExtension (registered in FunctionalTestBase), Configuration, Edge, Consent, Edge Identity)
        setExpectationEvent(type: FunctionalTestConst.EventType.HUB, source: FunctionalTestConst.EventSource.SHARED_STATE, expectedCount: 5)
        setExpectationEvent(type: FunctionalTestConst.EventType.CONSENT, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT, expectedCount: 1)

        // expectations for update config request&response events
        setExpectationEvent(type: FunctionalTestConst.EventType.CONFIGURATION, source: FunctionalTestConst.EventSource.REQUEST_CONTENT, expectedCount: 1)
        setExpectationEvent(type: FunctionalTestConst.EventType.CONFIGURATION, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT, expectedCount: 1)

        // wait for async registration because the EventHub is already started in FunctionalTestBase
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([Identity.self, Edge.self, Consent.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))

        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])

        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
    }

    // MARK: test experience events handling based on collect consent value
    func testCollectConsent_whenNo_thenHits_hitsCleared() {
        // setup
        updateCollectConsent(status: ConsentStatus.no)
        getConsentsSync()
        resetTestExpectations()

        // test
        fireManyEvents()

        // verify
        let resultNetworkRequests = getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
        XCTAssertTrue(resultNetworkRequests.isEmpty)
    }

    func testCollectConsent_whenYes_thenHits_hitsSent() {
        // setup
        updateCollectConsent(status: ConsentStatus.yes)
        getConsentsSync()
        resetTestExpectations()

        // test
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: EVENTS_COUNT)
        fireManyEvents()

        // verify
        assertNetworkRequestsCount()
    }

    func testCollectConsent_whenPending_thenHits_thenYes_hitsSent() {
        // initial pending
        updateCollectConsent(status: ConsentStatus.pending)
        getConsentsSync()
        fireManyEvents()

        // verify
        var resultNetworkRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 2)
        XCTAssertEqual(0, resultNetworkRequests.count)

        // test - change to yes
        updateCollectConsent(status: ConsentStatus.yes)
        getConsentsSync()

        // verify
        resultNetworkRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 2)
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
        let resultNetworkRequests = getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
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
        let resultNetworkRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
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
        let resultNetworkRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
        XCTAssertEqual(0, resultNetworkRequests.count)
    }

    func testCollectConsent_whenNo_thenPending_thenHits_thenYes_hitsSent() {
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 5)

        // initial no, pending
        updateCollectConsent(status: ConsentStatus.no)
        updateCollectConsent(status: ConsentStatus.pending)
        getConsentsSync()
        fireManyEvents()

        // test - change to yes
        updateCollectConsent(status: ConsentStatus.yes)

        // verify
        assertNetworkRequestsCount()
    }

    // MARK: test consent events are being sent to Edge Network
    func testCollectConsentNo_sendsRequestToEdgeNetwork() {
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // test
        updateCollectConsent(status: ConsentStatus.no)

        // verify
        assertNetworkRequestsCount()
        let interactRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
        XCTAssertEqual(0, interactRequests.count)
        let consentRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
        XCTAssertEqual(HttpMethod.post, consentRequests[0].httpMethod)
        let requestBody = getFlattenNetworkRequestBody(consentRequests[0])
        print(requestBody)
        XCTAssertEqual(11, requestBody.count)
        XCTAssertEqual("update", requestBody["query.consent.operation"] as? String)
        XCTAssertNotNil(requestBody["identityMap.ECID[0].id"] as? String)
        XCTAssertEqual("ambiguous", requestBody["identityMap.ECID[0].authenticatedState"] as? String)
        XCTAssertEqual(false, requestBody["identityMap.ECID[0].primary"] as? Bool)
        XCTAssertEqual("Adobe", requestBody["consent[0].standard"] as? String)
        XCTAssertEqual("2.0", requestBody["consent[0].version"] as? String)
        XCTAssertEqual("n", requestBody["consent[0].value.collect.val"] as? String)
        XCTAssertNotNil(requestBody["consent[0].value.metadata.time"] as? String)
        XCTAssertEqual(true, requestBody["meta.konductorConfig.streaming.enabled"] as? Bool)
        XCTAssertEqual("\u{0000}", requestBody["meta.konductorConfig.streaming.recordSeparator"] as? String)
        XCTAssertEqual("\n", requestBody["meta.konductorConfig.streaming.lineFeed"] as? String)
    }

    func testCollectConsentYes_sendsRequestToEdgeNetwork() {
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // test
        updateCollectConsent(status: ConsentStatus.yes)

        // verify
        assertNetworkRequestsCount()
        let interactRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
        XCTAssertEqual(0, interactRequests.count)
        let consentRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
        XCTAssertEqual(HttpMethod.post, consentRequests[0].httpMethod)
        let requestBody = getFlattenNetworkRequestBody(consentRequests[0])
        print(requestBody)
        XCTAssertEqual(11, requestBody.count)
        XCTAssertEqual("update", requestBody["query.consent.operation"] as? String)
        XCTAssertNotNil(requestBody["identityMap.ECID[0].id"] as? String)
        XCTAssertEqual("ambiguous", requestBody["identityMap.ECID[0].authenticatedState"] as? String)
        XCTAssertEqual(false, requestBody["identityMap.ECID[0].primary"] as? Bool)
        XCTAssertEqual("Adobe", requestBody["consent[0].standard"] as? String)
        XCTAssertEqual("2.0", requestBody["consent[0].version"] as? String)
        XCTAssertEqual("y", requestBody["consent[0].value.collect.val"] as? String)
        XCTAssertNotNil(requestBody["consent[0].value.metadata.time"] as? String)
        XCTAssertEqual(true, requestBody["meta.konductorConfig.streaming.enabled"] as? Bool)
        XCTAssertEqual("\u{0000}", requestBody["meta.konductorConfig.streaming.recordSeparator"] as? String)
        XCTAssertEqual("\n", requestBody["meta.konductorConfig.streaming.lineFeed"] as? String)
    }

    func testCollectConsentOtherThanYesNo_doesNotSendRequestToEdgeNetwork() {
        // test
        updateCollectConsent(status: ConsentStatus.pending)
        updateCollectConsent(status: "u")
        updateCollectConsent(status: "some value")

        // verify
        let interactRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_INTERACT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
        XCTAssertEqual(0, interactRequests.count)
        let consentRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
        XCTAssertEqual(0, consentRequests.count)
    }

    // MARK: Configurable Endpoint

    func testCollectConsent_withConfigurableEndpoint_withEmptyConfigEndpoint_UsesProduction() {
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // test
        updateCollectConsent(status: ConsentStatus.yes)

        // verify
        assertNetworkRequestsCount()
        let consentRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
        XCTAssertEqual(HttpMethod.post, consentRequests[0].httpMethod)
        XCTAssertTrue(consentRequests[0].url.absoluteURL.absoluteString.hasPrefix(FunctionalTestConst.EX_EDGE_CONSENT_PROD_URL_STR))
    }

    func testCollectConsent_withConfigurableEndpoint_withInvalidConfigEndpoint_UsesProduction() {
        // set to invalid endpoint
        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "invalid-endpoint"])
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // test
        updateCollectConsent(status: ConsentStatus.yes)

        // verify
        assertNetworkRequestsCount()
        let consentRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
        XCTAssertEqual(HttpMethod.post, consentRequests[0].httpMethod)
        XCTAssertTrue(consentRequests[0].url.absoluteURL.absoluteString.hasPrefix(FunctionalTestConst.EX_EDGE_CONSENT_PROD_URL_STR))
    }

    func testCollectConsent_withConfigurableEndpoint_withProductionConfigEndpoint_UsesProduction() {
        // set to prod endpoint
        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "prod"])
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // test
        updateCollectConsent(status: ConsentStatus.yes)

        // verify
        assertNetworkRequestsCount()
        let consentRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_CONSENT_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
        XCTAssertEqual(HttpMethod.post, consentRequests[0].httpMethod)
        XCTAssertTrue(consentRequests[0].url.absoluteURL.absoluteString.hasPrefix(FunctionalTestConst.EX_EDGE_CONSENT_PROD_URL_STR))
    }

    func testCollectConsent_withConfigurableEndpoint_withPreProductionConfigEndpoint_UsesPreProduction() {
        // set to pre-prod endpoint
        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "pre-prod"])
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_CONSENT_PRE_PROD_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // test
        updateCollectConsent(status: ConsentStatus.yes)

        // verify
        assertNetworkRequestsCount()
        let consentRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_CONSENT_PRE_PROD_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
        XCTAssertEqual(HttpMethod.post, consentRequests[0].httpMethod)
        XCTAssertTrue(consentRequests[0].url.absoluteURL.absoluteString.hasPrefix(FunctionalTestConst.EX_EDGE_CONSENT_PRE_PROD_URL_STR))
    }

    func testCollectConsent_withConfigurableEndpoint_withIntegrationConfigEndpoint_UsesIntegration() {
        // set to integration endpoint
        MobileCore.updateConfigurationWith(configDict: ["edge.environment": "int"])
        setExpectationNetworkRequest(url: FunctionalTestConst.EX_EDGE_CONSENT_INTEGRATION_URL_STR, httpMethod: HttpMethod.post, expectedCount: 1)

        // test
        updateCollectConsent(status: ConsentStatus.yes)

        // verify
        assertNetworkRequestsCount()
        let consentRequests = self.getNetworkRequestsWith(url: FunctionalTestConst.EX_EDGE_CONSENT_INTEGRATION_URL_STR, httpMethod: HttpMethod.post, timeout: 1)
        XCTAssertEqual(HttpMethod.post, consentRequests[0].httpMethod)
        XCTAssertTrue(consentRequests[0].url.absoluteURL.absoluteString.hasPrefix(FunctionalTestConst.EX_EDGE_CONSENT_INTEGRATION_URL_STR))
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
        wait(for: [expectation], timeout: 1)
    }
}

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

@testable import AEPEdge
import Foundation
import XCTest

class EdgeEndpointTests: XCTestCase {

    override func setUp() {
        // continueAfterFailure set to true to continue running all test cases
        continueAfterFailure = true
    }

    // MARK: EdgeEnvironmentType tests
    func testEnvironmentTypeProduction() {
        XCTAssertEqual(.production, EdgeEnvironmentType(optionalRawValue: "prod"))
    }

    func testEnvironmentTypeProductionIsLowercased() {
        XCTAssertEqual(.production, EdgeEnvironmentType(optionalRawValue: "PROD"))
    }

    func testEnvironmentTypePreProduction() {
        XCTAssertEqual(.preProduction, EdgeEnvironmentType(optionalRawValue: "pre-prod"))
    }

    func testEnvironmentTypePreProductionIsLowercased() {
        XCTAssertEqual(.preProduction, EdgeEnvironmentType(optionalRawValue: "PRE-PROD"))
    }

    func testEnvironmentTypeIntegration() {
        XCTAssertEqual(.integration, EdgeEnvironmentType(optionalRawValue: "int"))
    }

    func testEnvironmentTypeIntegrationIsLowercased() {
        XCTAssertEqual(.integration, EdgeEnvironmentType(optionalRawValue: "INT"))
    }

    func testEnvironmentTypeDefaultsToProductionWhenNil() {
        XCTAssertEqual(.production, EdgeEnvironmentType(optionalRawValue: nil))
    }

    func testEnvironmentTypeDefaultsToProductionWhenEmpty() {
        XCTAssertEqual(.production, EdgeEnvironmentType(optionalRawValue: ""))
    }

    func testEnvironmentTypeDefaultsToProductionWhenInvalid() {
        XCTAssertEqual(.production, EdgeEnvironmentType(optionalRawValue: "invalid"))
    }

    // MARK: EdgeEndpoint tests
    func testEdgeEndpoint_interact_defaultDomain() {
        // cases defined as: ($0: input EnvironmentType, $1: expected output EdgeEndpoint URL, $2: Test case name)
        let cases = [(EdgeEnvironmentType.production, "https://edge.adobedc.net/ee/v1/interact", "DefaultProductionEndpoint"),
                     (.preProduction, "https://edge.adobedc.net/ee-pre-prd/v1/interact", "DefaultPreProductionEndpoint"),
                     (.integration, "https://edge-int.adobedc.net/ee/v1/interact", "DefaultIntegrationEndpoint")]

        cases.forEach {
            let endpoint = EdgeEndpoint(requestType: EdgeRequestType.interact, environmentType: $0)
            XCTAssertEqual($1, endpoint.url?.absoluteString, "\($2) test case failed.")
        }
    }

    func testEdgeEndpoint_interact_customDomain() {
        let domain1 = "my.awesome.site"
        let domain2 = ""
        // cases defined as: ($0: input EnvironmentType, $1: input custom domain, $2: expected output EdgeEndpoint URL, $3: Test case name)
        let cases = [(EdgeEnvironmentType.production, domain1, "https://\(domain1)/ee/v1/interact", "CustomProductionEndpoint"),
                     (.preProduction, domain1, "https://\(domain1)/ee-pre-prd/v1/interact", "CustomPreProductionEndpoint"),
                     (.integration, domain1, "https://edge-int.adobedc.net/ee/v1/interact", "CustomIntegrationEndpoint"),
                     (.production, domain2, "https://edge.adobedc.net/ee/v1/interact", "CustomEmptyDomainUsesDefault")]

        cases.forEach {
            let endpoint = EdgeEndpoint(requestType: EdgeRequestType.interact, environmentType: $0, optionalDomain: $1)
            XCTAssertEqual($2, endpoint.url?.absoluteString, "\($3) test case failed.")
        }
    }

    func testEdgeEndpoint_consent_defaultDomain() {
        // cases defined as: ($0: input EnvironmentType, $1: expected output EdgeEndpoint URL, $2: Test case name)
        let cases = [(EdgeEnvironmentType.production, "https://edge.adobedc.net/ee/v1/privacy/set-consent", "DefaultProductionEndpoint"),
                     (.preProduction, "https://edge.adobedc.net/ee-pre-prd/v1/privacy/set-consent", "DefaultProductionEndpoint"),
                     (.integration, "https://edge-int.adobedc.net/ee/v1/privacy/set-consent", "DefaultIntegrationEndpoint")]

        cases.forEach {
            let endpoint = EdgeEndpoint(requestType: EdgeRequestType.consent, environmentType: $0)
            XCTAssertEqual($1, endpoint.url?.absoluteString, "\($2) test case failed.")
        }
    }

    func testEdgeEndpoint_consent_customDomain() {
        let domain1 = "my.awesome.site"
        let domain2 = ""
        // cases defined as: ($0: input EnvironmentType, $1: input custom domain, $2: expected output EdgeEndpoint URL, $3: Test case name)
        let cases = [(EdgeEnvironmentType.production, domain1, "https://\(domain1)/ee/v1/privacy/set-consent", "CustomProductionEndpoint"),
                     (.preProduction, domain1, "https://\(domain1)/ee-pre-prd/v1/privacy/set-consent", "CustomPreProductionEndpoint"),
                     (.integration, domain1, "https://edge-int.adobedc.net/ee/v1/privacy/set-consent", "CustomIntegrationEndpoint"),
                     (.production, domain2, "https://edge.adobedc.net/ee/v1/privacy/set-consent", "CustomEmptyDomainUsesDefault")]

        cases.forEach {
            let endpoint = EdgeEndpoint(requestType: EdgeRequestType.consent, environmentType: $0, optionalDomain: $1)
            XCTAssertEqual($2, endpoint.url?.absoluteString, "\($3) test case failed.")
        }
    }

}

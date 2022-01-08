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
        continueAfterFailure = false
    }

    func testDefaultProductionEndpoint() {
        let endpoint = EdgeEndpoint(type: .production)
        let expected = "https://\(EdgeConstants.NetworkKeys.EDGE_DEFAULT_DOMAIN)\(EdgeConstants.NetworkKeys.EDGE_ENDPOINT_PATH)"
        XCTAssertEqual(expected, endpoint.endpointUrl)
    }

    func testDefaultPreProductionEndpoint() {
        let endpoint = EdgeEndpoint(type: .preProduction)
        let expected = "https://\(EdgeConstants.NetworkKeys.EDGE_DEFAULT_DOMAIN)\(EdgeConstants.NetworkKeys.EDGE_ENDPOINT_PRE_PRODUCTION_PATH)"
        XCTAssertEqual(expected, endpoint.endpointUrl)
    }

    func testDefaultIntegrationEndpoint() {
        let endpoint = EdgeEndpoint(type: .integration)
        let expected = EdgeConstants.NetworkKeys.EDGE_ENDPOINT_INTEGRATION
        XCTAssertEqual(expected, endpoint.endpointUrl)
    }

    func testCustomProductionEndpoint() {
        let domain = "my.awesome.site"
        let endpoint = EdgeEndpoint(type: .production, optionalDomain: domain)
        let expected = "https://\(domain)\(EdgeConstants.NetworkKeys.EDGE_ENDPOINT_PATH)"
        XCTAssertEqual(expected, endpoint.endpointUrl)
    }

    func testCustomPreProductionEndpoint() {
        let domain = "my.awesome.site"
        let endpoint = EdgeEndpoint(type: .preProduction, optionalDomain: domain)
        let expected = "https://\(domain)\(EdgeConstants.NetworkKeys.EDGE_ENDPOINT_PRE_PRODUCTION_PATH)"
        XCTAssertEqual(expected, endpoint.endpointUrl)
    }

    func testCustomIntegrationEndpoint() {
        let domain = "my.awesome.site"
        let endpoint = EdgeEndpoint(type: .integration, optionalDomain: domain)
        let expected = EdgeConstants.NetworkKeys.EDGE_ENDPOINT_INTEGRATION
        XCTAssertEqual(expected, endpoint.endpointUrl)
    }

    func testCustomDomainRemovesHttpsPrefix() {
        let domain = "https://my.awesome.site"
        let endpoint = EdgeEndpoint(type: .production, optionalDomain: domain)
        let expected = "https://my.awesome.site\(EdgeConstants.NetworkKeys.EDGE_ENDPOINT_PATH)"
        XCTAssertEqual(expected, endpoint.endpointUrl)
    }

    func testCustomDomainRemovesHttpPrefix() {
        let domain = "http://my.awesome.site"
        let endpoint = EdgeEndpoint(type: .production, optionalDomain: domain)
        let expected = "https://my.awesome.site\(EdgeConstants.NetworkKeys.EDGE_ENDPOINT_PATH)"
        XCTAssertEqual(expected, endpoint.endpointUrl)
    }

    func testCustomEmptyDomainUsesDefault() {
        let domain = ""
        let endpoint = EdgeEndpoint(type: .production, optionalDomain: domain)
        let expected = "https://\(EdgeConstants.NetworkKeys.EDGE_DEFAULT_DOMAIN)\(EdgeConstants.NetworkKeys.EDGE_ENDPOINT_PATH)"
        XCTAssertEqual(expected, endpoint.endpointUrl)
    }

    func testCustomDomainIsLowercase() {
        let domain = "MY.LOUD.SITE"
        let endpoint = EdgeEndpoint(type: .production, optionalDomain: domain)
        let expected = "https://my.loud.site\(EdgeConstants.NetworkKeys.EDGE_ENDPOINT_PATH)"
        XCTAssertEqual(expected, endpoint.endpointUrl)
    }
}

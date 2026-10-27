//
// Copyright 2026 Adobe. All rights reserved.
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
import AEPServices
import AEPTestUtils
import XCTest

class DeviceAttributesRequestBuilderTests: XCTestCase, AnyCodableAsserts {
    private let testDataStoreName = "DeviceAttributesRequestBuilderTests"
    private let identityMap: [String: Any] = ["ECID": [["id": "ecid"]]]
    private let implementationDetails: [String: Any] = [
        "name": "https://ns.adobe.com/experience/mobilesdk/ios",
        "environment": "app",
        "version": "5.0.0+1.0.0"
    ]

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
    }

    func testBuildPayload_usesSdkXdmAndMetaInsteadOfProducerValues() throws {
        StoreResponsePayloadManager(testDataStoreName)
            .saveStorePayloads([StoreResponsePayload(payload: StorePayload(key: "key", value: "value", maxAge: 3600))])
        let builder = DeviceAttributesRequestBuilder(dataStoreName: testDataStoreName)
        let eventData: [String: Any] = ["app": ["identifier": "com.example.app"],
                                        "timezone": "America/Los_Angeles",
                                        "xdm": ["identityMap": ["ECID": [["id": "producer-ecid"]]], "producerField": true],
                                        "meta": ["configOverrides": ["datastreamIdOverride": "producer-datastream"]]]

        let payload = try XCTUnwrap(builder.buildPayload(eventData: eventData,
                                                         implementationDetails: implementationDetails,
                                                         identityMap: identityMap))

        let expectedJSON = #"""
        {
          "app": { "identifier": "com.example.app" },
          "timezone": "America/Los_Angeles",
          "xdm": {
            "implementationDetails": {
              "name": "https://ns.adobe.com/experience/mobilesdk/ios",
              "environment": "app",
              "version": "5.0.0+1.0.0"
            },
            "identityMap": { "ECID": [ { "id": "ecid" } ] }
          },
          "meta": {
            "state": {
              "entries": [ { "key": "key", "value": "value", "maxAge": 3600 } ]
            }
          }
        }
        """#
        assertExactMatch(expected: expectedJSON, actual: payload)
    }

    func testBuildPayload_preservesAppEmptyTokenAndTimezoneWithoutEventsEnvelope() throws {
        let builder = DeviceAttributesRequestBuilder(dataStoreName: testDataStoreName)
        let attributes: [String: Any] = [
            "app": ["id": "com.example.app", "platform": "apnsSandbox"],
            "timezone": "Europe/London",
            "tokens": [
                "pushNotification": "",
                "liveActivityStart": [["attributeType": "A", "value": "start"]],
                "liveActivityUpdate": []
            ]
        ]
        let payload = try XCTUnwrap(builder.buildPayload(eventData: attributes, implementationDetails: nil, identityMap: nil))
        let decoded = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as? [String: Any])

        XCTAssertEqual(attributes["app"] as? NSDictionary, decoded["app"] as? NSDictionary)
        XCTAssertEqual(attributes["tokens"] as? NSDictionary, decoded["tokens"] as? NSDictionary)
        XCTAssertEqual("Europe/London", decoded["timezone"] as? String)
        XCTAssertNil(decoded["events"])
        XCTAssertNil(decoded["xdm"])
        XCTAssertNil(decoded["meta"])
    }

    func testBuildPayload_discardsProducerXdmAndMetaWithoutSdkEnrichment() throws {
        let builder = DeviceAttributesRequestBuilder(dataStoreName: testDataStoreName)
        let attributes: [String: Any] = [
            "app": ["id": "com.example.app", "newAttribute": ["enabled": true]],
            "timezone": "Europe/London",
            "newBackendAttribute": ["values": [1, 2], "label": "dynamic"]
        ]
        var producerData = attributes
        producerData["xdm"] = ["identityMap": ["ECID": [["id": "producer-ecid"]]]]
        producerData["meta"] = ["configOverrides": ["datastreamIdOverride": "producer-datastream"]]

        let payload = try XCTUnwrap(builder.buildPayload(eventData: producerData, implementationDetails: nil, identityMap: nil))
        let decoded = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as? [String: Any])

        XCTAssertEqual(attributes as NSDictionary, decoded as NSDictionary)
    }

    func testBuildPayload_onlyProducerSdkFieldsAndNoEnrichment_returnsNil() {
        let builder = DeviceAttributesRequestBuilder(dataStoreName: testDataStoreName)
        XCTAssertNil(builder.buildPayload(eventData: ["xdm": ["producerField": "value"], "meta": ["producerField": "value"]],
                                          implementationDetails: nil,
                                          identityMap: nil))
    }

    func testBuildPayload_nilOrEmptyEventData_returnsNil() {
        let builder = DeviceAttributesRequestBuilder(dataStoreName: testDataStoreName)
        XCTAssertNil(builder.buildPayload(eventData: nil, implementationDetails: implementationDetails, identityMap: identityMap))
        XCTAssertNil(builder.buildPayload(eventData: [:], implementationDetails: implementationDetails, identityMap: identityMap))
    }

    func testBuildPayload_expiredStorePayloadsAreNotSent() throws {
        StoreResponsePayloadManager(testDataStoreName)
            .saveStorePayloads([StoreResponsePayload(payload: StorePayload(key: "expired", value: "value", maxAge: -1))])
        let builder = DeviceAttributesRequestBuilder(dataStoreName: testDataStoreName)

        let payload = try XCTUnwrap(builder.buildPayload(eventData: ["timezone": "UTC"], implementationDetails: nil, identityMap: nil))

        XCTAssertNil(payload["meta"])
    }

    func testBuildRequestBody_isCompactJson() throws {
        let builder = DeviceAttributesRequestBuilder(dataStoreName: testDataStoreName)

        let body = try XCTUnwrap(builder.buildRequestBody(eventData: ["timezone": "UTC", "app": ["id": "com.example.app"]],
                                                          implementationDetails: nil,
                                                          identityMap: identityMap))

        XCTAssertFalse(body.contains("\n"))
        let expectedJSON = #"{"timezone": "UTC", "app": {"id": "com.example.app"}, "xdm": {"identityMap": {"ECID": [{"id": "ecid"}]}}}"#
        assertExactMatch(expected: expectedJSON, actual: body)
    }

    func testBuildRequestBody_unencodableData_returnsNil() {
        let builder = DeviceAttributesRequestBuilder(dataStoreName: testDataStoreName)
        XCTAssertNil(builder.buildRequestBody(eventData: ["invalid": Double.nan], implementationDetails: nil, identityMap: nil))
    }

    func testBuildRequestBody_multipleEcids_retainsCurrentMetadataAndOtherNamespacesWithoutMutatingInput() throws {
        let builder = DeviceAttributesRequestBuilder(dataStoreName: testDataStoreName)
        let current: [String: Any] = ["id": "current-ecid", "authenticatedState": "ambiguous", "primary": false]
        let email: [[String: Any]] = [["id": "test@example.com", "authenticatedState": "authenticated", "primary": true]]
        let identities: [String: Any] = [
            "ECID": [current, ["id": "legacy-ecid"], ["id": "another-ecid"]],
            "Email": email
        ]
        let original = identities as NSDictionary

        let body = try XCTUnwrap(builder.buildRequestBody(eventData: ["timezone": "Europe/Rome"],
                                                          implementationDetails: nil,
                                                          identityMap: identities))
        let data = try XCTUnwrap(body.data(using: .utf8))
        let decoded = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let xdm = try XCTUnwrap(decoded["xdm"] as? [String: Any])
        let requestIdentities = try XCTUnwrap(xdm["identityMap"] as? [String: Any])
        let ecids = try XCTUnwrap(requestIdentities["ECID"] as? [[String: Any]])

        XCTAssertEqual(ecids.count, 1)
        XCTAssertEqual(ecids[0] as NSDictionary, current as NSDictionary)
        XCTAssertEqual(requestIdentities["Email"] as? NSArray, email as NSArray)
        XCTAssertEqual(identities as NSDictionary, original)
        XCTAssertEqual((identities["ECID"] as? [[String: Any]])?.count, 3)
    }

    func testBuildPayload_singleEcid_preservesIdentityMap() throws {
        let builder = DeviceAttributesRequestBuilder(dataStoreName: testDataStoreName)
        let identities: [String: Any] = [
            "ECID": [["id": "current-ecid", "authenticatedState": "ambiguous", "primary": false]],
            "Email": [["id": "test@example.com"]]
        ]

        let payload = try XCTUnwrap(builder.buildPayload(eventData: ["timezone": "Europe/Rome"],
                                                         implementationDetails: nil,
                                                         identityMap: identities))
        let data = try JSONEncoder().encode(payload)
        let decoded = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let xdm = try XCTUnwrap(decoded["xdm"] as? [String: Any])

        XCTAssertEqual(xdm["identityMap"] as? NSDictionary, identities as NSDictionary)
    }
}

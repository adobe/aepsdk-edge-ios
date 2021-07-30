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

@testable import AEPEdge
import Foundation
import XCTest

class EdgeHitTests: XCTestCase {
    private let CONFIG_ID = "testConfigId"
    private let EDGE_REQUEST = EdgeRequest(meta: nil, xdm: nil, events: [["test": "data"]])
    private let CONSENT_UPDATE_REQUEST = EdgeConsentUpdate(meta: nil, identityMap: nil, consent: [EdgeConsentPayload(standard: "Adobe", version: "2.0", value: ["consent": ["collect": "y"]])])

    override func setUp() {
        continueAfterFailure = false
    }

    // MARK: ExperienceEventsEdgeHit tests

    func testExperienceEventsEdgeHit() {
        let edgeHit = ExperienceEventsEdgeHit(edgeEndpoint: .production, configId: CONFIG_ID, request: EDGE_REQUEST)
        XCTAssertEqual(EdgeEndpoint.production, .production)
        XCTAssertEqual(CONFIG_ID, edgeHit.configId)
        XCTAssertNotNil(edgeHit.requestId)
        XCTAssertEqual(EDGE_REQUEST.events, edgeHit.request.events)
    }

    func testExperienceEventsEdgeHit_streamingSettings() {
        let edgeHit1 = ExperienceEventsEdgeHit(edgeEndpoint: .production, configId: CONFIG_ID, request: EdgeRequest(meta: nil, xdm: nil, events: [["test": "data"]]))
        XCTAssertNil(edgeHit1.getStreamingSettings())

        let streamingSettings = Streaming(recordSeparator: "A", lineFeed: "B")
        let edgeHit2 = ExperienceEventsEdgeHit(edgeEndpoint: .production,
                                               configId: CONFIG_ID,
                                               request: EdgeRequest(meta: RequestMetadata(konductorConfig: KonductorConfig(streaming: streamingSettings), state: nil),
                                                                    xdm: nil, events: [["test": "data"]]))
        XCTAssertNotNil(edgeHit2.getStreamingSettings())
    }

    func testExperienceEventsEdgeHit_getPayload_noStreaming() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let json = """
                    {"events" : [{"test" : "data"}]}
                    """.data(using: .utf8)! // swiftlint:disable:this force_unwrapping

        let expectedPayload = try! JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
        let edgeHit = ExperienceEventsEdgeHit(edgeEndpoint: .production, configId: CONFIG_ID, request: EdgeRequest(meta: nil, xdm: nil, events: [["test": "data"]]))

        XCTAssertTrue(expectedPayload == payloadToDict(payload: edgeHit.getPayload()))
    }

    func testExperienceEventsEdgeHit_getPayload_withStreaming() {
        let json = """
                {"meta" :
                    {"konductorConfig" :
                        {"streaming" :
                            {"enabled" : true,"recordSeparator" : "A","lineFeed" : "B"}
                        }
                    },
                "events" : [{  "test" : "data"}]}
                """.data(using: .utf8)! // swiftlint:disable:this force_unwrapping
        let expectedPayload = try! JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
        let streamingSettings = Streaming(recordSeparator: "A", lineFeed: "B")
        let edgeHit = ExperienceEventsEdgeHit(edgeEndpoint: .production,
                                              configId: CONFIG_ID,
                                              request: EdgeRequest(meta: RequestMetadata(konductorConfig: KonductorConfig(streaming: streamingSettings), state: nil), xdm: nil, events: [["test": "data"]]))

        XCTAssertTrue(expectedPayload == payloadToDict(payload: edgeHit.getPayload()))
    }

    func testExperienceEventsEdgeHit_getType() {
        let edgeHit = ExperienceEventsEdgeHit(edgeEndpoint: .production, configId: CONFIG_ID, request: EDGE_REQUEST)
        XCTAssertEqual(ExperienceEdgeRequestType.interact, edgeHit.getType())
    }

    // MARK: ConsentEgeHit tests

    func testConsentEdgeHit_getPayload() {
        let json =
            """
            {"consent" :
                [{
                    "standard" : "Adobe",
                    "version" : "2.0",
                    "value" : {
                        "consent" : {
                            "collect" : "y"
                        }
                    }}
                ]
            }
            """.data(using: .utf8)! // swiftlint:disable:this force_unwrapping
        let expectedPayload = try! JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
        let edgeHit = ConsentEdgeHit(edgeEndpoint: .production, configId: CONFIG_ID, consents: CONSENT_UPDATE_REQUEST)

        XCTAssertTrue(expectedPayload == payloadToDict(payload: edgeHit.getPayload()))
    }

    func testConsentEdgeHit_getPayloadWithStreaming() {
        let json =
            """
            {"meta" :
                    {"konductorConfig" :
                        {"streaming" :
                            {"enabled" : true,"recordSeparator" : "A","lineFeed" : "B"}
                        }
                    },
            "consent" :
                [{
                    "standard" : "Adobe",
                    "version" : "2.0",
                    "value" : {
                        "consent" : {
                            "collect" : "y"
                        }
                    }}
                ]
            }
            """.data(using: .utf8)! // swiftlint:disable:this force_unwrapping
        let expectedPayload = try! JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
        let streamingSettings = Streaming(recordSeparator: "A", lineFeed: "B")
        let consentUpdate = EdgeConsentUpdate(meta: RequestMetadata(konductorConfig: KonductorConfig(streaming: streamingSettings), state: nil),
                                              identityMap: nil,
                                              consent: [EdgeConsentPayload(standard: "Adobe", version: "2.0", value: ["consent": ["collect": "y"]])])
        let edgeHit = ConsentEdgeHit(edgeEndpoint: .production, configId: CONFIG_ID, consents: consentUpdate)

        XCTAssertTrue(expectedPayload == payloadToDict(payload: edgeHit.getPayload()))
    }

    func testConsentEdgeHit_getType() {
        let edgeHit = ConsentEdgeHit(edgeEndpoint: .production, configId: CONFIG_ID, consents: CONSENT_UPDATE_REQUEST)
        XCTAssertEqual(ExperienceEdgeRequestType.consent, edgeHit.getType())
    }

    func testConsentEdgeHit_getStreamingSettings_streamingNotEnabled() {
        let edgeHit = ConsentEdgeHit(edgeEndpoint: .production, configId: CONFIG_ID, consents: CONSENT_UPDATE_REQUEST)
        XCTAssertNil(edgeHit.getStreamingSettings())
    }

    func testConsentEdgeHit_getStreamingSettings_streamingEnabled() {
        let streamingSettings = Streaming(recordSeparator: "A", lineFeed: "B")
        let consentUpdate = EdgeConsentUpdate(meta: RequestMetadata(konductorConfig: KonductorConfig(streaming: streamingSettings), state: nil),
                                              identityMap: nil,
                                              consent: [EdgeConsentPayload(standard: "Adobe", version: "2.0", value: ["consent": ["collect": "y"]])])
        let edgeHit = ConsentEdgeHit(edgeEndpoint: .production, configId: CONFIG_ID, consents: consentUpdate)
        XCTAssertNotNil(edgeHit.getStreamingSettings())
    }

    private func payloadToDict(payload: String?) -> [String: Any] {
        guard let payloadData = payload?.data(using: .utf8),
              let payload = try! JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] else {
            XCTFail("Failed to convert payload to data")
            return [:]
        }

        return payload
    }
}

func == (lhs: [String: Any], rhs: [String: Any]) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

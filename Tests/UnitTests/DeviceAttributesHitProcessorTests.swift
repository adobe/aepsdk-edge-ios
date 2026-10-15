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

@testable import AEPCore
@testable import AEPEdge
import AEPServices
import AEPTestUtils
import XCTest

class DeviceAttributesHitProcessorTests: XCTestCase, AnyCodableAsserts {
    /// Records requests and replies synchronously with the queued responses (the last one repeats).
    private final class StubNetworking: Networking {
        var responses: [HttpConnection] = []
        private(set) var requests: [NetworkRequest] = []

        func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {
            requests.append(networkRequest)
            let response = responses.count > 1 ? responses.removeFirst() : responses.first
            completionHandler?(response ?? HttpConnection(data: nil, response: nil, error: nil))
        }
    }

    private let testStoreName = "DeviceAttributesHitProcessorTests"
    private let defaultConfig: [String: Any] = ["edge.configId": "test-config-id"]
    private let defaultIdentityMap: [String: Any] = ["identityMap": ["ECID": [["id": "test-ecid", "authenticatedState": "ambiguous", "primary": false]]]]
    private let defaultEventData: [String: Any] = ["timezone": "Europe/London", "tokens": ["pushNotification": "token"]]
    private let successBody = #"""
    {
      "requestId": "server-request-id",
      "handle": [
        { "type": "locationHint:result", "payload": [
            { "scope": "Target", "hint": "35", "ttlSeconds": 1800 },
            { "scope": "EdgeNetwork", "hint": "or2", "ttlSeconds": 1800 }
        ] },
        { "type": "state:store", "payload": [ { "key": "kndctr_cookie", "value": "cookie-value", "maxAge": 1800 } ] },
        { "type": "personalization:decisions", "payload": [ { "id": "ignored" } ] }
      ]
    }
    """#

    private var stubNetworking: StubNetworking!
    private var dispatchedEvents: [Event] = []
    private var locationHintUpdates: [(hint: String, ttl: TimeInterval)] = []
    private var currentLocationHint: String?
    private var implementationDetails: [String: Any]? = ["name": "https://ns.adobe.com/experience/mobilesdk/ios", "environment": "app", "version": "5.0.0"]
    private var assuranceIntegrationId: String?
    private var processor: DeviceAttributesHitProcessor!

    override func setUp() {
        ServiceProvider.shared.namedKeyValueService = MockDataStore()
        stubNetworking = StubNetworking()
        ServiceProvider.shared.networkService = stubNetworking
        dispatchedEvents = []
        locationHintUpdates = []
        currentLocationHint = nil
        assuranceIntegrationId = nil
        processor = makeProcessor()
    }

    // MARK: Response classification

    func testProcessHit_200_dispatchesSuccessAndRemovesHit() throws {
        stubNetworking.responses = [response(200, body: successBody)]
        let (event, entity) = makeEntity()

        XCTAssertTrue(process(entity))

        try assertSingleResult(for: event, status: "success", reason: nil, httpStatus: 200)
    }

    func testProcessHit_202_dispatchesSuccess() throws {
        stubNetworking.responses = [response(202, body: nil)]
        let (event, entity) = makeEntity()

        XCTAssertTrue(process(entity))

        try assertSingleResult(for: event, status: "success", reason: nil, httpStatus: 202)
    }

    func testProcessHit_unsupportedOrUnrecoverableCodes_dispatchFailedNetwork() throws {
        for code in [204, 207, 400, 401, 403, 404, 500] {
            setUp()
            stubNetworking.responses = [response(code, body: nil)]
            let (event, entity) = makeEntity()

            XCTAssertTrue(process(entity), "code \(code)")

            try assertSingleResult(for: event, status: "failed", reason: "network", httpStatus: code)
        }
    }

    func testProcessHit_400ProblemJson_dispatchesFailedNetwork() throws {
        let problem = #"""
        {"type": "https://ns.adobe.com/aep/errors/EXEG-0003-400", "status": 400, "title": "Invalid request",
         "report": {"requestId": "id", "errors": ["Missing timezone"]}}
        """#
        stubNetworking.responses = [response(400, body: problem)]
        let (event, entity) = makeEntity()

        XCTAssertTrue(process(entity))

        try assertSingleResult(for: event, status: "failed", reason: "network", httpStatus: 400)
        XCTAssertTrue(locationHintUpdates.isEmpty)
    }

    func testProcessHit_recoverableCodes_retryWithoutResultEvent() {
        for code in [408, 429, 502, 503, 504, 507] {
            setUp()
            stubNetworking.responses = [response(code, body: nil)]
            let (_, entity) = makeEntity()

            XCTAssertFalse(process(entity), "code \(code)")

            XCTAssertTrue(dispatchedEvents.isEmpty, "code \(code)")
            XCTAssertEqual(EdgeConstants.Defaults.RETRY_INTERVAL, processor.retryInterval(for: entity), "code \(code)")
        }
    }

    func testProcessHit_recoverableCodeWithRetryAfter_usesHeaderInterval() {
        stubNetworking.responses = [response(503, body: nil, headers: ["Retry-After": "30"])]
        let (_, entity) = makeEntity()

        XCTAssertFalse(process(entity))

        XCTAssertEqual(30, processor.retryInterval(for: entity))
    }

    func testProcessHit_recoverableUrlError_retriesWithoutResultEvent() {
        stubNetworking.responses = [HttpConnection(data: nil, response: nil, error: URLError(.notConnectedToInternet))]
        let (_, entity) = makeEntity()

        XCTAssertFalse(process(entity))

        XCTAssertTrue(dispatchedEvents.isEmpty)
        XCTAssertEqual(EdgeConstants.Defaults.RETRY_INTERVAL, processor.retryInterval(for: entity))
    }

    func testProcessHit_unrecoverableError_dispatchesFailedWithoutHttpStatus() throws {
        stubNetworking.responses = [HttpConnection(data: nil, response: nil, error: URLError(.badURL))]
        let (event, entity) = makeEntity()

        XCTAssertTrue(process(entity))

        try assertSingleResult(for: event, status: "failed", reason: "network", httpStatus: nil)
    }

    func testProcessHit_noResponse_dispatchesFailedWithoutHttpStatus() throws {
        stubNetworking.responses = [HttpConnection(data: nil, response: nil, error: nil)]
        let (event, entity) = makeEntity()

        XCTAssertTrue(process(entity))

        try assertSingleResult(for: event, status: "failed", reason: "network", httpStatus: nil)
    }

    func testProcessHit_retryThenSuccess_dispatchesExactlyOneResult() throws {
        stubNetworking.responses = [response(503, body: nil), response(503, body: nil), response(200, body: successBody)]
        let (event, entity) = makeEntity()

        XCTAssertFalse(process(entity))
        XCTAssertFalse(process(entity))
        XCTAssertTrue(process(entity))

        XCTAssertEqual(3, stubNetworking.requests.count)
        try assertSingleResult(for: event, status: "success", reason: nil, httpStatus: 200)
        XCTAssertEqual(EdgeConstants.Defaults.RETRY_INTERVAL, processor.retryInterval(for: entity))
    }

    // MARK: Request

    func testProcessHit_sendsFlatBodyToDeviceAttributesEndpoint() throws {
        assuranceIntegrationId = "assurance-id"
        stubNetworking.responses = [response(200, body: nil)]
        let (_, entity) = makeEntity()

        XCTAssertTrue(process(entity))

        let request = try XCTUnwrap(stubNetworking.requests.first)
        XCTAssertEqual(.post, request.httpMethod)
        let components = try XCTUnwrap(URLComponents(url: request.url, resolvingAgainstBaseURL: false))
        XCTAssertEqual("edge.adobedc.net", components.host)
        XCTAssertEqual("/ee/v1/mobile/device-attributes", components.path)
        XCTAssertEqual("test-config-id", components.queryItems?.first { $0.name == "configId" }?.value)
        XCTAssertFalse((components.queryItems?.first { $0.name == "requestId" }?.value ?? "").isEmpty)
        XCTAssertEqual("assurance-id", request.httpHeaders["X-Adobe-AEP-Validation-Token"])
        XCTAssertEqual("application/json", request.httpHeaders["Content-Type"])

        let body = try XCTUnwrap(String(data: request.connectPayload, encoding: .utf8))
        let expectedJSON = #"""
        {
          "timezone": "Europe/London",
          "tokens": { "pushNotification": "token" },
          "xdm": {
            "implementationDetails": { "name": "https://ns.adobe.com/experience/mobilesdk/ios", "environment": "app", "version": "5.0.0" },
            "identityMap": { "ECID": [ { "id": "test-ecid", "authenticatedState": "ambiguous", "primary": false } ] }
          }
        }
        """#
        assertExactMatch(expected: expectedJSON, actual: body)
        XCTAssertFalse(body.contains("\n"))
    }

    func testProcessHit_usesLocationHintEnvironmentAndCustomDomain() throws {
        currentLocationHint = "va6"
        stubNetworking.responses = [response(200, body: nil)]
        let (_, entity) = makeEntity(config: ["edge.configId": "test-config-id", "edge.environment": "pre-prod", "edge.domain": "custom.example.com"])

        XCTAssertTrue(process(entity))

        let request = try XCTUnwrap(stubNetworking.requests.first)
        XCTAssertEqual("custom.example.com", request.url.host)
        XCTAssertEqual("/ee-pre-prd/va6/v1/mobile/device-attributes", request.url.path)
    }

    func testProcessHit_doesNotSendAssuranceHeaderWhenUnavailable() throws {
        stubNetworking.responses = [response(200, body: nil)]
        let (_, entity) = makeEntity()

        XCTAssertTrue(process(entity))

        XCTAssertNil(try XCTUnwrap(stubNetworking.requests.first).httpHeaders["X-Adobe-AEP-Validation-Token"])
    }

    // MARK: Response handles

    func testProcessHit_success_appliesLocationHintAndStoreHandlesOnly() throws {
        stubNetworking.responses = [response(200, body: successBody)]
        let (event, entity) = makeEntity()

        XCTAssertTrue(process(entity))

        XCTAssertEqual(1, locationHintUpdates.count)
        XCTAssertEqual("or2", locationHintUpdates.first?.hint)
        XCTAssertEqual(1800, locationHintUpdates.first?.ttl)
        let stored = StoreResponsePayloadManager(testStoreName).getActivePayloadList()
        XCTAssertEqual(1, stored.count)
        XCTAssertEqual("kndctr_cookie", stored.first?.key)
        XCTAssertEqual("cookie-value", stored.first?.value)
        // Only the result event is dispatched (no Edge response, error or complete events)
        try assertSingleResult(for: event, status: "success", reason: nil, httpStatus: 200)
    }

    func testProcessHit_successWithMalformedOrEmptyBody_stillSucceeds() throws {
        for body in ["", "not json", "{}", #"{"handle": "invalid"}"#, #"{"handle": [{"type": "locationHint:result", "payload": [{"scope": "EdgeNetwork", "hint": ""}]}]}"#] {
            setUp()
            stubNetworking.responses = [response(200, body: body)]
            let (event, entity) = makeEntity()

            XCTAssertTrue(process(entity))

            XCTAssertTrue(locationHintUpdates.isEmpty, body)
            XCTAssertTrue(StoreResponsePayloadManager(testStoreName).getActivePayloadList().isEmpty, body)
            try assertSingleResult(for: event, status: "success", reason: nil, httpStatus: 200)
        }
    }

    func testProcessHit_failure_doesNotApplyResponseHandles() {
        stubNetworking.responses = [response(400, body: successBody)]
        let (_, entity) = makeEntity()

        XCTAssertTrue(process(entity))

        XCTAssertTrue(locationHintUpdates.isEmpty)
        XCTAssertTrue(StoreResponsePayloadManager(testStoreName).getActivePayloadList().isEmpty)
    }

    // MARK: Identities reset

    func testProcessHit_queuedBeforeReset_isDiscardedWithoutRequestOrResult() {
        let (_, entity) = makeEntity(timestamp: Date(timeIntervalSinceNow: -60))
        setResetDate(Date())

        XCTAssertTrue(process(entity))

        XCTAssertTrue(stubNetworking.requests.isEmpty)
        XCTAssertTrue(dispatchedEvents.isEmpty)
    }

    func testProcessHit_queuedAfterReset_isSent() throws {
        setResetDate(Date(timeIntervalSinceNow: -60))
        stubNetworking.responses = [response(200, body: nil)]
        let (event, entity) = makeEntity()

        XCTAssertTrue(process(entity))

        XCTAssertEqual(1, stubNetworking.requests.count)
        try assertSingleResult(for: event, status: "success", reason: nil, httpStatus: 200)
    }

    func testProcessHit_resetWhileWaitingForRetry_isDiscardedOnNextAttempt() {
        stubNetworking.responses = [response(503, body: nil)]
        let (_, entity) = makeEntity(timestamp: Date(timeIntervalSinceNow: -60))

        XCTAssertFalse(process(entity))
        setResetDate(Date())
        XCTAssertTrue(process(entity))

        XCTAssertEqual(1, stubNetworking.requests.count)
        XCTAssertTrue(dispatchedEvents.isEmpty)
    }

    func testProcessHit_resetWhileInFlight_dispatchesResultButIgnoresStoreHandles() throws {
        let (event, entity) = makeEntity(timestamp: Date(timeIntervalSinceNow: -60))
        let networking = ResetDuringRequestNetworking(response: response(200, body: successBody)) { [weak self] in
            self?.setResetDate(Date())
        }
        ServiceProvider.shared.networkService = networking

        XCTAssertTrue(process(entity))

        XCTAssertTrue(StoreResponsePayloadManager(testStoreName).getActivePayloadList().isEmpty)
        XCTAssertEqual(1, locationHintUpdates.count)
        try assertSingleResult(for: event, status: "success", reason: nil, httpStatus: 200)
    }

    // MARK: Drops

    func testProcessHit_missingDatastreamId_dispatchesDroppedMissingConfig() throws {
        for config in [[:], ["edge.configId": ""]] as [[String: Any]] {
            setUp()
            let (event, entity) = makeEntity(config: config)

            XCTAssertTrue(process(entity))

            XCTAssertTrue(stubNetworking.requests.isEmpty)
            try assertSingleResult(for: event, status: "dropped", reason: "missingConfig", httpStatus: nil)
        }
    }

    func testProcessHit_emptyPayload_dispatchesDroppedInvalidPayload() throws {
        implementationDetails = nil
        processor = makeProcessor()
        let (event, entity) = makeEntity(eventData: ["xdm": ["producer": "value"]], identityMap: [:])

        XCTAssertTrue(process(entity))

        XCTAssertTrue(stubNetworking.requests.isEmpty)
        try assertSingleResult(for: event, status: "dropped", reason: "invalidPayload", httpStatus: nil)
    }

    func testProcessHit_undecodableEntity_dispatchesUnchainedDrop() throws {
        for data in [nil, Data("{".utf8), Data("{}".utf8)] {
            setUp()
            let entity = DataEntity(uniqueIdentifier: "stored-request-id", timestamp: Date(), data: data)

            XCTAssertTrue(process(entity))

            XCTAssertTrue(stubNetworking.requests.isEmpty)
            XCTAssertEqual(1, dispatchedEvents.count)
            let result = try XCTUnwrap(dispatchedEvents.first)
            XCTAssertNil(result.parentID)
            XCTAssertEqual("Device Attributes Response", result.name)
            XCTAssertEqual(EdgeConstants.EventType.EDGE_BYPASS_CONSENT, result.type)
            XCTAssertEqual(EventSource.responseContent, result.source)
            XCTAssertEqual(["status": "dropped", "reason": "invalidPayload", "requestEventId": "stored-request-id"] as NSDictionary,
                           result.data as NSDictionary?)
        }
    }

    // MARK: Helpers

    /// Persists the identities reset date while the request is in flight.
    private final class ResetDuringRequestNetworking: Networking {
        let response: HttpConnection
        let onRequest: () -> Void
        init(response: HttpConnection, onRequest: @escaping () -> Void) {
            self.response = response
            self.onRequest = onRequest
        }
        func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {
            onRequest()
            completionHandler?(response)
        }
    }

    private func makeProcessor() -> DeviceAttributesHitProcessor {
        return DeviceAttributesHitProcessor(
            sharedStateReader: SharedStateReader(getSharedState: { [weak self] name, _, _ in
                guard name == EdgeConstants.SharedState.Assurance.STATE_OWNER_NAME, let id = self?.assuranceIntegrationId else { return nil }
                return SharedStateResult(status: .set, value: ["integrationid": id])
            }),
            getImplementationDetails: { [weak self] in self?.implementationDetails },
            getLocationHint: { [weak self] in self?.currentLocationHint },
            updateLocationHint: { [weak self] hint, ttl in self?.locationHintUpdates.append((hint, ttl)) },
            dispatch: { [weak self] event in self?.dispatchedEvents.append(event) },
            storeDataStoreName: testStoreName)
    }

    private func makeEntity(eventData: [String: Any]? = nil,
                            config: [String: Any]? = nil,
                            identityMap: [String: Any]? = nil,
                            timestamp: Date = Date()) -> (Event, DataEntity) {
        let event = Event(name: "Device Attributes Request",
                          type: EdgeConstants.EventType.EDGE_BYPASS_CONSENT,
                          source: EventSource.requestContent,
                          data: eventData ?? defaultEventData)
        let edgeEntity = EdgeDataEntity(event: event,
                                        configuration: AnyCodable.from(dictionary: config ?? defaultConfig) ?? [:],
                                        identityMap: AnyCodable.from(dictionary: identityMap ?? defaultIdentityMap) ?? [:])
        let data = try? JSONEncoder().encode(edgeEntity)
        return (event, DataEntity(uniqueIdentifier: event.id.uuidString, timestamp: timestamp, data: data))
    }

    private func process(_ entity: DataEntity) -> Bool {
        var result: Bool?
        processor.processHit(entity: entity) { result = $0 }
        XCTAssertNotNil(result, "processHit should complete synchronously with the stub network service")
        return result ?? false
    }

    private func response(_ code: Int, body: String?, headers: [String: String]? = nil) -> HttpConnection {
        let url = URL(string: "https://edge.adobedc.net/ee/v1/mobile/device-attributes")!
        return HttpConnection(data: body?.data(using: .utf8),
                              response: HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: headers),
                              error: nil)
    }

    private func setResetDate(_ date: Date) {
        NamedCollectionDataStore(name: EdgeConstants.EXTENSION_NAME)
            .set(key: EdgeConstants.DataStoreKeys.RESET_IDENTITIES_DATE, value: date.timeIntervalSince1970)
    }

    private func assertSingleResult(for request: Event, status: String, reason: String?, httpStatus: Int?,
                                    file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertEqual(1, dispatchedEvents.count, file: file, line: line)
        let result = try XCTUnwrap(dispatchedEvents.first, file: file, line: line)
        XCTAssertEqual("Device Attributes Response", result.name, file: file, line: line)
        XCTAssertEqual(EdgeConstants.EventType.EDGE_BYPASS_CONSENT, result.type, file: file, line: line)
        XCTAssertEqual(EventSource.responseContent, result.source, file: file, line: line)
        XCTAssertEqual(request.id, result.parentID, file: file, line: line)
        var expected: [String: Any] = ["status": status]
        if let reason = reason { expected["reason"] = reason }
        if let httpStatus = httpStatus { expected["httpStatus"] = httpStatus }
        XCTAssertEqual(expected as NSDictionary, result.data as NSDictionary?, file: file, line: line)
    }
}

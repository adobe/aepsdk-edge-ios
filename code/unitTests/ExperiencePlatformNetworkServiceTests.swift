//
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import XCTest

@testable import ACPExperiencePlatform

class ExperiencePlatformNetworkServiceTests: XCTestCase {
    
    private var mockNetworkService = MockNetworkServiceOverrider()
    private var mockResponseCallback = MockResponseCallback()
    private var networkService = ExperiencePlatformNetworkService()
    
    public override func setUp() {
        self.mockResponseCallback = MockResponseCallback()
        self.mockNetworkService = MockNetworkServiceOverrider()
        AEPServiceProvider.shared.networkService = mockNetworkService
        networkService = ExperiencePlatformNetworkService()
    }
    
    func testStrings() {
        let testStr : String = "\u{00A9}{\"some\":\"thing\\n\"}\u{00F8}" +
        "\u{00A9}{" +
        "  \"may\": {" +
        "    \"include\": \"nested\"," +
        "    \"objects\": [" +
        "      \"and\"," +
        "      \"arrays\"" +
        "    ]" +
        "  }" +
        "}\u{00F8}";
        let requestConfigRecordSeparator: Character = "\u{00A9}"
        let requestConfigLineFeed: Character = "\u{00F8}"
        // todo
        
    }
    
    func testDoRequest_whenRequestHeadersAreEmpty_setsDefaultHeaders() {

        // setup
        var jsonBody: Data = "{}".data(using: .utf8)!
        var url: URL = URL(string: "https://test.com")!
        var mockResponseCallback = MockResponseCallback()

        // test
        let networkService = ExperiencePlatformNetworkService()
        let retryResult = networkService.doRequest(url:url, jsonBody:jsonBody, requestHeaders: [:], responseCallback: mockResponseCallback, retryTimes: 0)

        // verify
        // TODO: update network service and add assertions
    }
    
    func testDoRequest_whenRequestHeadersExist_RequestHeadersAppendedOnNetworkCall() {
        
    }
    
    func testDoRequest_whenConnection_ResponseCode200_ReturnsRetryNo_AndCallsResponseCallback_AndNoErrorCallback() {
        
    }
    
    func testDoRequest_whenConnection_ResponseCode204_ReturnsRetryNo_AndNoResponseCallback_AndNoErrorCallback() {
        
    }
    
    func testHandleStreamingResponse_nilSeparators_doesNotCrash() {
        let responseStr:String = ""
        
        let streamingSettings = Streaming(recordSeparator: nil, lineFeed: nil)
        let connection:HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)
        
        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }
    
    func testHandleStreamingResponse_EmptyResponse() {
        let responseStr:String = "{}"
        
        let streamingSettings = Streaming(recordSeparator: "", lineFeed: "\n")
        let connection:HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)
        
        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }
    
    func testHandleStreamingResponse_nonCharacterSeparators_doesNotHandleContent() {
        let responseStr:String =
            "<RS>{\"some\":\"thing\\n\"}<LF>" +
            "<RS>{\n" +
            "  \"may\": {\n" +
            "    \"include\": \"nested\",\n" +
            "    \"objects\": [\n" +
            "      \"and\",\n" +
            "      \"arrays\"\n" +
            "    ]\n" +
            "  }\n" +
            "}<LF>"
        
        let streamingSettings = Streaming(recordSeparator: "<RS>", lineFeed: "<LF>")
        let connection:HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)
        
        XCTAssertFalse(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([], mockResponseCallback.onResponseJsonResponse)
    }
    
    func testHandleStreamingResponse_SimpleStreamingResponse2() {
        let responseStr:String =
            "\u{00A9}{\"some\":\"thing\\n\"}\u{00F8}" +
            "\u{00A9}{\n" +
            "  \"may\": {\n" +
            "    \"include\": \"nested\",\n" +
            "    \"objects\": [\n" +
            "      \"and\",\n" +
            "      \"arrays\"\n" +
            "    ]\n" +
            "  }\n" +
            "}\u{00F8}"
        var expectedResponse:[String] = []
        expectedResponse.append("{\"some\":\"thing\\n\"}")
        expectedResponse.append("{\n" +
            "  \"may\": {\n" +
            "    \"include\": \"nested\",\n" +
            "    \"objects\": [\n" +
            "      \"and\",\n" +
            "      \"arrays\"\n" +
            "    ]\n" +
            "  }\n" +
            "}")
        let streamingSettings = Streaming(recordSeparator: "\u{00A9}", lineFeed: "\u{00F8}")
        let connection:HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)
        
        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual(expectedResponse, mockResponseCallback.onResponseJsonResponse)
    }
    
    func testHandleStreamingResponse_SimpleStreamingResponse3() {
        let responseStr:String =
            "\u{00A9}{\"some\":\"thing\\n\"}\u{00FF}" +
            "\u{00A9}{\n" +
            "  \"may\": {\n" +
            "    \"include\": \"nested\",\n" +
            "    \"objects\": [\n" +
            "      \"and\",\n" +
            "      \"arrays\"\n" +
            "    ]\n" +
            "  }\n" +
            "}\u{00FF}"
        var expectedResponse:[String] = []
        expectedResponse.append("{\"some\":\"thing\\n\"}")
        expectedResponse.append("{\n" +
            "  \"may\": {\n" +
            "    \"include\": \"nested\",\n" +
            "    \"objects\": [\n" +
            "      \"and\",\n" +
            "      \"arrays\"\n" +
            "    ]\n" +
            "  }\n" +
            "}")
        let streamingSettings = Streaming(recordSeparator: "\u{00A9}", lineFeed: "\u{00FF}")
        let connection:HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)
        
        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual(expectedResponse, mockResponseCallback.onResponseJsonResponse)
    }
    
    func testHandleStreamingResponse_SingleStreamingResponse() {
        let responseStr:String = "\u{0000}{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}\n"
        let expectedResponse:String =
        "{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}"
        let streamingSettings = Streaming(recordSeparator: "\u{0000}", lineFeed: "\n")
        let connection:HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)
        
        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([expectedResponse], mockResponseCallback.onResponseJsonResponse)
    }
    
    func testHandleStreamingResponse_TwoStreamingResponses() {
        var responseStr:String = "\u{0000}{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}\n"
        responseStr += responseStr
        let expectedResponse:String =
        "{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}"
        let streamingSettings = Streaming(recordSeparator: "\u{0000}", lineFeed: "\n")
        let connection:HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)
        
        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([expectedResponse, expectedResponse], mockResponseCallback.onResponseJsonResponse)

    }
    
    func testHandleStreamingResponse_ManyStreamingResponses() {
        let responseStr:String = "\u{0000}{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}\n"
        let expectedResponse:String =
        "{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}"
        let streamingSettings = Streaming(recordSeparator: "\u{0000}", lineFeed: "\n")
        let connection:HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: streamingSettings, responseCallback: mockResponseCallback)
        
        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([expectedResponse], mockResponseCallback.onResponseJsonResponse)
    }
    
    func testHandleNonStreamingResponse_WhenValidJson_ShouldReturnEntireResponse() {
        let responseStr:String = "{\"some\":\"thing\"}," +
                                    "{" +
                                    "  \"may\": {" +
                                    "    \"include\": \"nested\"," +
                                    "    \"objects\": [" +
                                    "      \"and\"," +
                                    "      \"arrays\"" +
                                    "    ]" +
                                    "  }" +
                                    "}"
        let connection:HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: nil, responseCallback: mockResponseCallback)
        
        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }
    
    func testHandleNonStreamingResponse_WhenValidJsonWithNewLine_ShouldReturnResponse() {
        let responseStr:String =  "{\"some\":\"thing\"},\n" +
                                    "{" +
                                    "  \"may\": {" +
                                    "    \"include\": \"nested\"," +
                                    "    \"objects\": [" +
                                    "      \"and\"," +
                                    "      \"arrays\"" +
                                    "    ]" +
                                    "  }" +
                                    "}\n"
        let connection:HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: nil, responseCallback: mockResponseCallback)
        
        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }
    
    func testHandleNonStreamingResponse_WhenOneJsonObject_ShouldReturnEntireResponse() {
        let responseStr:String = "{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}"
        let connection:HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: nil, responseCallback: mockResponseCallback)
        
        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }
    
    func testHandleNonStreamingResponse_WhenTwoJsonObjects_ShouldReturnEntireResponse() {
        let responseStr:String = "{\"requestId\":\"ded17427-c993-4182-8d94-2a169c1a23e2\",\"handle\":[{\"type\":\"identity:exchange\",\"payload\":[{\"type\":\"url\",\"id\":411,\"spec\":{\"url\":\"//cm.everesttech.net/cm/dd?d_uuid=42985602780892980519057012517360930936\",\"hideReferrer\":false,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":358,\"spec\":{\"url\":\"//ib.adnxs.com/getuid?https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D358%26dpuuid%3D%24UID\",\"hideReferrer\":true,\"ttlMinutes\":10080}},{\"type\":\"url\",\"id\":477,\"spec\":{\"url\":\"//idsync.rlcdn.com/365868.gif?partner_uid=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":14400}},{\"type\":\"url\",\"id\":540,\"spec\":{\"url\":\"//pixel.tapad.com/idsync/ex/receive?partner_id=ADB&partner_url=https%3A%2F%2Fdpm.demdex.net%2Fibs%3Adpid%3D540%26dpuuid%3D%24%7BTA_DEVICE_ID%7D&partner_device_id=42985602780892980519057012517360930936\",\"hideReferrer\":true,\"ttlMinutes\":1440}},{\"type\":\"url\",\"id\":771,\"spec\":{\"url\":\"https://cm.g.doubleclick.net/pixel?google_nid=adobe_dmp&google_cm&gdpr=0&gdpr_consent=\",\"hideReferrer\":true,\"ttlMinutes\":20160}},{\"type\":\"url\",\"id\":1123,\"spec\":{\"url\":\"//analytics.twitter.com/i/adsct?p_user_id=42985602780892980519057012517360930936&p_id=38594\",\"hideReferrer\":true,\"ttlMinutes\":10080}}]}]}"
        let connection:HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: nil, responseCallback: mockResponseCallback)
        
        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }
    
    func testHandleNonStreamingResponse_WhenResponseIsEmptyObject_ShouldReturnEmptyObject() {
        let responseStr:String = "{}"
        let connection:HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: nil, responseCallback: mockResponseCallback)
        
        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }
    
    func testHandleNonStreamingResponse_WhenResponseIsEmptyString_ShouldReturnEmptyString() {
        let responseStr:String = ""
        let connection:HttpConnection = HttpConnection(data: responseStr.data(using: .utf8)!, response: nil, error: nil)
        networkService.handleContent(connection: connection, streaming: nil, responseCallback: mockResponseCallback)
        
        XCTAssertTrue(mockResponseCallback.onResponseCalled)
        XCTAssertFalse(mockResponseCallback.onErrorCalled)
        XCTAssertFalse(mockResponseCallback.onCompleteCalled)
        XCTAssertEqual([responseStr], mockResponseCallback.onResponseJsonResponse)
    }
}
  

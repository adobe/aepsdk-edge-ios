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

import AEPCore
import AEPEdge
import AEPEdgeIdentity
import AEPServices
import Foundation
import XCTest

/// This Test class is an example of usages of the FunctionalTestBase APIs
class SampleFunctionalTests: FunctionalTestBase {
    private let event1 = Event(name: "e1", type: "eventType", source: "eventSource", data: ["key1":"value1"])
//    private let xdmEvent = Event(name: <#T##String#>, type: <#T##String#>, source: <#T##String#>, data: <#T##[String : Any]?#>)
    private let event2 = Event(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private let exEdgeInteractUrlString = "https://edge.adobedc.net/ee/v1/interact"
    private let exEdgeInteractUrl = URL(string: "https://edge.adobedc.net/ee/v1/interact")! // swiftlint:disable:this force_unwrapping
    private let responseBody = "{\"test\": \"json\"}"
    
    let LOG_SOURCE = "SampleFunctionalTests"
    
    let asyncTimeout: TimeInterval = 10

    public class override func setUp() {
        super.setUp()
        FunctionalTestBase.debugEnabled = true
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        // hub shared state update for extension versions (InstrumentedExtension (registered in FunctionalTestBase), IdentityEdge, Edge), Edge extension, IdentityEdge XDM shared state and Config shared state updates
//        setExpectationEvent(type: FunctionalTestConst.EventType.HUB, source: FunctionalTestConst.EventSource.SHARED_STATE, expectedCount: 4)
//
//        // expectations for update config request&response events
//        setExpectationEvent(type: FunctionalTestConst.EventType.CONFIGURATION, source: FunctionalTestConst.EventSource.REQUEST_CONTENT, expectedCount: 1)
//        setExpectationEvent(type: FunctionalTestConst.EventType.CONFIGURATION, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT, expectedCount: 1)

        // wait for async registration because the EventHub is already started in FunctionalTestBase
        let waitForRegistration = CountDownLatch(1)
        MobileCore.setLogLevel(.trace)
        MobileCore.configureWith(appId: "94f571f308d5/6b1be84da76a/launch-023a1b64f561-development")
        MobileCore.registerExtensions([Identity.self, Edge.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))
//        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])

//        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
    }
    
    func registerMessagingRequestContentListener(_ listener: @escaping EventListener) {
        MobileCore.registerEventListener(type: FunctionalTestConst.EventType.EDGE, source: "locationHint:result", listener: listener)
    }

    // MARK: sample tests for the FunctionalTest framework usage

    func testSample_AssertUnexpectedEvents() {
        // set event expectations specifying the event type, source and the count (count should be > 0)
//        setExpectationEvent(type: "eventType", source: "eventSource", expectedCount: 1)
//        MobileCore.dispatch(event: event1)
////        MobileCore.dispatch(event: event1)
//        sleep(2)
//        print("FunctionalTestBase.networkService.networkRequestResponseHandles: \(FunctionalTestBase.networkService.networkRequestResponseHandles)")
//        print("is dict empty: \(FunctionalTestBase.networkService.networkRequestResponseHandles.isEmpty)")

        // assert that no unexpected event was received
//        assertUnexpectedEvents()
        
        // setup
        let edgeRequestContentExpectation = XCTestExpectation(description: "Edge extension request content listener called")
        registerMessagingRequestContentListener() { event in
            XCTAssertNotNil(event)
            let data = event.data
            XCTAssertNotNil(data)
//            data["payload"]
            guard let payloadArray = data?["payload"] as? [[String:Any]] else {
                XCTFail()
                return
            }
            print()
            let targetHint = payloadArray[0]
            XCTAssertEqual("Target", targetHint["scope"] as? String)
            XCTAssertEqual(1800, targetHint["ttlSeconds"] as? Int)
            XCTAssertEqual("35", targetHint["hint"] as? String)
            
            
//            XCTAssertEqual(<#T##expression1: Equatable##Equatable#>, <#T##expression2: Equatable##Equatable#>)
            print("LISTENER: \(data)")
            Log.debug(label: self.LOG_SOURCE, "LISTENER: \(data)")
//            XCTAssertEqual(true, data?[MessagingConstants.Event.Data.Key.REFRESH_MESSAGES] as? Bool)
            edgeRequestContentExpectation.fulfill()
        }
        
        // test
//        MobileCore.dispatch(event: event1)
        
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        Edge.sendEvent(experienceEvent: experienceEvent, { (handles: [EdgeEventHandle]) in
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            guard let data = try? encoder.encode(handles) else {
//                self.dataContent = "failed to encode EdgeEventHandle"
                print("failed to encode EdgeEventHandle")
                return
            }
//            self.dataContent = String(data: data, encoding: .utf8) ?? "failed to encode JSON to string"
            let result = String(data: data, encoding: .utf8) ?? "failed to encode JSON to string"
//            print("HANDLE: \(result)")
            Log.debug(label: self.LOG_SOURCE, "HANDLE: \(result)")
            
        })
        
        // verify
        wait(for: [edgeRequestContentExpectation], timeout: asyncTimeout)
    }
}

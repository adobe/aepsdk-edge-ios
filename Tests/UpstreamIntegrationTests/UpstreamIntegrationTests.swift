//
// Copyright 2023 Adobe. All rights reserved.
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
import AEPEdge
import AEPEdgeIdentity
import AEPServices
import Foundation
import XCTest

class NetworkTestingDelegate: NetworkRequestDelegate {
    var testCaseCompletion: (HttpConnection) -> ()
    func handleNetworkResponse(httpConnection: AEPServices.HttpConnection) {
        print("Delegate received httpConnection: \(httpConnection)")
        testCaseCompletion(httpConnection)
    }
    init() {
        testCaseCompletion = { httpConnection in
            
        }
    }
}

/// This test class validates proper intergration with upstream services, specifically Edge Network
class UpstreamIntegrationTests: XCTestCase {
    private var edgeEnvironment: EdgeEnvironment = .prod
    private var edgeLocationHint: EdgeLocationHint? = nil
    
    private let testingDelegate = NetworkTestingDelegate()
    
    let LOG_SOURCE = "SampleFunctionalTests"
    
    let asyncTimeout: TimeInterval = 10

    override func setUp() {
        let networkService = FunctionalTestNetworkService()
        networkService.testingDelegate = testingDelegate
        ServiceProvider.shared.networkService = networkService
        
        // Extract Edge Network environment level from shell environment
        if let environment = EdgeEnvironment() {
            self.edgeEnvironment = environment
        }
        print("Using Edge Network environment: \(edgeEnvironment.rawValue)")
        // Extract Edge location hint from shell environment
        if let locationHint = EdgeLocationHint() {
            self.edgeLocationHint = locationHint
        }
        
        let waitForRegistration = CountDownLatch(1)
        MobileCore.setLogLevel(.trace)
        MobileCore.configureWith(appId: "94f571f308d5/6b1be84da76a/launch-023a1b64f561-development")
        MobileCore.registerExtensions([Identity.self, Edge.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))
        
        // Set Edge location hint value if one is set for the test
        if edgeLocationHint != nil {
            print("Setting Edge location hint to: \(String(describing: edgeLocationHint?.rawValue))")
            Edge.setLocationHint(edgeLocationHint?.rawValue)
        }
        else {
            print("No preset Edge location hint is being used for this test.")
        }
    }
    
    public override func tearDown() {
        super.tearDown()

        // to revisit when AMSDK-10169 is available
        // wait .2 seconds in case there are unexpected events that were in the dispatch process during cleanup
        usleep(200000)
        EventHub.reset()
        UserDefaults.clearAll()
        FileManager.default.clearCache()
    }
    
    // TODO: create specific listeners for type: Edge + source: * (wildcard) and capture all the response handles for the test event
    // TODO: create specific listeners for error responses
    func registerEdgeLocationHintListener(_ listener: @escaping EventListener) {
        MobileCore.registerEventListener(type: FunctionalTestConst.EventType.EDGE, source: "locationHint:result", listener: listener)
    }
    
    /// Loads JSON from static file in the same resource bundle as the test class and casts it into the provided type.
    ///
    /// NOTE: caller is reponsible for providing the correct casting type for ``JSONSerialization/jsonObject(with:options:)``, otherwise decoding will fail
    func loadJSONData<T>(fileName: String) -> T? {
        guard let pathString = Bundle(for: type(of: self)).path(forResource: fileName, ofType: "json") else {
            XCTFail("\(fileName).json not found")
            return nil
        }

        guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
            XCTFail("Unable to convert \(fileName).json to String")
            return nil
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Unable to convert \(fileName).json to Data")
            return nil
        }

        guard let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? T else {
            XCTFail("Unable to convert \(fileName).json to JSON dictionary")
            return nil
        }
        return jsonDictionary
    }

    // MARK: sample tests for the FunctionalTest framework usage
    func testSample_AssertUnexpectedEvents() {
        // Register a callback with the functional test network service to receive the HTTPConnection object when it's available
        
        // Setup
        let edgeRequestContentExpectation = XCTestExpectation(description: "Edge extension request content listener called")
        // Async testing methodology
        // test cases should fail quickly, if conditions are not met
        // all of a test case's conditions should be tried before the lock condition on a case is released
        // there are 2 main areas to test:
            // 1. the HTTP code, metadata values, and data types/related validation
            // 2. the logical content (is the event response what we expect for this type of event sent?
        
        /// HttpConnection has object `response.URL` which has value: https://obumobile5.data.adobedc.net/ee/v1/interact?configId=d936b4a4-8f13-4d8d-aabc-fcd1874b1ee5&requestId=159AEE9A-45B6-469E-B6FA-FBE506DA2E34
        /// This is the same as the one set in the edge configuration?
        /// only need to validate against this one
        // MARK: Network response assertions
        testingDelegate.testCaseCompletion = { httpConnection in
            print("SOURCE: testCaseCompletion: \(httpConnection)")
            print("data as string: \(httpConnection.responseString)")
            
            httpConnection.response?.url
            print("baseURL: \(httpConnection.response?.url?.host)")
            if httpConnection.response?.url?.host == "obumobile5.data.adobedc.net" {
                XCTAssertEqual(200, httpConnection.responseCode)
            }
        }
        
        // MARK: Response Event assertions
        registerEdgeLocationHintListener() { event in
            XCTAssertNotNil(event)
            let data = event.data
            XCTAssertNotNil(data)
            guard let payloadArray = data?["payload"] as? [[String:Any]] else {
                XCTFail()
                return
            }
            print()
            let targetHint = payloadArray[0]
            guard let locationHintCorrectValue: [String:Any] = self.loadJSONData(fileName: "locationHint"), let locationHintPayload = locationHintCorrectValue["payload"] as? [[String:Any]] else {
                XCTFail()
                return
            }
            
            // TODO: JSON dictionary compare
//            XCTAssertEqual(locationHintPayload, payloadArray)
            XCTAssertEqual("Target", targetHint["scope"] as? String)
            XCTAssertEqual(1800, targetHint["ttlSeconds"] as? Int)
//            XCTAssertEqual("35", targetHint["hint"] as? String)
            
            print("LISTENER: \(data)")
            Log.debug(label: self.LOG_SOURCE, "LISTENER: \(data)")
//            XCTAssertEqual(true, data?[MessagingConstants.Event.Data.Key.REFRESH_MESSAGES] as? Bool)
            edgeRequestContentExpectation.fulfill()
        }
        
        // test
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


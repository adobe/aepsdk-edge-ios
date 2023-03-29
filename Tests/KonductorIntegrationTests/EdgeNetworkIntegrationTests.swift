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

import AEPCore
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

/// This Test class is an example of usages of the FunctionalTestBase APIs
class KonductorIntegrationTests: FunctionalTestBase {
    private let event1 = Event(name: "e1", type: "eventType", source: "eventSource", data: ["key1":"value1"])
//    private let xdmEvent = Event(name: <#T##String#>, type: <#T##String#>, source: <#T##String#>, data: <#T##[String : Any]?#>)
    private let event2 = Event(name: "e2", type: "eventType", source: "eventSource", data: nil)
    private let exEdgeInteractUrlString = "https://edge.adobedc.net/ee/v1/interact"
    private let exEdgeInteractUrl = URL(string: "https://edge.adobedc.net/ee/v1/interact")! // swiftlint:disable:this force_unwrapping
    private let responseBody = "{\"test\": \"json\"}"
    
    private var edgeNetworkEnvironment: EdgeNetworkEnvironment = .prod
    private var edgeLocationHint: EdgeLocationHint? = nil
    
    /// Edge Network (Konductor) environment levels that correspond to their deployment environment levels
    enum EdgeNetworkEnvironment: String {
        /// Production
        case prod
        /// Pre-production - aka: staging
        case preProd = "pre-prod"
        /// Integration - aka: development
        case int
    }
    
    /// All location hint values available for the Edge network extension
    enum EdgeLocationHint: String {
        /// Oregon, USA
        case or2
        /// Virginia, USA
        case va6
        /// Ireland
        case irl1
        /// India
        case ind1
        /// Japan
        case jpn3
        /// Singapore
        case sgp3
        /// Australia
        case aus3
    }
    
    private let testingDelegate = NetworkTestingDelegate()
    
    let LOG_SOURCE = "SampleFunctionalTests"
    
    let asyncTimeout: TimeInterval = 10

    public class override func setUp() {
        super.setUp()
        FunctionalTestBase.debugEnabled = true
        
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        func extractEnvironmentVariable<T: RawRepresentable>(keyName: String, enum: T.Type) -> T? where T.RawValue == String {
            guard let environmentString = ProcessInfo.processInfo.environment[keyName] else {
                print("Unable to find valid \(keyName) value (raw value: \(String(describing: ProcessInfo.processInfo.environment[keyName]))).")
                return nil
            }
            
            guard let enumCase = T(rawValue: environmentString) else {
                print("Unable to create valid enum case of type \(T.Type.self) from environment variable value: \(environmentString)")
                return nil
            }
            
            return enumCase
        }
        
        // hub shared state update for extension versions (InstrumentedExtension (registered in FunctionalTestBase), IdentityEdge, Edge), Edge extension, IdentityEdge XDM shared state and Config shared state updates
        //        setExpectationEvent(type: FunctionalTestConst.EventType.HUB, source: FunctionalTestConst.EventSource.SHARED_STATE, expectedCount: 4)
        //
        //        // expectations for update config request&response events
        //        setExpectationEvent(type: FunctionalTestConst.EventType.CONFIGURATION, source: FunctionalTestConst.EventSource.REQUEST_CONTENT, expectedCount: 1)
        //        setExpectationEvent(type: FunctionalTestConst.EventType.CONFIGURATION, source: FunctionalTestConst.EventSource.RESPONSE_CONTENT, expectedCount: 1)
        
        // Extract Konductor environment level from shell environment
        if let environment = extractEnvironmentVariable(keyName: "EDGE_NETWORK_ENVIRONMENT", enum: EdgeNetworkEnvironment.self) {
            self.konductorEnvironment = environment
        }
        print("Using Edge Network environment: \(konductorEnvironment.rawValue)")
        // Extract Edge location hint from shell environment
        if let locationHint = extractEnvironmentVariable(keyName: "EDGE_LOCATION_HINT", enum: EdgeLocationHint.self) {
            self.edgeLocationHint = locationHint
        }
        
    
//        print("all env vars: \(ProcessInfo.processInfo.environment)")
        
        // Wait for async registration because the EventHub is already started in FunctionalTestBase
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
        
//        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])

//        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
        registerNetworkServiceTestingDelegate(delegate: testingDelegate)
    }
    
    // TODO: create specific listeners for type: Edge + source: * (wildcard) and capture all the response handles for the test event
    // TODO: create specific listeners for error responses
    func registerEdgeLocationHintListener(_ listener: @escaping EventListener) {
        MobileCore.registerEventListener(type: FunctionalTestConst.EventType.EDGE, source: "locationHint:result", listener: listener)
    }
    
    func readJSONData(fileName: String) -> [String:Any]? {
        guard let pathString = Bundle(for: type(of: self)).path(forResource: fileName, ofType: "json") else {
//            fatalError("\(fileName).json not found")
            return nil
        }

        guard let jsonString = try? String(contentsOfFile: pathString, encoding: .utf8) else {
//            fatalError("Unable to convert \(fileName).json to String")
            return nil
        }

        print("The JSON string is: \(jsonString)")

        guard let jsonData = jsonString.data(using: .utf8) else {
//            fatalError("Unable to convert \(fileName).json to Data")
            return nil
        }

        guard let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:Any] else {
//            fatalError("Unable to convert \(fileName).json to JSON dictionary")
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
//            data["payload"]
            guard let payloadArray = data?["payload"] as? [[String:Any]] else {
                XCTFail()
                return
            }
            print()
            let targetHint = payloadArray[0]
            guard let locationHintCorrectValue = self.readJSONData(fileName: "locationHint"), let locationHintPayload = locationHintCorrectValue["payload"] as? [[String:Any]] else {
                XCTFail()
                return
            }
            
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


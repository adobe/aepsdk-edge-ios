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


/// This test class validates proper intergration with upstream services, specifically Edge Network
class UpstreamIntegrationTests: XCTestCase {
    private var edgeEnvironment: EdgeEnvironment = .prod
    private var edgeLocationHint: EdgeLocationHint? = nil
    
    private let testingDelegate = NetworkTestingDelegate()
    
    let LOG_SOURCE = "SampleFunctionalTests"
    
    let asyncTimeout: TimeInterval = 10
    
    override func setUp() {
        let networkService = IntegrationTestNetworkService()
        networkService.testingDelegate = testingDelegate
        ServiceProvider.shared.networkService = networkService
        
        // Extract Edge Network environment level from shell environment; see init for default value
        self.edgeEnvironment = EdgeEnvironment()
        print("Using Edge Network environment: \(edgeEnvironment.rawValue)")
        
        // Extract Edge location hint from shell environment; see init for default value
        self.edgeLocationHint = EdgeLocationHint()
        
        let waitForRegistration = CountDownLatch(1)
        MobileCore.setLogLevel(.trace)
        // Set environment file ID for specific Edge Network environment
        setMobileCoreEnvironmentFileID(for: edgeEnvironment)
        MobileCore.registerExtensions([Identity.self, Edge.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))
        
        // Set Edge location hint value if one is set for the test target
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
    
    // MARK: - Upstream integration test cases
    
    func testSendEvent_withStandardExperienceEvent_receivesExpectedEventHandles() {
        // Setup
        // Test expectations that make sure the callbacks fire for:
        // 1. The network response from Edge Network
        // 2. The event response handles converted into events, captured by test case event listeners
        let edgeRequestContentExpectation = XCTestExpectation(description: "Edge extension request content listener called")
        let networkResponseExpectation = XCTestExpectation(description: "Network request callback called")
        
        // MARK: Network response assertions
        testingDelegate.testCaseCompletion = { httpConnection in
            print("SOURCE: testCaseCompletion: \(httpConnection)")
            print("data as string: \(httpConnection.responseString)")
            
            httpConnection.response?.url
            print("baseURL: \(httpConnection.response?.url?.host)")
            if httpConnection.response?.url?.host == "obumobile5.data.adobedc.net" {
                XCTAssertEqual(200, httpConnection.responseCode)
                networkResponseExpectation.fulfill()
            }
            
        }
        
        let validationJSON = #"""
        {
          "payload": [
            {
              "ttlSeconds" : 1800,
              "scope" : "Target",
              "hint" : "35"
            },
            {
              "ttlSeconds" : 1800,
              "scope" : "AAM",
              "hint" : "9"
            },
            {
              "ttlSeconds" : 1800,
              "scope" : "EdgeNetwork",
              "hint" : "or2"
            }
          ]
        }
        """#
        
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
            guard let locationHintCorrectValue: [String:Any] = self.convertToJSON(validationJSON), let locationHintPayload = locationHintCorrectValue["payload"] as? [[String:Any]] else {
                XCTFail()
                return
            }
            
            // TODO: JSON dictionary compare
            XCTAssertEqual("Target", targetHint["scope"] as? String)
            XCTAssertEqual(1800, targetHint["ttlSeconds"] as? Int)
            
            Log.debug(label: self.LOG_SOURCE, "LISTENER: \(String(describing: data))")
            edgeRequestContentExpectation.fulfill()
        }
        
        // Test
        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                              data: ["data": ["test": "data"]])
        Edge.sendEvent(experienceEvent: experienceEvent)
        
        
        // Verify
        wait(for: [edgeRequestContentExpectation, networkResponseExpectation], timeout: asyncTimeout)
    }
    
    func testJSONComparisonSystem() {
        let multilineValidation = #"""
          {
            "integerCompare": 456,
            "decimalCompare": 123.123,
            "stringCompare": "abc",
            "boolCompare": true,
            "nullCompare": null,
            "arraySizeCompare": [1,2,3],
            "arrayValueCompare": [1],
            "arrayOfObjectsPass": [
              {
                "object1": "value1"
              },
              {
                "object2": "value2"
              }
            ],
            "arrayOfObjectsFail": [
              {
                "object1": "value1"
              },
              {
                "object2": "value2"
              }
            ],
            "dictionaryCompare": {
              "nested1": "value1"
            },
            "dictionaryNestedCompare": {
              "nested1": {
                "nested2": {
                  "nested3": {
                    "nested4": {
                      "nested1": "value1"
                    }
                  }
                }
              }
            },
            "trulyNested": [
              {
                "nest1": [
                  {
                    "nest2": {
                      "nest3": [
                        {
                          "nest4": "value1"
                        }
                      ]
                    }
                  }
                ]
              }
            ]
          }
        """#
        
        let multilineInput = #"""
          {
            "integerCompare": 0,
            "decimalCompare": 4.123,
            "stringCompare": "def",
            "boolCompare": false,
            "nullCompare": "not null",
            "arraySizeCompare": [1,2],
            "arrayValueCompare": [0],
            "arrayOfObjectsPass": [
              {
                "object1": "value1"
              },
              {
                "object2": "value2"
              }
            ],
            "arrayOfObjectsFail": [
              {
                "object1": "value1"
              },
              {
                "object2": "value3"
              }
            ],
            "dictionaryCompare": {
              "nested1different": "value1"
            },
            "dictionaryNestedCompare": {
              "nested1": {
                "nested2": {
                  "nested3": {
                    "nested4": {
                      "nested1": "value2"
                    }
                  }
                }
              }
            },
            "trulyNested": [
              {
                "nest1": [
                  {
                    "nest2": {
                      "nest3": [
                        [
                          "nest4"
                        ]
                      ]
                    }
                  }
                ]
              }
            ]
          }
        """#
        
        // MARK: AnyCodable testing
        let jsonValidation = try? JSONDecoder().decode(AnyCodable.self, from: multilineValidation.data(using: .utf8)!)
        let jsonInput = try? JSONDecoder().decode(AnyCodable.self, from: multilineInput.data(using: .utf8)!)
        assertEqual(lhs: jsonValidation, rhs: jsonInput)
    }
    
    // MARK: - Test helper methods
    
    /// Converts a JSON string into the provided type.
    ///
    /// NOTE: caller is reponsible for providing the correct casting type resulting JSON, otherwise decoding will fail
    func convertToJSON<T>(_ jsonString: String) -> T? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail("Unable to convert provided JSON string to Data: \(jsonString)")
            return nil
        }
        
        guard let jsonDictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? T else {
            XCTFail("Unable to convert provided JSON string to JSON type \(T.self)")
            return nil
        }
        return jsonDictionary
    }
    
    func setMobileCoreEnvironmentFileID(for edgeEnvironment: EdgeEnvironment) {
        switch edgeEnvironment {
        case .prod:
            MobileCore.configureWith(appId: "94f571f308d5/6b1be84da76a/launch-023a1b64f561-development")
        case .preProd:
            MobileCore.configureWith(appId: "94f571f308d5/6b1be84da76a/launch-023a1b64f561-development")
        case .int:
            // TODO: create integration environment environment file ID
            MobileCore.configureWith(appId: "94f571f308d5/6b1be84da76a/launch-023a1b64f561-development")
        }
    }
    
    // TODO: create specific listeners for type: Edge + source: * (wildcard) and capture all the response handles for the test event
    // TODO: create specific listeners for error responses
    func registerEdgeLocationHintListener(_ listener: @escaping EventListener) {
        MobileCore.registerEventListener(type: FunctionalTestConst.EventType.EDGE, source: "locationHint:result", listener: listener)
    }
    
    // MARK: AnyCodable helpers
    /// Performs testing assertions between two `[AnyCodable]` instances.
    func assertEqual(lhs: [String: AnyCodable]?, rhs: [String: AnyCodable]?, keyPath: [String]) {
        if lhs == nil, rhs == nil {
            return
        }
        guard let lhs = lhs, let rhs = rhs else {
            XCTFail(#"""
                \#(lhs == nil ? "lhs is nil" : "rhs is nil") and \#(lhs == nil ? "rhs" : "lhs") is non-nil

                lhs: \#(String(describing: lhs))
                
                rhs: \#(String(describing: rhs))
                
                key path: \#(keyPath)
            """#)
            return
        }
        if lhs.count != rhs.count {
            XCTFail(#"""
                lhs and rhs counts do not match.
                lhs count: \#(lhs.count)
                rhs count: \#(rhs.count)
                
                lhs: \#(lhs)
                
                rhs: \#(rhs)
                
                key path: \#(keyPath)
            """#)
            return
        }
        for (key, value) in lhs {
            var keyPath = keyPath
            keyPath.append(key)
            assertEqual(lhs: value, rhs: rhs[key], keyPath: keyPath)
        }
    }
    
    /// Performs testing assertions between two `[AnyCodable]` instances.
    func assertEqual(lhs: [AnyCodable]?, rhs: [AnyCodable]?, keyPath: [String]) {
        if lhs == nil, rhs == nil {
            return
        }
        guard let lhs = lhs, let rhs = rhs else {
            XCTFail(#"""
                \#(lhs == nil ? "lhs is nil" : "rhs is nil") and \#(lhs == nil ? "rhs" : "lhs") is non-nil

                lhs: \#(String(describing: lhs))
                
                rhs: \#(String(describing: rhs))
                
                key path: \#(keyPath)
            """#)
            return
        }
        if lhs.count != rhs.count {
            XCTFail(#"""
                lhs and rhs counts do not match.
                lhs count: \#(lhs.count)
                rhs count: \#(rhs.count)
                
                lhs: \#(lhs)
                
                rhs: \#(rhs)
                
                key path: \#(keyPath)
            """#)
            return
        }
        for (index, valueTuple) in zip(lhs, rhs).enumerated() {
            var keyPath = keyPath
            keyPath.append("[\(index)]")
            assertEqual(lhs: valueTuple.0, rhs: valueTuple.1, keyPath: keyPath)
        }
    }
    /// Performs testing assertions between two `AnyCodable` instances, using a similar logic path as the `AnyCodable ==` implementation.
    /// Traces the key path (both dictionary keys and array indices) and provides the trace on assertion failure, for easier debugging.
    /// Automatically performs any required conversions of underlying `Any?` types into `AnyCodable` format.
    ///
    /// Main entrypoint for `AnyCodable` testing assertions.
    func assertEqual(lhs: AnyCodable?, rhs: AnyCodable?, keyPath: [String] = []) {
        if lhs?.value == nil, rhs?.value == nil {
            return
        }
        guard let lhs = lhs, let rhs = rhs else {
            XCTFail(#"""
                \#(lhs == nil ? "lhs is nil" : "rhs is nil") and \#(lhs == nil ? "rhs" : "lhs") is non-nil

                lhs: \#(String(describing: lhs))
                
                rhs: \#(String(describing: rhs))
                
                key path: \#(keyPath)
            """#)
            return
        }

        switch (lhs.value, rhs.value) {
        case let (lhs as String, rhs as String):
            XCTAssertEqual(lhs, rhs, "key path: \(keyPath)")
        case let (lhs as Bool, rhs as Bool):
            XCTAssertEqual(lhs, rhs, "key path: \(keyPath)")
        case let (lhs as Int, rhs as Int):
            XCTAssertEqual(lhs, rhs, "key path: \(keyPath)")
        case let (lhs as Double, rhs as Double):
            XCTAssertEqual(lhs, rhs, "key path: \(keyPath)")
        case let (lhs as [String: AnyCodable], rhs as [String: AnyCodable]):
            return assertEqual(lhs: lhs, rhs: rhs, keyPath: keyPath)
        case let (lhs as [AnyCodable], rhs as [AnyCodable]):
            return assertEqual(lhs: lhs, rhs: rhs, keyPath: keyPath)
        case let (lhs as [Any?], rhs as [Any?]):
            return assertEqual(lhs: AnyCodable.from(array: lhs), rhs: AnyCodable.from(array: rhs), keyPath: keyPath)
        case let (lhs as [String: Any?], rhs as [String: Any?]):
            return assertEqual(lhs: AnyCodable.from(dictionary: lhs), rhs: AnyCodable.from(dictionary: rhs), keyPath: keyPath)
        default:
            XCTFail(#"""
                lhs and rhs types do not match

                lhs: \#(lhs)
                
                rhs: \#(rhs)
                
                key path: \#(keyPath)
            """#)
        }
    }
}


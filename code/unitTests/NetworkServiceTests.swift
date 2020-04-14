//
// ADOBE CONFIDENTIAL
//
// Copyright 2020 Adobe
// All Rights Reserved.
//
// NOTICE: All information contained herein is, and remains
// the property of Adobe and its suppliers, if any. The intellectual
// and technical concepts contained herein are proprietary to Adobe
// and its suppliers and are protected by all applicable intellectual
// property laws, including trade secret and copyright laws.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from Adobe.
//

import XCTest

@testable import ACPExperiencePlatform

class NetworkServiceTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testConnectAsync_doesNotThrow() {
        // Create an expectation for a background download task.
        let expectation = XCTestExpectation(description: "Completion handler called")
        
        guard let testUrl = URL(string: "https://") else {
            XCTFail()
            return
        }
        
        let networkRequest = NetworkRequest(url: testUrl)
        let networkService = NetworkService.shared.connectAsync(networkRequest: networkRequest, completionHandler: {connection in

            expectation.fulfill()
        })
        
        // Wait until the expectation is fulfilled, with a timeout of 1 seconds.
        wait(for: [expectation], timeout: 1.0)
        
    }
}

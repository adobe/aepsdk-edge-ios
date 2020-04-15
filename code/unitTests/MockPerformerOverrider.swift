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


import Foundation
@testable import ACPExperiencePlatform

class MockPerformerOverrider : HttpConnectionPerformer {
    var overrideUrlList:[URL]
    var shouldOverrideCalled:Bool?
    var shouldOverrideCalledWithUrls:[URL]
    var connectAsyncCalled:Bool?
    var connectAsyncCalledWithNetworkRequest:NetworkRequest?
    var connectAsyncCalledWithCompletionHandler: ((HttpConnection) -> Void)?
    
    init(overrideUrls:[URL] = []) {
        overrideUrlList = overrideUrls
        shouldOverrideCalledWithUrls = []
        reset()
    }
    
    func shouldOverride(url: URL, httpMethod: HttpMethod) -> Bool {
        shouldOverrideCalled = true
        shouldOverrideCalledWithUrls.append(url)
        
        return overrideUrlList.isEmpty || overrideUrlList.contains(url)
    }
    
    func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {
        print("Do nothing \(networkRequest)")
        connectAsyncCalled = true
        connectAsyncCalledWithNetworkRequest = networkRequest
        connectAsyncCalledWithCompletionHandler = completionHandler
    }
    
    func reset() {
        shouldOverrideCalled = false
        shouldOverrideCalledWithUrls = []
        connectAsyncCalled = false
        connectAsyncCalledWithNetworkRequest = nil
        connectAsyncCalledWithCompletionHandler = nil
    }
}

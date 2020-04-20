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


import SwiftUI
import ACPExperiencePlatform

class TestHttpConnectionPerformer: HttpConnectionPerformer {
    func shouldOverride(url: URL, httpMethod: HttpMethod) -> Bool {
        return true
    }
    
    func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?) {
        print("Do nothing \(networkRequest)")
    }
}

struct ContentView: View {
    var body: some View {
        Button(action: {
            let networkRequest1:NetworkRequest = NetworkRequest(url: URL(string: "https://www.adobe.com")!, httpMethod: HttpMethod.get, connectPayload: "test", httpHeaders: [:],
                                                                connectTimeout: 5, readTimeout: 5)
            
            NetworkServiceOverrider.shared.enableOverride(with: TestHttpConnectionPerformer())
            ACPNetworkService.shared.connectAsync(networkRequest: networkRequest1, completionHandler: {connection in
                                               // function body goes here
                print(connection.responseHttpHeader(forKey: "Content-Type") ?? "no content-type header")
                print(connection.responseCode ?? "no response code")
                print(connection.responseMessage ?? "no response message")
            })
            
            NetworkServiceOverrider.shared.reset()
            
            // not permitted
            // ACPNetworkService.shared.connectAsync(networkRequest: nil)
            
            // fire and forget example
            ACPNetworkService.shared.connectAsync(networkRequest: networkRequest1)
            
            // not https protocol not permitted, network request is constructed, but the connection is not initiated
            let networkRequestInvalid:NetworkRequest = NetworkRequest(url: URL(string: "http://www.adobe.com")!) // using default param values
            ACPNetworkService.shared.connectAsync(networkRequest: networkRequestInvalid)
            print(networkRequestInvalid)
            
            // nil/empty url not permitted
            //let networkRequestWithNilUrl:NetworkRequest = NetworkRequest(url: nil, httpMethod: HttpMethod.get, connectPayload: "test", httpHeaders: [:],
            //connectTimeout: 5, readTimeout: 5) ?? nil
        }) {
            Text("Ping")
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

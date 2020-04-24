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

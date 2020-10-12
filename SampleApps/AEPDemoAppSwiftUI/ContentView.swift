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

import AEPEdge
import AEPServices
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Button(action: {
                let networkRequest1: NetworkRequest = NetworkRequest(url: URL(string: "https://www.adobe.com")!,
                                                                     httpMethod: HttpMethod.get,
                                                                     connectPayload: "test",
                                                                     httpHeaders: [:],
                                                                     connectTimeout: 5,
                                                                     readTimeout: 5)

                ServiceProvider.shared.networkService.connectAsync(networkRequest: networkRequest1, completionHandler: {connection in
                    // function body goes here
                    print(connection.responseHttpHeader(forKey: "Content-Type") ?? "no content-type header")
                    print(connection.responseCode ?? "no response code")
                    print(connection.responseMessage ?? "no response message")
                })
            }) {
                Text("Network Service ping")
            }.padding()

            Button(action: {
                let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                                              data: ["data": ["test": "data"]])
                Edge.sendEvent(experienceEvent: experienceEvent, responseHandler: DemoResponseHandler())
            }) {
                Text("Ping to ExEdge")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

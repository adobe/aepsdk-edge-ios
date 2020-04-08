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

struct ContentView: View {
    var body: some View {
        Button(action: {
            let networkService:NetworkService = NetworkService()
            let networkRequest1:NetworkRequest? = NetworkRequest(url: URL(string: "https://www.adobe.com")!, httpMethod: HttpMethod.get, connectPayload: "test", httpHeaders: [:],
                                                                connectTimeout: 5, readTimeout: 5) ?? nil
            
            guard networkRequest1 != nil else {
                return;
            }
            networkService.connectUrlAsync(networkRequest: networkRequest1!, completionHandler: {connection in
                                               // function body goes here
                print(connection.responseHttpHeader(forKey: "Content-Type"))
                print(connection.responseCode)
                print(connection.responseMessage)
            })
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

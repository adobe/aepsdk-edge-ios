/*
Copyright 2020 Adobe. All rights reserved.
This file is licensed to you under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License. You may obtain a copy
of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under
the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
OF ANY KIND, either express or implied. See the License for the specific language
governing permissions and limitations under the License.
*/

import Foundation

struct HttpConnection {
    let data: Data?
    let response: HTTPURLResponse?
    let error: Error? // propose to add this
    
    var responseString: String? {
        if let unwrappedData = data {
            return String(data: unwrappedData, encoding: .utf8)
        }
        
        return nil
    }
    
    var responseCode: Int? {
        return response?.statusCode
    }
    
    var responseMessage: String? {
        if let code = responseCode {
            return HTTPURLResponse.localizedString(forStatusCode: code)
        }
        
        return nil
    }
    
    func getResponsePropertyValue(responsePropertyKey: String) -> String? {
        return response?.allHeaderFields[responsePropertyKey] as? String
    }
}

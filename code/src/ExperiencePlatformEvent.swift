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


import Foundation

public struct ExperiencePlatformEvent {

    private let LOG_TAG = "ExperiencePlatformEvent"

    var xdm: [String: Any]?
    var data: [String: Any]?
 
    
    init(xdm: [String : Any]?, data: [String : Any]?) {
         if let unwrappedXdm = xdm {
            self.xdm = unwrappedXdm
        }
        if let unwrappedData = data {
            self.data = unwrappedData
        }
    }

     init(xdm: XDMSchema?, data: [String : Any]?) {
        if let unwrappedXdm = xdm {
            let jsonData = unwrappedXdm.toJSONData()
            if let unwrappedjsonData = jsonData {
                self.xdm = try? JSONSerialization.jsonObject(with: unwrappedjsonData, options: []) as? [String: Any]
            }
        }
        if let unwrappedData = data {
            self.data = unwrappedData
        }
    }


    internal func asDictionary() -> [String : Any]? {
         var dataDict: [String : Any] = [:]
         if let xdm = xdm {
              dataDict["xdm"] = xdm
         }
         if let data = data {
             dataDict["data"] = data
        }
        return dataDict.isEmpty ? nil : dataDict
    }

}

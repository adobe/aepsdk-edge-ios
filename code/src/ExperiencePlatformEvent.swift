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
            self.xdm = xdm
            self.data = data
    }

     init(xdm: XDMSchema?, data: [String : Any]?) {
        if let unwrappedxdm = xdm {
            let jsonXdm = unwrappedxdm.toJSONData()
            if let unwrappedJsonXdm = jsonXdm {
                self.xdm = try? JSONSerialization.jsonObject(with: unwrappedJsonXdm, options: []) as? [String: Any]
            }
        }
            self.data = data
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

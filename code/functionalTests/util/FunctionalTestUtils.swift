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

public class FunctionalTestUtils {
    
    /// Removes all User Defaults
    public static func resetUserDefaults() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
    
    public static func flattenDictionary(dict: [String : Any]) -> [String : Any] {
        var result: [String : Any] = [:]
        
        func recursive(dict: [String : Any], out: inout [String : Any], currentKey: String = "") {
            if dict.isEmpty {
                out[currentKey] = "isEmpty"
                return
            }
            for (key, val) in dict {
                let resultKey = currentKey.isEmpty ? key : currentKey + "." + key
                process(value: val, out: &out, key: resultKey)
            }
        }
        
        func recursive(list: [Any], out: inout [String : Any], currentKey: String) {
            if list.isEmpty {
                out[currentKey] = "isEmpty"
                return
            }
            for (index, value) in list.enumerated() {
                let resultKey = currentKey + "[\(index)]"
                process(value: value, out: &out, key: resultKey)
            }
        }
        
        func process(value: Any, out: inout [String : Any], key: String) {
            if let value = value as? [String : Any] {
                recursive(dict: value, out: &out, currentKey: key)
            } else if let value = value as? [Any] {
                recursive(list: value, out: &out, currentKey: key)
            } else {
                out[key] = value
            }
        }
        
        recursive(dict: dict, out: &result)
        return result
    }
}

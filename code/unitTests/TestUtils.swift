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

/// Flatten a multi-level dictionary to a single level where each key is a dotted notation of each nested key.
/// - Parameter dict: the dictionary to flatten
func flattenDictionary(dict: [String : Any]) -> [String : Any] {
    var result: [String : Any] = [:]
    
    func recursive(dict: [String : Any], out: inout [String : Any], currentKey: String = "") {
        if dict.isEmpty {
            out[currentKey] = "isEmpty"
            return
        }
        for (key, val) in dict {
            let resultKey = currentKey + "." + key
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

/// Convert an timestamp in miliseconds since Linux epoch to an iso 8601 formatted date string.
/// - Parameter timestamp: miliseconds since epoch
func timestampToISO8601(_ timestamp: Int) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp/1000))
    return ISO8601DateFormatter().string(from: date)
}

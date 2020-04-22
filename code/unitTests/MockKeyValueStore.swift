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

class MockKeyValueStore : KeyValueStore {
    
    var dataStore: [String : Any]

    init() {
        dataStore = [:]
    }
    
    func setInt(key: String, value: Int) {
        set(key: key, value: value)
    }
    
    func getInt(key: String, fallback: Int? = nil) -> Int? {
        return get(key: key) as? Int ?? fallback
    }
    
    func setString(key: String, value: String) {
        set(key: key, value: value)
    }
    
    func getString(key: String, fallback: String?) -> String? {
        return get(key: key) as? String ?? fallback
    }
    
    func setDouble(key: String, value: Double) {
        set(key: key, value: value)
    }
    
    func getDouble(key: String, fallback: Double?) -> Double? {
        return get(key: key) as? Double ?? fallback
    }
    
    func setLong(key: String, value: __int64_t) {
        set(key: key, value: value)
    }
    
    func getLong(key: String, fallback: __int64_t?) -> __int64_t? {
        return get(key: key) as? __int64_t ?? fallback
    }
    
    func setFloat(key: String, value: Float) {
        set(key: key, value: value)
    }
    
    func getFloat(key: String, fallback: Float?) -> Float? {
        return get(key: key) as? Float ?? fallback
    }
    
    func setBool(key: String, value: Bool) {
        set(key: key, value: value)
    }
    
    func getBool(key: String, fallback: Bool?) -> Bool? {
        return get(key: key) as? Bool ?? fallback
    }
    
    func setArray(key: String, value: Array<String>) {
        set(key: key, value: value)
    }
    
    func getArray(key: String, fallback: [String]?) -> [String]? {
        return get(key: key) as? Array<String> ?? fallback
    }
    
    func setDictionary(key: String, value: [String: String]) {
        set(key: key, value: value)
    }
    
    func getDictionary(key: String, fallback: [String: String]?) -> [String: String]? {
        return get(key: key) as? [String: String] ?? fallback
    }
    
    func setObject<T: Codable>(key: String, value: T) {
        let encoder = JSONEncoder()
        if let encodedValue = try? encoder.encode(value) {
            set(key: key, value: encodedValue)
        } else {
            set(key: key, value: nil)
        }
    }
    
    func getObject<T: Codable>(key: String, fallback: T? = nil) -> T? {
        if let savedData = get(key: key) as? Data {
            let decoder = JSONDecoder()
            return try? decoder.decode(T.self, from: savedData)
        }
        
        return fallback
    }
    
    func contains(key: String) -> Bool {
        return (get(key: key) != nil) ? true : false
    }
    
    func remove(key: String) {
        if key.isEmpty {
            return
        }
        dataStore.removeValue(forKey: key)
    }
    
    func removeAll() {
        dataStore.removeAll()
    }
    
    func dictionaryRepresentation() -> [String : Any] {
        return [:]
    }
    
    private func set(key: String, value: Any?) {
        if key.isEmpty {
            return
        }
        
        dataStore[key] = value
    }
    
    private func get(key: String) -> Any? {
        if key.isEmpty {
           return nil
        }
        return dataStore[key]
    }
}

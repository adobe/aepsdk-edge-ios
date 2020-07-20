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

/// The KeyValueStore to be used by the iOS platform
class NamedUserDefaultsStore: KeyValueStore {

    private let dataStoreName: String
    private let keyPrefix: String
    private let userDefaults: UserDefaults

    init(name: String) {
        dataStoreName = name
        keyPrefix = "com.adobe.mobile.datastore.\(dataStoreName)."
        // TODO: - Take care of suite name / app group initialization
        userDefaults = UserDefaults(suiteName: "\(keyPrefix)") ?? UserDefaults.standard
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

    func setArray(key: String, value: [String]) {
        set(key: key, value: value)
    }

    func getArray(key: String, fallback: [String]?) -> [String]? {
        return get(key: key) as? [String] ?? fallback
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

        userDefaults.removeObject(forKey: keyPrefix + key)
    }

    func removeAll() {
        let userDefaultsDict = userDefaults.dictionaryRepresentation()
        for item in userDefaultsDict {
            userDefaults.removeObject(forKey: item.key)
        }
    }

    func dictionaryRepresentation() -> [String: Any] {
        return userDefaults.dictionaryRepresentation()
    }

    private func set(key: String, value: Any?) {
        if key.isEmpty {
            return
        }

        userDefaults.set(value, forKey: keyPrefix + key)
    }

    private func get(key: String) -> Any? {
        if key.isEmpty {
            return nil
        }

        return userDefaults.object(forKey: keyPrefix + key)
    }
}

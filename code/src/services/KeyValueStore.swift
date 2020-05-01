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

/// A key value store
protocol KeyValueStore {
    
    /// Sets or updates an int value
    /// - Parameters:
    ///   - key: `String` representation of key
    ///   - value: `Int` value to be set or updated
    func setInt(key: String, value: Int)
    
    /// Get int value for key
    /// - Parameters:
    ///     - key: `String` representation of key
    ///     - fallback: `Int?` the default value to return if key does not exist
    /// - Returns: A persisted value if it exists, defaultValue otherwise
    func getInt(key: String, fallback: Int?) -> Int?
    
    /// Sets or updates a string value
    /// - Parameters:
    ///   - key: `String` representation of key
    ///   - value: `String` value to be set or updated
    func setString(key: String, value: String)
    
    /// Get string value for key
    /// - Parameters:
    ///     - key: `String` representation of key
    ///     - fallback: `String?` the default value to return if key does not exist
    /// - Returns: A persisted value if it exists, defaultValue otherwise
    func getString(key: String, fallback: String?) -> String?
    
    /// Sets or updates a double value
    /// - Parameters:
    ///   - key: `String` representation of key
    ///   - value: `double` value to be set or updated
    func setDouble(key: String, value: Double)
    
    /// Get double value for key
    /// - Parameters:
    ///     - key: `String` representation of key
    ///     - fallback: `Double?` the default value to return if key does not exist
    /// - Returns: A persisted value if it exists, defaultValue otherwise
    func getDouble(key: String, fallback: Double?) -> Double?
    
    /// Sets or updates an __int64_t value
    /// - Parameters:
    ///   - key: `String` representation of key
    ///   - value: `__int64_t` value to be set or updated
    func setLong(key: String, value: __int64_t)
    
    /// Get __int64_t value for key
    /// - Parameters:
    ///     - key: `String` representation of key
    ///     - fallback: `__int64_t?` the default value to return if key does not exist
    /// - Returns: A persisted value if it exists, defaultValue otherwise
    func getLong(key: String, fallback: __int64_t?) -> __int64_t?
    
    /// Sets or updates a Float value
    /// - Parameters:
    ///   - key: `String` representation of key
    ///   - value: `Float` value to be set or updated
    func setFloat(key: String, value: Float)
    
    /// Get Float value for key
    /// - Parameters:
    ///     - key: `String` representation of key
    ///     - fallback: `Float?` the default value to return if key does not exist
    /// - Returns: A persisted value if it exists, defaultValue otherwise
    func getFloat(key: String, fallback: Float?) -> Float?
    
    /// Sets or updates a Bool value
    /// - Parameters:
    ///   - key: `String` representation of key
    ///   - value: `Bool` value to be set or updated
    func setBool(key: String, value: Bool)
    
    /// Get Bool value for key
    /// - Parameters:
    ///     - key: `String` representation of key
    ///     - fallback: `Bool?` the default value to return if key does not exist
    /// - Returns: A persisted value if it exists, defaultValue otherwise
    func getBool(key: String, fallback: Bool?) -> Bool?
    
    /// Sets or updates a string array value
    /// - Parameters:
    ///   - key: `String` representation of key
    ///   - value: `[String]` value to be set or updated
    func setArray(key: String, value: [String])
    
    /// Get string array value for key
    /// - Parameters:
    ///     - key: `String` representation of key
    ///     - fallback: `[String]?` the default value to return if key does not exist
    /// - Returns: A persisted value if it exists, defaultValue otherwise
    func getArray(key: String, fallback: [String]?) -> [String]?
    
    /// Sets or updates a dictionary of strings value
    /// - Parameters:
    ///   - key: `String` representation of key
    ///   - value: `[String: String]` value to be set or updated
    func setDictionary(key: String, value: [String: String])
    
    /// Get string dictionary value for key
    /// - Parameters:
    ///     - key: `String` representation of key
    ///     - fallback: `[String: String]?` the default value to return if key does not exist
    /// - Returns: A persisted value if it exists, defaultValue otherwise
    func getDictionary(key: String, fallback: [String: String]?) -> [String: String]?
    
    /// Sets or updates a given Codable Object.
    /// - Parameters:
    ///     - key: `String` representation of key
    ///     - value: `T: Codable` value to be set or updated
    func setObject<T: Codable>(key: String, value: T)
    
    /// Get T object for key
    /// - Parameters:
    ///     - key: `String` representation of key
    ///     - fallback: `T: Codable?` the default value to return if key does not exist or unarchiving fails
    /// - Returns: A persisted value if it exists and unarchiving succeeds, defaultValue otherwise
    func getObject<T: Codable>(key: String, fallback: T?) -> T?
    
    /// Check if the DataStore contains the given key
    /// - Parameters:
    ///     - key: `String` representation of key
    /// - Returns: True if the key exists in the store, False if it does not
    func contains(key: String) -> Bool
    
    /// Removes the persisted value for the given key
    /// - Parameters:
    ///     - key: `String` representation of key
    func remove(key: String)
    
    /// Remove all key-value pairs from this DataStore
    func removeAll()
    
    /// Gets a dictionary representation of the data store
    /// - Returns: A dictionary representation of the datastore as `[String, Any]`
    func dictionaryRepresentation() -> [String: Any]
}

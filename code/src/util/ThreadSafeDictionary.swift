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

/// A thread safe reference type dictionary
final class ThreadSafeDictionary<K: Hashable, V> {
    typealias Element = Dictionary<K, V>.Element
    private var dictionary = [K: V]()
    private let queue: DispatchQueue
    
    /// Creates a new thread safe dictionary
    /// - Parameter identifier: A unique identifier for this dictionary, a reverse-DNS naming style (com.example.myqueue) is recommended
    init(identifier: String = "com.adobe.threadsafedictionary.queue") {
        queue = DispatchQueue(label: identifier, attributes: .concurrent)
    }
    
    /// How many key pair values are preset in the dictionary
    public var count: Int {
        return queue.sync { return self.dictionary.keys.count }
    }
        
    // MARK: Subscript
     public subscript(key: K) -> V? {
         get {
            return queue.sync { return self.dictionary[key] }
         }
         set {
            queue.async(flags: .barrier) {
                self.dictionary[key] = newValue
             }
         }
     }
    
    
    /// Removes the value for the provided key (if any)
    /// - Parameter forKey: the key to be removed from the dictionary
    /// - Returns: the removed value associated with the key or nil if not found
    public func removeValue(forKey: K) -> V? {
        return queue.sync { return self.dictionary.removeValue(forKey: forKey) }
    }
    
    @inlinable public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        return queue.sync { return try? self.dictionary.first(where: predicate) }
    }

}

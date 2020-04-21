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

enum AuthenticationState : String, Codable {
    case ambiguous = "ambiguous"
    case authenticated = "authenticated"
    case loggedOut = "loggedOut"
}

/// Defines a map containing a set of end user identities, keyed on either namespace integration code or the namespace ID of the identity.
/// Within each namespace, the identity is unique. The values of the map are an array, meaning that more than one identity of each namespace may be carried.
struct IdentityMap {
    private var items: [String : [IdentityItem]] = [:]
    
    /// Adds an `IdentityItem` to this map. If an item is added which shares the same `namespace` and `id` as an item
    /// already in the map, then the new item replaces the existing item.
    /// - Parameters:
    ///   - namespace: the namespace for this identity
    ///   - id: Identity of the consumer in the related namespace.
    ///   - authenticationState: The state this identity is authenticated as for this observed ExperienceEvent.
    ///   - primary: Indicates this identity is the preferred identity. Is used as a hint to help systems better organize how identities are queried.
    mutating func addItem(namespace: String,
                 id: String,
                 authenticationState: AuthenticationState? = nil,
                 primary: Bool? = nil) {
        let item = IdentityItem(id: id, authenticationState: authenticationState, primary: primary)
        
        if var namespaceItems = items[namespace] {
            if let index = namespaceItems.firstIndex(of: item) {
                namespaceItems[index] = item
            } else {
                namespaceItems.append(item)
            }
            items[namespace] = namespaceItems
        } else {
            items[namespace] = [item]
        }
    }
    
    /// Get the array of `IdentityItem` for the given namespace.
    /// - Parameter namespace: the namespace of items to retrieve
    /// - Returns: An array of `IdentityItem` for the given `namespace` or nil if this `IdentityMap` does not contain the `namespace`.
    func getItemsFor(namespace: String) -> [IdentityItem]? {
        return items[namespace]
    }
}

extension IdentityMap : Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(items)
    }
}

extension IdentityMap : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let identityItems = try? container.decode([String : [IdentityItem]].self) {
            items = identityItems
        }
    }
}

/// Identity is used to clearly distinguish people that are interacting with digital experiences.
struct IdentityItem : Codable {
    let id: String?
    let authenticationState: AuthenticationState?
    let primary: Bool?
}

/// Defines two `IdentityItem` objects are equal if they have the same `id`.
extension IdentityItem : Equatable {
    static func ==(lhs: IdentityItem, rhs: IdentityItem) -> Bool {
        return lhs.id == rhs.id
    }
}

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

enum AuthenticationState : String {
    case ambiguous = "ambiguous"
    case authenticated = "authenticated"
    case loggedOut = "loggedOut"
}

struct IdentityMap {
    private var items: [String : [IdentityItem]] = [:]
    
    mutating func addItem(namespace: String,
                 id: String,
                 state: AuthenticationState? = nil,
                 primary: Bool? = nil) {
        let item = IdentityItem(id: id, state: state, primary: primary)
        
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
    
    func getItemsFor(namespace: String) -> [IdentityItem]? {
        if let list = items[namespace] {
            return list
        }
        
        return nil
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

struct IdentityItem {
    var id: String?
    var state: AuthenticationState?
    var primary: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case primary = "primary"
        case state = "authenticationState"
    }
}

extension IdentityItem : Equatable {
    static func ==(lhs: IdentityItem, rhs: IdentityItem) -> Bool {
        return lhs.id == rhs.id
    }
}

extension IdentityItem : Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = id { try container.encode(unwrapped, forKey: .id)}
        if let unwrapped = primary { try container.encode(unwrapped, forKey: .primary)}
        if let unwrapped = state { try container.encode(unwrapped.rawValue, forKey: .state)}
    }
}

extension IdentityItem : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decode(String.self, forKey: .id)
        if let stateValue = try? container.decode(String.self, forKey: .state) {
            state = AuthenticationState.init(rawValue: stateValue)
        }
        primary = try? container.decode(Bool.self, forKey: .primary)
    }
}

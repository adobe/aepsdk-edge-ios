//
// Copyright 2022 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

/*
----
 XDM Property Swift Object Generated 2020-07-17 14:52:38.218773 -0700 PDT m=+2.052211033 by XDMTool
 Title            :    ProductListItemsItem
 Description    :
----
*/

import Foundation


public struct ProductListItemsItem : Decodable {
    public init() {}

    public var currencyCode: String?
    public var name: String?
    public var priceTotal: Double?
    public var productAddMethod: String?
    public var product: String?
    public var quantity: Int64?
    public var sku: String?

    enum CodingKeys: String, CodingKey {
        case currencyCode = "currencyCode"
        case name = "name"
        case priceTotal = "priceTotal"
        case productAddMethod = "productAddMethod"
        case product = "product"
        case quantity = "quantity"
        case sku = "SKU"
    }
}

extension ProductListItemsItem: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = currencyCode { try container.encode(unwrapped, forKey: .currencyCode) }
        if let unwrapped = name { try container.encode(unwrapped, forKey: .name) }
        if let unwrapped = priceTotal { try container.encode(unwrapped, forKey: .priceTotal) }
        if let unwrapped = productAddMethod { try container.encode(unwrapped, forKey: .productAddMethod) }
        if let unwrapped = product { try container.encode(unwrapped, forKey: .product) }
        if let unwrapped = quantity { try container.encode(unwrapped, forKey: .quantity) }
        if let unwrapped = sku { try container.encode(unwrapped, forKey: .sku) }
    }
}

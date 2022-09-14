/*
 Copyright 2022 Adobe
 All Rights Reserved.
 
 NOTICE: Adobe permits you to use, modify, and distribute this file in
 accordance with the terms of the Adobe license agreement accompanying
 it.
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

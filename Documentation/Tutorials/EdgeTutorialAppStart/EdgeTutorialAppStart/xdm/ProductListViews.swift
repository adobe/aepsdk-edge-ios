/*
 Copyright 2022 Adobe
 All Rights Reserved.
 
 NOTICE: Adobe permits you to use, modify, and distribute this file in
 accordance with the terms of the Adobe license agreement accompanying
 it.
----
 XDM Property Swift Object Generated 2020-07-17 14:52:38.218134 -0700 PDT m=+2.051572255 by XDMTool
 Title            :    ProductListViews
 Description    :    View or views of a product-list has occurred.
----
*/

import Foundation


public struct ProductListViews {
    public init() {}

    public var id: String?
    public var value: Double?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case value = "value"
    }
}

extension ProductListViews:Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = id { try container.encode(unwrapped, forKey: .id) }
        if let unwrapped = value { try container.encode(unwrapped, forKey: .value) }
    }
}

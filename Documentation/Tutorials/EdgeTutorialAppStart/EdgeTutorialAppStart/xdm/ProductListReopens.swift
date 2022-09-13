/*
 Copyright 2022 Adobe
 All Rights Reserved.
 
 NOTICE: Adobe permits you to use, modify, and distribute this file in
 accordance with the terms of the Adobe license agreement accompanying
 it.
----
 XDM Property Swift Object Generated 2020-07-17 14:52:38.218054 -0700 PDT m=+2.051492659 by XDMTool
 Title            :    ProductListReopens
 Description    :    A product list that was no longer accessible (abandoned) has been re-activated by the user. Example via a re-marketing activity.
----
*/

import Foundation


public struct ProductListReopens {
    public init() {}

    public var id: String?
    public var value: Double?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case value = "value"
    }
}

extension ProductListReopens:Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = id { try container.encode(unwrapped, forKey: .id) }
        if let unwrapped = value { try container.encode(unwrapped, forKey: .value) }
    }
}

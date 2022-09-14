/*
 Copyright 2022 Adobe
 All Rights Reserved.
 
 NOTICE: Adobe permits you to use, modify, and distribute this file in
 accordance with the terms of the Adobe license agreement accompanying
 it.
----
 XDM Property Swift Object Generated 2020-07-17 14:52:38.219084 -0700 PDT m=+2.052522329 by XDMTool
 Title            :    Commerce
 Description    :    Commerce specific data related to this event.
----
*/

import Foundation


public struct Commerce {
    public init() {}

    public var cartAbandons: CartAbandons?
    public var checkouts: Checkouts?
    public var inStorePurchase: InStorePurchase?
    public var order: Order?
    public var productListAdds: ProductListAdds?
    public var productListOpens: ProductListOpens?
    public var productListRemovals: ProductListRemovals?
    public var productListReopens: ProductListReopens?
    public var productListViews: ProductListViews?
    public var productViews: ProductViews?
    public var purchases: Purchases?
    public var saveForLaters: SaveForLaters?

    enum CodingKeys: String, CodingKey {
        case cartAbandons = "cartAbandons"
        case checkouts = "checkouts"
        case inStorePurchase = "inStorePurchase"
        case order = "order"
        case productListAdds = "productListAdds"
        case productListOpens = "productListOpens"
        case productListRemovals = "productListRemovals"
        case productListReopens = "productListReopens"
        case productListViews = "productListViews"
        case productViews = "productViews"
        case purchases = "purchases"
        case saveForLaters = "saveForLaters"
    }
}

extension Commerce:Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = cartAbandons { try container.encode(unwrapped, forKey: .cartAbandons) }
        if let unwrapped = checkouts { try container.encode(unwrapped, forKey: .checkouts) }
        if let unwrapped = inStorePurchase { try container.encode(unwrapped, forKey: .inStorePurchase) }
        if let unwrapped = order { try container.encode(unwrapped, forKey: .order) }
        if let unwrapped = productListAdds { try container.encode(unwrapped, forKey: .productListAdds) }
        if let unwrapped = productListOpens { try container.encode(unwrapped, forKey: .productListOpens) }
        if let unwrapped = productListRemovals { try container.encode(unwrapped, forKey: .productListRemovals) }
        if let unwrapped = productListReopens { try container.encode(unwrapped, forKey: .productListReopens) }
        if let unwrapped = productListViews { try container.encode(unwrapped, forKey: .productListViews) }
        if let unwrapped = productViews { try container.encode(unwrapped, forKey: .productViews) }
        if let unwrapped = purchases { try container.encode(unwrapped, forKey: .purchases) }
        if let unwrapped = saveForLaters { try container.encode(unwrapped, forKey: .saveForLaters) }
    }
}

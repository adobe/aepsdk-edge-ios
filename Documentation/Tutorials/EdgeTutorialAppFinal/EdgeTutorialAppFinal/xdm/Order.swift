/*
 Copyright 2022 Adobe
 All Rights Reserved.
 
 NOTICE: Adobe permits you to use, modify, and distribute this file in
 accordance with the terms of the Adobe license agreement accompanying
 it.
----
 XDM Property Swift Object Generated 2020-07-17 14:52:38.218364 -0700 PDT m=+2.051802072 by XDMTool
 Title            :    Order
 Description    :    The placed order for one or more products.
----
*/

import Foundation


public struct Order {
    public init() {}

    public var currencyCode: String?
    public var payments: Array<PaymentsItem?>?
    public var priceTotal: Double?
    public var purchaseID: String?
    public var purchaseOrderNumber: String?

    enum CodingKeys: String, CodingKey {
        case currencyCode = "currencyCode"
        case payments = "payments"
        case priceTotal = "priceTotal"
        case purchaseID = "purchaseID"
        case purchaseOrderNumber = "purchaseOrderNumber"
    }
}

extension Order:Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = currencyCode { try container.encode(unwrapped, forKey: .currencyCode) }
        if let unwrapped = payments { try container.encode(unwrapped, forKey: .payments) }
        if let unwrapped = priceTotal { try container.encode(unwrapped, forKey: .priceTotal) }
        if let unwrapped = purchaseID { try container.encode(unwrapped, forKey: .purchaseID) }
        if let unwrapped = purchaseOrderNumber { try container.encode(unwrapped, forKey: .purchaseOrderNumber) }
    }
}

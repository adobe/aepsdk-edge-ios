/*
 Copyright 2022 Adobe
 All Rights Reserved.
 
 NOTICE: Adobe permits you to use, modify, and distribute this file in
 accordance with the terms of the Adobe license agreement accompanying
 it.
----
 XDM Property Swift Object Generated 2020-07-17 14:52:38.218545 -0700 PDT m=+2.051983375 by XDMTool
 Title            :    PaymentsItem
 Description    :
----
*/

import Foundation


public struct PaymentsItem {
    public init() {}

    public var currencyCode: String?
    public var paymentAmount: Double?
    public var paymentType: String?
    public var transactionID: String?

    enum CodingKeys: String, CodingKey {
        case currencyCode = "currencyCode"
        case paymentAmount = "paymentAmount"
        case paymentType = "paymentType"
        case transactionID = "transactionID"
    }
}

extension PaymentsItem:Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = currencyCode { try container.encode(unwrapped, forKey: .currencyCode) }
        if let unwrapped = paymentAmount { try container.encode(unwrapped, forKey: .paymentAmount) }
        if let unwrapped = paymentType { try container.encode(unwrapped, forKey: .paymentType) }
        if let unwrapped = transactionID { try container.encode(unwrapped, forKey: .transactionID) }
    }
}

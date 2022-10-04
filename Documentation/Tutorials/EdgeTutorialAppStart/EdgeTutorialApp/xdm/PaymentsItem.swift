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

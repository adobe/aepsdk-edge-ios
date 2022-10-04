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
 XDM Property Swift Object Generated 2020-07-17 14:52:38.219533 -0700 PDT m=+2.052971413 by XDMTool
 Title            :    Checkouts
 Description    :    An action during a checkout process of a product list, there can be more than one checkout event if there are multiple steps in a checkout process. If there are multiple steps the event time information and referenced page or experience is used to identify the step individual events represent in order.
----
*/

import Foundation


public struct Checkouts {
    public init() {}

    public var id: String?
    public var value: Double?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case value = "value"
    }
}

extension Checkouts:Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = id { try container.encode(unwrapped, forKey: .id) }
        if let unwrapped = value { try container.encode(unwrapped, forKey: .value) }
    }
}

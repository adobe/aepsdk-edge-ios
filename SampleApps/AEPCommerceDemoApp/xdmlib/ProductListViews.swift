/*
 Copyright 2020 Adobe. All rights reserved.

 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.

----
 XDM Property Swift Object Generated 2020-07-17 14:52:38.218134 -0700 PDT m=+2.051572255 by XDMTool

 Title			:	ProductListViews
 Description	:	View or views of a product-list has occurred.
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

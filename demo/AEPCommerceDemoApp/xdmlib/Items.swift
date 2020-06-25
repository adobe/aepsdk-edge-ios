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
 XDM Property Swift Object Generated 2020-06-25 16:18:51.498803 -0700 PDT m=+1.941042773 by XDMTool

 Title			:	Items
 Description	:	
----
*/

import Foundation


public struct Items {
	public init() {}

	public var authenticatedState: AuthenticatedState?
	public var id: String?
	public var primary: Bool?

	enum CodingKeys: String, CodingKey {
		case authenticatedState = "authenticatedState"
		case id = "id"
		case primary = "primary"
	}	
}

extension Items:Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = authenticatedState { try container.encode(unwrapped, forKey: .authenticatedState) }
		if let unwrapped = id { try container.encode(unwrapped, forKey: .id) }
		if let unwrapped = primary { try container.encode(unwrapped, forKey: .primary) }
	}
}

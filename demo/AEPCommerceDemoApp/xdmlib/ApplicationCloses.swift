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
 XDM Property Swift Object Generated 2020-07-07 16:48:02.664073 -0700 PDT m=+1.813157231 by XDMTool

 Title			:	ApplicationCloses
 Description	:	Graceful termination of an application.
----
*/

import Foundation


public struct ApplicationCloses {
	public init() {}

	public var id: String?
	public var value: Float?

	enum CodingKeys: String, CodingKey {
		case id = "id"
		case value = "value"
	}	
}

extension ApplicationCloses:Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = id { try container.encode(unwrapped, forKey: .id) }
		if let unwrapped = value { try container.encode(unwrapped, forKey: .value) }
	}
}

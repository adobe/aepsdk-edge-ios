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
 XDM Property Swift Object Generated 2020-04-24 12:43:41.181129 -0700 PDT m=+2.099492529 by XDMTool

 Title			:	Place context
 Description	:	The transient circumstances related to the observation. Examples include locale specific information such as weather, local time, traffic, day of the week, workday vs. holiday, and working hours.
----
*/

import Foundation
import ACPExperiencePlatform

struct PlaceContext {
	public var geo: Geo?
	public var localTimezoneOffset: Int64?
	public var localTime: Date?

	enum CodingKeys: String, CodingKey {
		case geo = "geo"
		case localTimezoneOffset = "localTimezoneOffset"
		case localTime = "localTime"
	}	
}

extension PlaceContext:Encodable {
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = geo { try container.encode(unwrapped, forKey: .geo) }
		if let unwrapped = localTimezoneOffset { try container.encode(unwrapped, forKey: .localTimezoneOffset) }
		if let unwrapped = XDMFormatters.dateToISO8601String(from: localTime) { try container.encode(unwrapped, forKey: .localTime) }
	}
}

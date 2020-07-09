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
 XDM Property Swift Object Generated 2020-07-08 17:42:27.771941 -0700 PDT m=+1.895256374 by XDMTool

 Title			:	Place context
 Description	:	The transient circumstances related to the observation. Examples include locale specific information such as weather, local time, traffic, day of the week, workday vs. holiday, and working hours.
----
*/

import Foundation
import AEPExperiencePlatform

public struct PlaceContext {
	public init() {}

	public var geo: Geo?
	public var localTime: Date?
	public var localTimezoneOffset: Int64?

	enum CodingKeys: String, CodingKey {
		case geo = "geo"
		case localTime = "localTime"
		case localTimezoneOffset = "localTimezoneOffset"
	}	
}

extension PlaceContext:Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = geo { try container.encode(unwrapped, forKey: .geo) }
		if let unwrapped = XDMFormatters.dateToISO8601String(from: localTime) { try container.encode(unwrapped, forKey: .localTime) }
		if let unwrapped = localTimezoneOffset { try container.encode(unwrapped, forKey: .localTimezoneOffset) }
	}
}

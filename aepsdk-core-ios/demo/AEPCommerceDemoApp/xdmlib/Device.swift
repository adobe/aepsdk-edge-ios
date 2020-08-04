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
 XDM Property Swift Object Generated 2020-07-17 14:52:20.61629 -0700 PDT m=+2.254498513 by XDMTool

 Title			:	Device
 Description	:	An identified device, application or device browser instance that is trackable across sessions, normally by cookies.
----
*/

import Foundation


public struct Device {
	public init() {}

	public var colorDepth: Int64?
	public var manufacturer: String?
	public var modelNumber: String?
	public var model: String?
	public var screenHeight: Int64?
	public var screenOrientation: ScreenOrientation?
	public var screenWidth: Int64?
	public var type: String?
	public var typeID: String?
	public var typeIDService: String?

	enum CodingKeys: String, CodingKey {
		case colorDepth = "colorDepth"
		case manufacturer = "manufacturer"
		case modelNumber = "modelNumber"
		case model = "model"
		case screenHeight = "screenHeight"
		case screenOrientation = "screenOrientation"
		case screenWidth = "screenWidth"
		case type = "type"
		case typeID = "typeID"
		case typeIDService = "typeIDService"
	}	
}

extension Device:Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = colorDepth { try container.encode(unwrapped, forKey: .colorDepth) }
		if let unwrapped = manufacturer { try container.encode(unwrapped, forKey: .manufacturer) }
		if let unwrapped = modelNumber { try container.encode(unwrapped, forKey: .modelNumber) }
		if let unwrapped = model { try container.encode(unwrapped, forKey: .model) }
		if let unwrapped = screenHeight { try container.encode(unwrapped, forKey: .screenHeight) }
		if let unwrapped = screenOrientation { try container.encode(unwrapped, forKey: .screenOrientation) }
		if let unwrapped = screenWidth { try container.encode(unwrapped, forKey: .screenWidth) }
		if let unwrapped = type { try container.encode(unwrapped, forKey: .type) }
		if let unwrapped = typeID { try container.encode(unwrapped, forKey: .typeID) }
		if let unwrapped = typeIDService { try container.encode(unwrapped, forKey: .typeIDService) }
	}
}

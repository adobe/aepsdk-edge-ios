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
 XDM Property Swift Object Generated 2020-07-10 12:46:29.540139 -0700 PDT m=+2.255977396 by XDMTool

 Title			:	Environment
 Description	:	Information about the surrounding situation the event observation occurred in, specifically detailing transitory information such as the network or software versions.
----
*/

import Foundation


public struct Environment {
	public init() {}

	public var browserDetails: BrowserDetails?
	public var carrier: String?
	public var colorDepth: Int64?
	public var connectionType: ConnectionType?
	public var domain: String?
	public var iSP: String?
	public var ipV4: String?
	public var ipV6: String?
	public var language: String?
	public var operatingSystem: String?
	public var operatingSystemVendor: String?
	public var operatingSystemVersion: String?
	public var type: Type?
	public var viewportHeight: Int64?
	public var viewportWidth: Int64?

	enum CodingKeys: String, CodingKey {
		case browserDetails = "browserDetails"
		case carrier = "carrier"
		case colorDepth = "colorDepth"
		case connectionType = "connectionType"
		case domain = "domain"
		case iSP = "ISP"
		case ipV4 = "ipV4"
		case ipV6 = "ipV6"
		case language = "language"
		case operatingSystem = "operatingSystem"
		case operatingSystemVendor = "operatingSystemVendor"
		case operatingSystemVersion = "operatingSystemVersion"
		case type = "type"
		case viewportHeight = "viewportHeight"
		case viewportWidth = "viewportWidth"
	}	
}

extension Environment:Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = browserDetails { try container.encode(unwrapped, forKey: .browserDetails) }
		if let unwrapped = carrier { try container.encode(unwrapped, forKey: .carrier) }
		if let unwrapped = colorDepth { try container.encode(unwrapped, forKey: .colorDepth) }
		if let unwrapped = connectionType { try container.encode(unwrapped, forKey: .connectionType) }
		if let unwrapped = domain { try container.encode(unwrapped, forKey: .domain) }
		if let unwrapped = iSP { try container.encode(unwrapped, forKey: .iSP) }
		if let unwrapped = ipV4 { try container.encode(unwrapped, forKey: .ipV4) }
		if let unwrapped = ipV6 { try container.encode(unwrapped, forKey: .ipV6) }
		if let unwrapped = language { try container.encode(unwrapped, forKey: .language) }
		if let unwrapped = operatingSystem { try container.encode(unwrapped, forKey: .operatingSystem) }
		if let unwrapped = operatingSystemVendor { try container.encode(unwrapped, forKey: .operatingSystemVendor) }
		if let unwrapped = operatingSystemVersion { try container.encode(unwrapped, forKey: .operatingSystemVersion) }
		if let unwrapped = type { try container.encode(unwrapped, forKey: .type) }
		if let unwrapped = viewportHeight { try container.encode(unwrapped, forKey: .viewportHeight) }
		if let unwrapped = viewportWidth { try container.encode(unwrapped, forKey: .viewportWidth) }
	}
}

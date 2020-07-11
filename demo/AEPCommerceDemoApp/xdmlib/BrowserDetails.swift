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
 XDM Property Swift Object Generated 2020-07-10 12:46:29.537571 -0700 PDT m=+2.253409349 by XDMTool

 Title			:	Browser details
 Description	:	The browser specific details such as browser name, version, javascript version, user agent string, and accept language.
----
*/

import Foundation


public struct BrowserDetails {
	public init() {}

	public var acceptLanguage: String?
	public var cookiesEnabled: Bool?
	public var javaEnabled: Bool?
	public var javaScriptEnabled: Bool?
	public var javaScriptVersion: String?
	public var javaVersion: String?
	public var name: String?
	public var quicktimeVersion: String?
	public var thirdPartyCookiesEnabled: Bool?
	public var userAgent: String?
	public var vendor: String?
	public var version: String?
	public var viewportHeight: Int64?
	public var viewportWidth: Int64?

	enum CodingKeys: String, CodingKey {
		case acceptLanguage = "acceptLanguage"
		case cookiesEnabled = "cookiesEnabled"
		case javaEnabled = "javaEnabled"
		case javaScriptEnabled = "javaScriptEnabled"
		case javaScriptVersion = "javaScriptVersion"
		case javaVersion = "javaVersion"
		case name = "name"
		case quicktimeVersion = "quicktimeVersion"
		case thirdPartyCookiesEnabled = "thirdPartyCookiesEnabled"
		case userAgent = "userAgent"
		case vendor = "vendor"
		case version = "version"
		case viewportHeight = "viewportHeight"
		case viewportWidth = "viewportWidth"
	}	
}

extension BrowserDetails:Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = acceptLanguage { try container.encode(unwrapped, forKey: .acceptLanguage) }
		if let unwrapped = cookiesEnabled { try container.encode(unwrapped, forKey: .cookiesEnabled) }
		if let unwrapped = javaEnabled { try container.encode(unwrapped, forKey: .javaEnabled) }
		if let unwrapped = javaScriptEnabled { try container.encode(unwrapped, forKey: .javaScriptEnabled) }
		if let unwrapped = javaScriptVersion { try container.encode(unwrapped, forKey: .javaScriptVersion) }
		if let unwrapped = javaVersion { try container.encode(unwrapped, forKey: .javaVersion) }
		if let unwrapped = name { try container.encode(unwrapped, forKey: .name) }
		if let unwrapped = quicktimeVersion { try container.encode(unwrapped, forKey: .quicktimeVersion) }
		if let unwrapped = thirdPartyCookiesEnabled { try container.encode(unwrapped, forKey: .thirdPartyCookiesEnabled) }
		if let unwrapped = userAgent { try container.encode(unwrapped, forKey: .userAgent) }
		if let unwrapped = vendor { try container.encode(unwrapped, forKey: .vendor) }
		if let unwrapped = version { try container.encode(unwrapped, forKey: .version) }
		if let unwrapped = viewportHeight { try container.encode(unwrapped, forKey: .viewportHeight) }
		if let unwrapped = viewportWidth { try container.encode(unwrapped, forKey: .viewportWidth) }
	}
}

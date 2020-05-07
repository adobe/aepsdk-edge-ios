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
 XDM Property Swift Object Generated 2020-05-06 03:42:23.092468 -0700 PDT m=+1.756951121 by XDMTool

 Title			:	Application
 Description	:	This mixin is used to capture application information related to an ExperienceEvent, including the name of the application, app version, installs, launches, crashes, and closures. It could be either the application targeted by the event like the send of a push notification or the application originating the event such as a click, or a login.
----
*/

import Foundation


public struct Application {
	public init() {}

	public var applicationCloses: ApplicationCloses?
	public var crashes: Crashes?
	public var featureUsages: FeatureUsages?
	public var firstLaunches: FirstLaunches?
	public var id: String?
	public var installs: Installs?
	public var launches: Launches?
	public var name: String?
	public var upgrades: Upgrades?
	public var version: String?

	enum CodingKeys: String, CodingKey {
		case applicationCloses = "applicationCloses"
		case crashes = "crashes"
		case featureUsages = "featureUsages"
		case firstLaunches = "firstLaunches"
		case id = "id"
		case installs = "installs"
		case launches = "launches"
		case name = "name"
		case upgrades = "upgrades"
		case version = "version"
	}	
}

extension Application:Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = applicationCloses { try container.encode(unwrapped, forKey: .applicationCloses) }
		if let unwrapped = crashes { try container.encode(unwrapped, forKey: .crashes) }
		if let unwrapped = featureUsages { try container.encode(unwrapped, forKey: .featureUsages) }
		if let unwrapped = firstLaunches { try container.encode(unwrapped, forKey: .firstLaunches) }
		if let unwrapped = id { try container.encode(unwrapped, forKey: .id) }
		if let unwrapped = installs { try container.encode(unwrapped, forKey: .installs) }
		if let unwrapped = launches { try container.encode(unwrapped, forKey: .launches) }
		if let unwrapped = name { try container.encode(unwrapped, forKey: .name) }
		if let unwrapped = upgrades { try container.encode(unwrapped, forKey: .upgrades) }
		if let unwrapped = version { try container.encode(unwrapped, forKey: .version) }
	}
}

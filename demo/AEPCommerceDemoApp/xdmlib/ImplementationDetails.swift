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
 XDM Property Swift Object Generated 2020-06-25 16:18:51.497141 -0700 PDT m=+1.939381139 by XDMTool

 Title			:	Implementation details
 Description	:	The details of the software used to collect the ExperienceEvent.
----
*/

import Foundation


public struct ImplementationDetails {
	public init() {}

	public var environment: Environment?
	public var name: String?
	public var version: String?

	enum CodingKeys: String, CodingKey {
		case environment = "environment"
		case name = "name"
		case version = "version"
	}	
}

extension ImplementationDetails:Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = environment { try container.encode(unwrapped, forKey: .environment) }
		if let unwrapped = name { try container.encode(unwrapped, forKey: .name) }
		if let unwrapped = version { try container.encode(unwrapped, forKey: .version) }
	}
}

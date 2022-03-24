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
 XDM Schema Swift Object Generated 2020-07-17 14:52:20.614883 -0700 PDT m=+2.253090988 by XDMTool

 Title			:	Mobile SDK Lifecycle Schema
 Version		:	1.1
 Description	:	
 Type			:	schemas
----
*/

import Foundation
import AEPEdge

public struct MobileSDKLifecycleSchema : XDMSchema {
	public let schemaVersion = "1.1"
	public let schemaIdentifier = ""
	public let datasetIdentifier = ""
	
	public init() {}

	public var application: Application?
	public var device: Device?
	public var environment: Environment?
	public var eventMergeId: String?
	public var eventType: String?
	public var identityMap: IdentityMap?
	public var placeContext: PlaceContext?
	public var timestamp: Date?

	enum CodingKeys: String, CodingKey {
		case application = "application"
		case device = "device"
		case environment = "environment"
		case eventMergeId = "eventMergeId"
		case eventType = "eventType"
		case identityMap = "identityMap"
		case placeContext = "placeContext"
		case timestamp = "timestamp"
	}	
}

extension MobileSDKLifecycleSchema {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = application { try container.encode(unwrapped, forKey: .application) }
		if let unwrapped = device { try container.encode(unwrapped, forKey: .device) }
		if let unwrapped = environment { try container.encode(unwrapped, forKey: .environment) }
		if let unwrapped = eventMergeId { try container.encode(unwrapped, forKey: .eventMergeId) }
		if let unwrapped = eventType { try container.encode(unwrapped, forKey: .eventType) }
		if let unwrapped = identityMap { try container.encode(unwrapped, forKey: .identityMap) }
		if let unwrapped = placeContext { try container.encode(unwrapped, forKey: .placeContext) }
        if let unwrapped = timestamp?.getISO8601UTCDateWithMilliseconds() { try container.encode(unwrapped, forKey: .timestamp) }
	}
}

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
 ID				:	https://ns.adobe.com/acopprod3/schemas/711b0b9afc7162017bfe022cda7af34a15232797b4a69107
 Alt ID			:	_acopprod3.schemas.711b0b9afc7162017bfe022cda7af34a15232797b4a69107
 Type			:	schemas
 IMS Org		:	FAF554945B90342F0A495E2C@AdobeOrg
----
*/

import Foundation
import AEPExperiencePlatform

public struct MobileSDKLifecycleSchema : XDMSchema {
	public let schemaVersion = "1.1"
	public let schemaIdentifier = "https://ns.adobe.com/acopprod3/schemas/711b0b9afc7162017bfe022cda7af34a15232797b4a69107"
	public let datasetIdentifier = "5f05094a112ea71914bd169c"
	
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
		if let unwrapped = XDMFormatters.dateToISO8601String(from: timestamp) { try container.encode(unwrapped, forKey: .timestamp) }
	}
}

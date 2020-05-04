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
 XDM Schema Swift Object Generated 2020-05-04 09:37:54.458155 -0700 PDT m=+1.682073884 by XDMTool

 Title			:	Mobile SDK Platform Event Schema
 Version		:	1.4
 Description	:	Platform Event Schema used by Mobile SDK
 ID				:	https://ns.adobe.com/acopprod1/schemas/e1af53c26439f963fbfebe50330323ae
 Alt ID			:	_acopprod1.schemas.e1af53c26439f963fbfebe50330323ae
 Type			:	schemas
 IMS Org		:	3E2A28175B8ED3720A495E23@AdobeOrg
----
*/

import Foundation

struct MobileSDKPlatformEventSchema : XDMSchema {
	public let schemaVersion = "1.4"
	public let schemaIdentifier = "https://ns.adobe.com/acopprod1/schemas/e1af53c26439f963fbfebe50330323ae"
	public let datasetIdentifier = "5dd603781b95cc18a83d42ce"

	public var application: Application?
	public var commerce: Commerce?
	public var device: Device?
	public var environment: Environment?
	public var eventMergeId: String?
	public var eventType: String?
	public var identityMap: IdentityMap?
	public var placeContext: PlaceContext?
	public var productListItems: Array<ProductListItemsItem?>?
	public var timestamp: Date?

	enum CodingKeys: String, CodingKey {
		case application = "application"
		case commerce = "commerce"
		case device = "device"
		case environment = "environment"
		case eventMergeId = "eventMergeId"
		case eventType = "eventType"
		case identityMap = "identityMap"
		case placeContext = "placeContext"
		case productListItems = "productListItems"
		case timestamp = "timestamp"
	}	
}

extension MobileSDKPlatformEventSchema {
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = application { try container.encode(unwrapped, forKey: .application) }
		if let unwrapped = commerce { try container.encode(unwrapped, forKey: .commerce) }
		if let unwrapped = device { try container.encode(unwrapped, forKey: .device) }
		if let unwrapped = environment { try container.encode(unwrapped, forKey: .environment) }
		if let unwrapped = eventMergeId { try container.encode(unwrapped, forKey: .eventMergeId) }
		if let unwrapped = eventType { try container.encode(unwrapped, forKey: .eventType) }
		if let unwrapped = identityMap { try container.encode(unwrapped, forKey: .identityMap) }
		if let unwrapped = placeContext { try container.encode(unwrapped, forKey: .placeContext) }
		if let unwrapped = productListItems { try container.encode(unwrapped, forKey: .productListItems) }
		if let unwrapped = XDMFormatters.dateToISO8601String(from: timestamp) { try container.encode(unwrapped, forKey: .timestamp) }
	}
}

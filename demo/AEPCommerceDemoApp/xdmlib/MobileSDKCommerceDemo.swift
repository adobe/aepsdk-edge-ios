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
 XDM Schema Swift Object Generated 2020-06-25 16:18:51.496212 -0700 PDT m=+1.938452303 by XDMTool

 Title			:	Mobile SDK Commerce Demo
 Version		:	1.0
 Description	:	Schema used by Mobile SDK Commerce Demo application
 ID				:	https://ns.adobe.com/acopprod3/schemas/3391dbaead444a0ee50b27c864f62a5899ee4c3e54c3992d
 Alt ID			:	_acopprod3.schemas.3391dbaead444a0ee50b27c864f62a5899ee4c3e54c3992d
 Type			:	schemas
 IMS Org		:	FAF554945B90342F0A495E2C@AdobeOrg
----
*/

import Foundation
import AEPExperiencePlatform

public struct MobileSDKCommerceDemo : XDMSchema {
	public let schemaVersion = "1.0"
	public let schemaIdentifier = "https://ns.adobe.com/acopprod3/schemas/3391dbaead444a0ee50b27c864f62a5899ee4c3e54c3992d"
	public let datasetIdentifier = "5ef40faffdf5591915bdb967"
	
	public init() {}

	public var application: Application?
	public var commerce: Commerce?
	public var device: Device?
	public var environment: Environment?
	public var eventMergeId: String?
	public var eventType: String?
	public var identityMap: IdentityMap?
	public var implementationDetails: ImplementationDetails?
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
		case implementationDetails = "implementationDetails"
		case placeContext = "placeContext"
		case productListItems = "productListItems"
		case timestamp = "timestamp"
	}	
}

extension MobileSDKCommerceDemo {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = application { try container.encode(unwrapped, forKey: .application) }
		if let unwrapped = commerce { try container.encode(unwrapped, forKey: .commerce) }
		if let unwrapped = device { try container.encode(unwrapped, forKey: .device) }
		if let unwrapped = environment { try container.encode(unwrapped, forKey: .environment) }
		if let unwrapped = eventMergeId { try container.encode(unwrapped, forKey: .eventMergeId) }
		if let unwrapped = eventType { try container.encode(unwrapped, forKey: .eventType) }
		if let unwrapped = identityMap { try container.encode(unwrapped, forKey: .identityMap) }
		if let unwrapped = implementationDetails { try container.encode(unwrapped, forKey: .implementationDetails) }
		if let unwrapped = placeContext { try container.encode(unwrapped, forKey: .placeContext) }
		if let unwrapped = productListItems { try container.encode(unwrapped, forKey: .productListItems) }
		if let unwrapped = XDMFormatters.dateToISO8601String(from: timestamp) { try container.encode(unwrapped, forKey: .timestamp) }
	}
}

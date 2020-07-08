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
 XDM Schema Swift Object Generated 2020-07-07 16:48:35.827903 -0700 PDT m=+1.826015255 by XDMTool

 Title			:	Mobile SDK Commerce Schema
 Version		:	1.0
 Description	:	
 ID				:	https://ns.adobe.com/acopprod3/schemas/95f430276fa51f45c81234aadc64f4e00dad6753d659345a
 Alt ID			:	_acopprod3.schemas.95f430276fa51f45c81234aadc64f4e00dad6753d659345a
 Type			:	schemas
 IMS Org		:	FAF554945B90342F0A495E2C@AdobeOrg
----
*/

import Foundation
import AEPExperiencePlatform

public struct MobileSDKCommerceSchema : XDMSchema {
	public let schemaVersion = "1.0"
	public let schemaIdentifier = "https://ns.adobe.com/acopprod3/schemas/95f430276fa51f45c81234aadc64f4e00dad6753d659345a"
	public let datasetIdentifier = "5f05095dba13bf191536d178"
	
	public init() {}

	public var commerce: Commerce?
	public var eventMergeId: String?
	public var eventType: String?
	public var identityMap: IdentityMap?
	public var productListItems: Array<ProductListItemsItem?>?
	public var timestamp: Date?

	enum CodingKeys: String, CodingKey {
		case commerce = "commerce"
		case eventMergeId = "eventMergeId"
		case eventType = "eventType"
		case identityMap = "identityMap"
		case productListItems = "productListItems"
		case timestamp = "timestamp"
	}	
}

extension MobileSDKCommerceSchema {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = commerce { try container.encode(unwrapped, forKey: .commerce) }
		if let unwrapped = eventMergeId { try container.encode(unwrapped, forKey: .eventMergeId) }
		if let unwrapped = eventType { try container.encode(unwrapped, forKey: .eventType) }
		if let unwrapped = identityMap { try container.encode(unwrapped, forKey: .identityMap) }
		if let unwrapped = productListItems { try container.encode(unwrapped, forKey: .productListItems) }
		if let unwrapped = XDMFormatters.dateToISO8601String(from: timestamp) { try container.encode(unwrapped, forKey: .timestamp) }
	}
}

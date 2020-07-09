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
 XDM Property Swift Object Generated 2020-07-08 17:42:27.772138 -0700 PDT m=+1.895453286 by XDMTool

 Title			:	Geo
 Description	:	The geographic location where the experience was delivered.
----
*/

import Foundation


public struct Geo {
	public init() {}

	public var city: String?
	public var countryCode: String?
	public var description_: String?
	public var dmaID: Int64?
	public var elevation: Float?
	public var latitude: Float?
	public var longitude: Float?
	public var msaID: Int64?
	public var postalCode: String?
	public var stateProvince: String?

	enum CodingKeys: String, CodingKey {
		case city = "city"
		case countryCode = "countryCode"
		case description_ = "description"
		case dmaID = "dmaID"
		case elevation = "elevation"
		case latitude = "latitude"
		case longitude = "longitude"
		case msaID = "msaID"
		case postalCode = "postalCode"
		case stateProvince = "stateProvince"
	}	
}

extension Geo:Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		if let unwrapped = city { try container.encode(unwrapped, forKey: .city) }
		if let unwrapped = countryCode { try container.encode(unwrapped, forKey: .countryCode) }
		if let unwrapped = description_ { try container.encode(unwrapped, forKey: .description_) }
		if let unwrapped = dmaID { try container.encode(unwrapped, forKey: .dmaID) }
		if let unwrapped = elevation { try container.encode(unwrapped, forKey: .elevation) }
		if let unwrapped = latitude { try container.encode(unwrapped, forKey: .latitude) }
		if let unwrapped = longitude { try container.encode(unwrapped, forKey: .longitude) }
		if let unwrapped = msaID { try container.encode(unwrapped, forKey: .msaID) }
		if let unwrapped = postalCode { try container.encode(unwrapped, forKey: .postalCode) }
		if let unwrapped = stateProvince { try container.encode(unwrapped, forKey: .stateProvince) }
	}
}

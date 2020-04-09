//
// ADOBE CONFIDENTIAL
//
// Copyright 2020 Adobe
// All Rights Reserved.
//
// NOTICE: All information contained herein is, and remains
// the property of Adobe and its suppliers, if any. The intellectual
// and technical concepts contained herein are proprietary to Adobe
// and its suppliers and are protected by all applicable intellectual
// property laws, including trade secret and copyright laws.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from Adobe.
//


import Foundation

struct EdgeRequest {
    /// Metadata passed to solutions and even to Konductor itself with possiblity of overriding at event level
    var meta: RequestMetadata?
    
    /// XDM context data for the entire request
    var xdm: RequestContext?
    
    /// List of Events
    var events: [[AnyHashable : AnyCodable]]?
    
    // TODO handle Events list
    
    enum CodingKeys: String, CodingKey {
        case meta = "meta"
        case events = "events"
        case xdm = "xdm"
    }
}

extension EdgeRequest : Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = meta { try container.encode(unwrapped, forKey: .meta)}
        if let unwrapped = xdm { try container.encode(unwrapped, forKey: .xdm)}
        if let unwrapped = events as? [[String:AnyCodable]] { try container.encode(unwrapped, forKey: .events)}
    }
}

extension EdgeRequest : Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        meta = try? container.decode(RequestMetadata.self, forKey: .meta)
        xdm = try? container.decode(RequestContext.self, forKey: .xdm)
        events = try? container.decode([[String:AnyCodable]].self, forKey: .events)
    }
}

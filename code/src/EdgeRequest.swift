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

/// A request for pushing events to the Adobe Data Platform.
/// An `EdgeRequest` is the top-level request object sent to Konductor.
struct EdgeRequest : Codable{
    /// Metadata passed to solutions and even to Konductor itself with possiblity of overriding at event level
    var meta: RequestMetadata?
    
    /// XDM context data for the entire request
    var xdm: RequestContextData?
    
    /// List of Experience events
    var events: [[String : AnyCodable]]?
}

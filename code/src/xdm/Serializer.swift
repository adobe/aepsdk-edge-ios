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

class Serializer {
    
    private init() {
        
    }
    
    private  let TIMESTAMP_FORMAT: String = "yyyy-MM-dd'T'HH:mm:ssXXX"
    private  let DATE_FORMAT: String = "yyyy-MM-dd"
    
    /// Serialize a list of Property elements to a list of XDM formatted maps.
    /// Calls Property.serializeToXdm()} on each element in the list.
    /// - Parameters:
    ///   -  listProperty: list of Property elements
    /// - Returns: a list of Property elements serialized to XDM map structure
    func serializeFromList(listProperty: [Property]) -> [[String: Any]] {
        
        return listProperty.map({$0.serializeToXdm()})
    }

    /// Serialize the given Date to a string formatted to an ISO 8601 date-time as defined in
    /// <a href="https://tools.ietf.org/html/rfc3339#section-5.6">RFC 3339, section 5.6</a>
    /// For example, 2017-09-26T15:52:25-07:00
    /// - Parameters:
    ///   - timestamp: A timestamp
    /// - Returns: The timestamp formatted to a string in the format of 'yyyy-MM-dd'T'HH:mm:ssXXX',
    /// or an empty string if {@code timestamp} is null
    func serializeToISO8601String(timestamp: Date?) -> String {
        
        guard let unwrappedTimestamp = timestamp else { return "" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = TIMESTAMP_FORMAT
        return dateFormatter.string(from: unwrappedTimestamp)
    }

    /// Serialize the given Date to a string formatted to an ISO 8601 date without time as defined in
    /// <a href="https://tools.ietf.org/html/rfc3339#section-5.6">RFC 3339, section 5.6</a>
    /// For example, 2017-09-26
    /// - Parameters:
    ///   - date: A date
    /// - Returns: The timestamp formatted to a string in the format of 'yyyy-MM-dd',
    /// or an empty string if the date is null
   func serializeToShortDateString(timestamp: Date?) -> String {
       
       guard let unwrappedTimestamp = timestamp else { return "" }
       let dateFormatter = DateFormatter()
       dateFormatter.dateFormat = DATE_FORMAT
       return dateFormatter.string(from: unwrappedTimestamp)
   }

}

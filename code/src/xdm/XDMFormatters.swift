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

class XDMFormatters {

    /// Serialize the given Date to a string formatted to an ISO 8601 date-time as defined in
    /// <a href="https://tools.ietf.org/html/rfc3339#section-5.6">RFC 3339, section 5.6</a>
    /// For example, 2017-09-26T15:52:25-07:00
    /// - Parameters:
    ///   - Date: A timestamp and it must not be null
    /// - Returns: The timestamp formatted to a string in the format of 'yyyy-MM-dd'T'HH:mm:ssXXX',
    ///            or an empty string if Date  is null
    public static func dateToISO8601String(from: Date?) -> String? {
        if let unwrapped = from {
            return unwrapped.asISO8601String()
        } else {
            return ""
        }
    }
    
    /// Serialize the given Date to a string formatted to an ISO 8601 date as defined in
    /// <a href="https://tools.ietf.org/html/rfc3339#section-5.6">RFC 3339, section 5.6</a>
    /// For example, 2017-09-26
    /// - Parameters:
    ///   - Date:  A timestamp and it must not be null
    /// - Returns: The timestamp formatted to a string in the format of 'yyyy-MM-dd',
    ///            or an empty string if Date  is null
    public static func dateToFullDateString(from: Date?) -> String? {
        if let unwrapped = from {
            return unwrapped.asFullDate()
        } else {
            return ""
        }
    }
}

private extension Date {
    func asISO8601String() -> String {
        return ISO8601DateFormatter().string(from: self)
    }
    
    func asFullDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter.string(from: self)
    }
}

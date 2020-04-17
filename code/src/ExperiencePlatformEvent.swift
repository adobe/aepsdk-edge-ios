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

public struct ExperiencePlatformEvent {
    private let LOG_TAG = "ExperiencePlatformEvent"

    private var xdmData: [String: AnyCodable]
    private var data: [String: AnyCodable]?

    init(xdmData: [String: Any], data: [String: Any]?) {
        self.xdmData = AnyCodable.from(dictionary: xdmData)
        self.data = AnyCodable.from(dictionary: data!)
    }

    init(xdmData: XDMSchema, data: [String : Any]?) {
        self.xdmData = AnyCodable.from(dictionary: xdmData as! [AnyHashable : Any])
        self.data = AnyCodable.from(dictionary: data!)
    }
    
    /// Returns the solution specific XDM event data for this event.
    /// - Returns:The XDM schema data
    func getXdmData() -> [String: AnyCodable]{
        return self.xdmData
      }

    /// Returns the free form data associated with this event
    /// - Returns:Free form data in JSON format
    func getData() -> [String: AnyCodable]{
        return self.data!
    }
    
}


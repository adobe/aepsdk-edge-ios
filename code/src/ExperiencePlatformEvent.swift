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

     private let freeFormData: [String: AnyCodable]
     private let xdmData: [String: AnyCodable]
    
     init(data: [String: Any], xdmData: [String: Any]) {
         self.freeFormData =  AnyCodable.from(dictionary: data)
         self.xdmData = AnyCodable.from(dictionary: xdmData)
    }
    
    init(xdmData: [String : Any], data: [String : Any]? = nil) {
        self.freeFormData = [:]
        self.xdmData = AnyCodable.from(dictionary: xdmData)
    }
    
    init(xdmData: [String : Any]? = nil, data: [String : Any]) {
        self.freeFormData = AnyCodable.from(dictionary: data)
        self.xdmData = [:]
    }
    
    /// Returns the free form data associated with this event
    /// - Returns:Free form data in JSON format
    func getFreeFormData() -> [String: Any]{
        return self.freeFormData
    }
    
    /// Returns the solution specific XDM event data for this event.
    /// - Returns:The XDM schema data
    func getXdmData() -> [String: Any]{
        return self.xdmData
      }
}


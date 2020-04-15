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

     private var data: [String: Any]
     private var xdmData: [String: Any]
    
    public init(data: [String: Any], xdmData: [String: Any] ) {
        self.data = data
        self.xdmData = xdmData
    }
    
    /// Sets a free form data associated with this event to be passed to Adobe Data Platform
    /// - Parameters:
    ///   -  data: Free form data, JSON like types are accepted
    mutating func setData(data: [String: Any])  {
        self.data = data
    }
    
    /// Sets the solution specific XDM event data for this event.
    /// If XDM schema is set multiple times using either this API
    /// - Parameters:
    ///   -  xdm: Schema information
   mutating func setXdmSchema(xdm: Schema) {
        self.xdmData = xdm.serializeToXdm()
      }
    
    /// Sets solution specific XDM event data for this event, passed as raw mapping of keys and
    /// Object values.
    /// If XDM schema is set multiple times using either this API or the value will be overwritten
    /// and only the last changes are applied.
    /// - Parameters:
    ///   -  xdm: Raw XDM schema data
    mutating func setXdmSchema(xdm: [String: Any]) {
        self.xdmData = xdm
      }

    /// Returns the free form data associated with this event
    /// - Returns:Free form data in JSON format
    func getData() -> [String: Any]{
        return self.data
    }
    
    /// Returns the solution specific XDM event data for this event.
    /// - Returns:The XDM schema data
    func getXdmData() -> [String: Any]{
        return self.xdmData
      }
}


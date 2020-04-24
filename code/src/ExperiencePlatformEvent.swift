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

    public var xdmData: [String: Any]?
    public var data: [String: Any]?

    init(xdmData: [String: Any], data: [String: Any]?) {
        self.xdmData = xdmData
        self.data = data
    }

//    To be updated / implemented after the updated implentation for XDMSchema has been checked-in
//    init(xdmData: XDMSchema, data: [String : Any]?) {
//          do {
//              let xdmdata = try JSONEncoder().encode(xdmData)
//                if let xdmDict = try JSONSerialization.jsonObject(with: xdmdata, options: []) as? [String: Any] {
//                self.xdmData = xdmDict
//              } else {
//                // log failed to serialize JSON data error
//            }
//
//        } catch {
//            // log thrown error
//        }
//         self.data = AnyCodable.from(dictionary: data!)
//    }
    
    internal func asDictionary() -> [String : Any]? {
         var dataDict: [String : Any] = [:]
        
         if let xdm = xdmData {
              dataDict["xdm"] = xdm
         }
         if let data = data {
             dataDict["data"] = data
        }
       
        return dataDict.isEmpty ? nil : dataDict
    }
    
    
    /// Returns the solution specific XDM event data for this event.
    /// - Returns:The XDM schema data
    func getXdmData() -> [String: Any]{

        guard let xdmdata = self.xdmData else {
            return [:]
        }
        return xdmdata
      }

    /// Returns the free form data associated with this event
    /// - Returns:Free form data in JSON format
    func getData() -> [String: Any]{
        
        guard let data = self.data else {
            return [:]
        }
        return data
    }
}

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

    public var xdmData: [String: Any]
    public var data: [String: Any]

    internal func asDictionary() -> [String : Any]? {
         var dataDict: [String : Any] = [:]
              dataDict["xdm"] = xdmData
             dataDict["data"] = data
        return dataDict.isEmpty ? nil : dataDict
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

    
}

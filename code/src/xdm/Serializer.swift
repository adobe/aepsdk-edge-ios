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
    
    func serializeFromList(listProperty: [Property]) -> [[String: Any]] {
        
        var serializedList:[[String: Any]] = [[String: Any]]()
        
        for property in listProperty {
            serializedList.append(property.serializeToXdm())
        }
        return serializedList
    }

    func serializeToISO8601String(timestamp: Date?) -> String {
        
        if timestamp == nil {
            return ""
         }
 
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = TIMESTAMP_FORMAT
        return dateFormatter.string(from: timestamp!)
        
    }

       func serializeToShortDateString(timestamp: Date?) -> String {
           
           if timestamp == nil {
               return ""
            }
    
           let dateFormatter = DateFormatter()
           dateFormatter.dateFormat = DATE_FORMAT
           return dateFormatter.string(from: timestamp!)
           
       }

}

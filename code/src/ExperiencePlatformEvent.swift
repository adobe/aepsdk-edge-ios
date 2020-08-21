//
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import Foundation

@objc(AEPExperiencePlatformEvent)
public class ExperiencePlatformEvent: NSObject {

    private let logTag = "ExperiencePlatformEvent"

    /// XDM formatted data, use an `XDMSchema` implementation for a better XDM data injestion and format control
    public let xdm: [String: Any]?

    /// Optional free-form data associated with this event
    public let data: [String: Any]?

    /// Adobe Data Platform dataset identifier, if not set the default dataset identifier set in the Blackbird configuration is used
    public let datasetIdentifier: String?

    /// Initialize an Experience Platform Event with the provided event data
    /// - Parameters:
    ///   - xdm:  Solution specific XDM event data for this event, passed as a raw XDM Schema data dictionary.
    ///   - data: Any free form data in a [String : Any] dictionary structure.
    ///   - datasetIdentifier: The Data Platform dataset identifier where this event should be sent to; if not provided, the default dataset identifier set in the Blackbird configuration is used
    public init(xdm: [String: Any], data: [String: Any]? = nil, datasetIdentifier: String? = nil) {
        self.xdm = xdm
        self.data = data
        self.datasetIdentifier = datasetIdentifier
    }

    /// Initialize an Experience Platform Event with the provided event data
    /// - Parameters:
    ///   - xdm: Solution specific XDM event data pased as an XDMSchema
    ///   - data: Any free form data in a [String : Any] dictionary structure.
    public init(xdm: XDMSchema, data: [String: Any]? = nil) {
        if let jsonXdm = xdm.toJSONData() {
            self.xdm = try? JSONSerialization.jsonObject(with: jsonXdm, options: []) as? [String: Any]
        } else {
            self.xdm = nil
        }
        self.data = data
        self.datasetIdentifier = xdm.datasetIdentifier
    }

    internal func asDictionary() -> [String: Any]? {
        var dataDict: [String: Any] = [:]
        if let unwrappedXdm = xdm {
            dataDict = [ExperiencePlatformConstants.JsonKeys.xdm: unwrappedXdm as Any]
        }
        if let unwrappedData = data {
            dataDict[ExperiencePlatformConstants.JsonKeys.data] = unwrappedData
        }

        if let unwrappedDatasetId = datasetIdentifier {
            dataDict[ExperiencePlatformConstants.EventDataKeys.datasetId] = unwrappedDatasetId
        }
        return dataDict.isEmpty ? nil : dataDict
    }
}

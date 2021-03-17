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

@objc(AEPExperienceEvent)
public class ExperienceEvent: NSObject {

    /// XDM formatted data, use an `XDMSchema` implementation for a better XDM data injestion and format control
    @objc public let xdm: [String: Any]?

    /// Optional free-form data associated with this event
    @objc public let data: [String: Any]?

    /// Optional free-form query data associated with this event
    @objc public var query: [String: Any]?

    /// Adobe Experience Platform dataset identifier, if not set the default dataset identifier set in the Edge Configuration is used
    @objc public let datasetIdentifier: String?

    /// Initialize an Experience Event with the provided event data
    /// - Parameters:
    ///   - xdm:  XDM formatted data for this event, passed as a raw XDM Schema data dictionary.
    ///   - data: Any free form data in a [String : Any] dictionary structure.
    ///   - datasetIdentifier: The Experience Platform dataset identifier where this event should be sent to; if not provided, the default dataset identifier set in the Edge configuration is used
    @objc public init(xdm: [String: Any], data: [String: Any]? = nil, datasetIdentifier: String? = nil) {
        self.xdm = xdm
        self.data = data
        self.datasetIdentifier = datasetIdentifier
    }

    /// Initialize an Experience Event with the provided event data
    /// - Parameters:
    ///   - xdm: XDM formatted event data passed as an XDMSchema
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
            dataDict = [EdgeConstants.JsonKeys.XDM: unwrappedXdm as Any]
        }
        if let unwrappedData = data {
            dataDict[EdgeConstants.JsonKeys.DATA] = unwrappedData
        }

        if let query = query, !query.isEmpty {
            dataDict[EdgeConstants.JsonKeys.QUERY] = query
        }

        if let unwrappedDatasetId = datasetIdentifier {
            dataDict[EdgeConstants.EventDataKeys.DATASET_ID] = unwrappedDatasetId
        }
        return dataDict.isEmpty ? nil : dataDict
    }
}

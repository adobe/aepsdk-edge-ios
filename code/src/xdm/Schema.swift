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

/// An interface representing a Platform XDM Event Data schema.
public protocol Schema {
    
    /// Returns the version of this schema as defined in the Adobe Experience Platform.
    /// - Returns: The version of this schema
    func getSchemaVersion() -> String
    
    /// Returns the identifier for this schema as defined in the Adobe Experience Platform.
    /// The identifier is a URI where this schema is defined.
    /// - Returns: The URI identifier for this schema
    func getSchemaIdentifier() -> String
    
    /// Returns the identifier for this dataset as defined in the Adobe Experience Platform.
    /// The identifier is a URI where this dataset is defined.
    /// - Returns: The URI identifier for this dataset
    func getDatasetIdentifier() -> String
}

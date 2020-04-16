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

/// The XDM property contains the attribures of data such as time stamp, device ID, IP, or MAC address,
/// or other potentially user-identifying values are incorporated in the generation of the xdm
/// The values should be hashed, so that no PII is encoded in the value, as the goal is not to identify
/// user or device, but the specific measure in time.

public protocol Property {
    
    /// Serialize the given object to a map equivalent of its XDM schema.
    /// - Returns: XDM formatted map of the given Property object
    
    func serializeToXdm() -> [String: Any]
    
}

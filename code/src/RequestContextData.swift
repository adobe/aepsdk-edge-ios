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

/// Property that holds the global XDM context data within an Edge Request object.
/// Is contained within the `EdgeRequest` request property.
struct RequestContextData : Encodable {
    let identityMap: IdentityMap?
    let environment: EnvironmentData?
    let device: DeviceData?
}

/// Property that holds the Environment information in XDM format
struct EnvironmentData : Encodable {
    let operatingSystem: String?
    let operatingSystemVersion: String?
    let operatingSystemVendor: String?
}

/// Property that holds the Device information in XDM format
struct DeviceData: Encodable {
    let manufacturer: String?
    let model: String?
    let modelNumber: String?
    let screenHeight: Int?
    let screenWidth: Int?
    let screenOrientation: String?
    let type: String?
    let colorDepth: String?
}

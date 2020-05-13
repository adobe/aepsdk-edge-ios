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

/// Protocol that can be implemented in order to receive response(s) from the Adobe Experience Edge in the mobile application when
/// `ExperiencePlatformEvent`s are sent through the `ACPExperiencePlatform`.
public protocol ExperiencePlatformResponseHandler {
    
    /// This method is called when the response was successfully fetched from the Adobe Experience Edge for an associated event;
    /// this method may be call multiple times for the same event, based on the data coming from the server.
    /// - Parameter data: response from the server
    func onResponse(data: [String: Any])
}

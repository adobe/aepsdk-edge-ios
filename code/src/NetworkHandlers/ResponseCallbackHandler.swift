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

/// Use this class to register `ExperiencePlatformCallback`(s) for a specific event identifier
/// and get notified once a response is received from the Experience Edge or when an error occurred
class ResponseCallbackHandler {
    static let shared = ResponseCallbackHandler()
    
    func registerCallback(uniqueEventId: String) {
        // todo AMSDK-9555
    }
    
    func unregisterCallback(uniqueEventId: String) {
        // todo AMSDK-9555
    }
    
    func invokeResponseCallback(eventData: [String: Any]) {
        // todo AMSDK-9555
    }
}

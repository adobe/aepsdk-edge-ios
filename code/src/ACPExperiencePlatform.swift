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

import ACPCore

public class ACPExperiencePlatform {
    @available(*, unavailable) private init() {}
    
    public static func registerExtension() {
        try? ACPCore.registerExtension(ExperiencePlatformInternal.self)
    }
    
    public static func extensionVersion() -> String {
        // TODO: implement me
        return "1.0.0-alpha"
    }
    
    /// For test purposes only - will remove once the public API changes are migrated to github
    public static func dispatchData(eventData: [String:Any], responseHandler: ExperiencePlatformResponseHandler? = nil) {
        guard let event = try? ACPExtensionEvent(name: "Add event for Data Platform", type: ExperiencePlatformConstants.eventTypeExperiencePlatform, source: ExperiencePlatformConstants.eventSourceExtensionRequestContent, data: eventData) else {
            return
        }
        
        ResponseCallbackHandler.shared.registerResponseHandler(uniqueEventId: event.eventUniqueIdentifier, responseHandler: responseHandler)
        try? ACPCore.dispatchEvent(event)
    }
}

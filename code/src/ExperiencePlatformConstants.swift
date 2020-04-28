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

struct ExperiencePlatformConstants {
    private init() {}
    
    static let eventTypeExperiencePlatform: String = "com.adobe.eventType.experiencePlatform"
    static let eventTypeAdobeHub: String = "com.adobe.eventType.hub"

    static let eventSourceAdobeSharedState: String = "com.adobe.eventSource.sharedState"
    static let eventSourceExtensionRequestContent: String = "com.adobe.eventSource.requestContent"
    static let eventSourceExtensionResponseContent: String = "com.adobe.eventSource.responseContent"
    static let eventSourceExtensionErrorResponseContent: String = "com.adobe.eventSource.errorResponseContent"
    
    static let platformDataStorage: String = "PlatformExtensionDataStorage"
    
    struct Defaults {
        private init() {}
        
        static let networkRequestMaxRetries: Int = 5
        
        static let requestConfigRecordSeparator = "\u{0000}"
        static let requestConfigLineFeed = "\n"
    }

    struct DataStoreKeys {
        private init() {}
        
        static let storeName: String = "ACPExperiencePlatform"
        static let storePayloads: String = "storePayloads"
    }
    
    struct SharedState {
        private init() {}
        
        static let stateowner: String = "stateowner"
        
        struct Configuration {
            private init() {}
            
            static let stateOwner = "com.adobe.module.configuration"
            static let experiencePlatformConfigId: String = "experiencePlatform.configId"
            static let experienceCloudOrgId: String = "experienceCloud.org"
        }
        
        struct Identity {
            private init() {}
            
            static let stateOwner = "com.adobe.mobile.identity"
            static let ecid = "mid"
        }
        
        struct Lifecycle {
            private init() {}
            
            static let stateOwner = "com.adobe.mobile.lifecycle"
        }
    }
    
    struct JsonKeys {
        private init() {}
        
        static let xdm = "xdm"
        static let ECID = "ECID"
        static let timestamp = "timestamp"
        static let eventId = "eventId"
    }
}

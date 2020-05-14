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
    
    static let eventTypeExperiencePlatform = "com.adobe.eventType.experiencePlatform"
    static let eventTypeAdobeHub = "com.adobe.eventType.hub"

    static let eventSourceAdobeSharedState = "com.adobe.eventSource.sharedState"
    static let eventSourceExtensionRequestContent = "com.adobe.eventSource.requestContent"
    static let eventSourceExtensionResponseContent = "com.adobe.eventSource.responseContent"
    static let eventSourceExtensionErrorResponseContent = "com.adobe.eventSource.errorResponseContent"
    
    static let platformDataStorage = "PlatformExtensionDataStorage"
    
    struct Defaults {
        private init() {}
        
        static let networkRequestMaxRetries: UInt = 5
        static let requestConfigRecordSeparator: String = "\u{0000}"
        static let requestConfigLineFeed: String = "\n"
    }

    struct EventDataKeys {
        private init() {}
        
        static let edgeRequesId = "requestId"
        static let requestEventId = "requestEventId"
    }
    
    struct DataStoreKeys {
        private init() {}
        
        static let storeName = "ACPExperiencePlatform"
        static let storePayloads = "storePayloads"
    }
    
    struct SharedState {
        private init() {}
        
        static let stateowner = "stateowner"
        
        struct Configuration {
            private init() {}
            
            static let stateOwner = "com.adobe.module.configuration"
            static let experiencePlatformConfigId = "experiencePlatform.configId"
            static let experienceCloudOrgId = "experienceCloud.org"
        }
        
        struct Identity {
            private init() {}
            
            static let stateOwner = "com.adobe.module.identity"
            static let ecid = "mid"
        }
        
        struct Lifecycle {
            private init() {}
            
            static let stateOwner = "com.adobe.module.lifecycle"
        }
    }
    
    struct JsonKeys {
        private init() {}
        
        static let xdm = "xdm"
        static let ECID = "ECID"
        static let timestamp = "timestamp"
        static let eventId = "eventId"
        
        struct Response {
            private init() {}
            
            struct Error {
                private init() {}
                
                static let message = "message"
                static let namespace = "namespace"
            }
        }
    }
    
    struct NetworkKeys {
        private init() {}
        
        static let edgeEndpoint = "https://edge.adobedc.net/ee/v1"
        static let requestParamConfigId = "configId"
        static let requestParamRequestId = "requestId"
        static let defaultConnectTimeout: TimeInterval = 5
        static let defaultReadTimeout: TimeInterval = 5
        
        static let headerKeyAccept = "accept"
        static let headerKeyContentType = "Content-Type"
        static let headerValueApplicationJson = "application/json"
    }
}

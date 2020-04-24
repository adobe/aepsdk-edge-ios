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

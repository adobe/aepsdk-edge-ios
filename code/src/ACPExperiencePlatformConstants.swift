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

struct ACPExperiencePlatformConstants {
    
    static let eventTypeExperiencePlatform: String = "com.adobe.eventType.experiencePlatform"
    static let eventTypeAdobeHub: String = "com.adobe.eventType.hub"

    static let eventSourceAdobeSharedState: String = "com.adobe.eventSource.sharedState"
    static let eventSourceExtensionRequestContent: String = "com.adobe.eventSource.requestContent"
    static let eventSourceExtensionResponseContent: String = "com.adobe.eventSource.responseContent"
    static let eventSourceExtensionErrorResponseContent: String = "com.adobe.eventSource.errorResponseContent"
    
    static let platformDataStorage: String = "PlatformExtensionDataStorage"
    
    struct Defaults {
        static let NetworkRequestMaxRetries: Int = 5
    }

    struct EventDataKeys {
        static let uniqueSequenceId: String = "uniquesequenceid"
    }
    
    struct SharedState {
        static let stateowner: String = "stateowner"
        static let configuration: String = "com.adobe.module.configuration"
        static let identity: String = "com.adobe.mobile.identity"
        static let lifecycle: String = "com.adobe.mobile.lifecycle"
        
        struct Configuration {
            static let experiencePlatformConfigId: String = "experiencePlatform.configId"
            static let experienceCloudOrgId: String = "experienceCloud.org"
        }
    }
}

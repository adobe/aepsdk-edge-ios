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
import ACPCore

class ExperiencePlatformExtensionResponseListener : ACPExtensionListener {
    private let TAG = "ExperiencePlatformExtensionListener"
    
    override init() {
        super.init()
    }
    
    override func hear(_ event: ACPExtensionEvent) {
        
        // get parent extension
        guard let parentExtension = self.extension as? ExperiencePlatformInternal else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Unable to hear event '\(event.eventUniqueIdentifier)' as parent extension is not instance of ExperiencePlatformInternal.")
            return
        }
        
        parentExtension.processPlatformResponseEvent(event)
    }
}

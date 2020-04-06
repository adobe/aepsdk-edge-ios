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

class ExperiencePlatformExtensionRequestListener : ACPExtensionListener {
    private let TAG = "ExperiencePlatformExtensionListener"
    
    override init() {
        super.init()
    }
    
    override func hear(_ event: ACPExtensionEvent) {
        
        // get parent extension
        guard let parentExtension = self.extension as? ACPExperiencePlatformInternal else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Unable to hear event '\(event.eventUniqueIdentifier)' as parent extension is not instance of ExperiencePlatformInternal.")
            return;
        }
        
        // Handle SharedState events
        if (event.eventType == ACPExperiencePlatformConstants.eventTypeAdobeHub) {
            guard let eventData = event.eventData else {
                ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Adobe Hub event contains no data. Cannot process event '\(event.eventUniqueIdentifier)'")
                return;
            }
            
            let stateOwner = eventData[ACPExperiencePlatformConstants.SharedState.stateowner] as? String
            if stateOwner == ACPExperiencePlatformConstants.SharedState.configuration {
                // kick event queue processing
                parentExtension.processEventQueue()
            }
        } else if event.eventType == ACPExperiencePlatformConstants.eventTypeExperiencePlatform &&
            event.eventSource == ACPExperiencePlatformConstants.eventSourceExtensionRequestContent {
            // Handle Platform Extension events
            parentExtension.processAddEvent(event)
        }
    }
}

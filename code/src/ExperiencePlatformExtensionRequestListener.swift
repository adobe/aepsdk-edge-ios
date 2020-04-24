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
import ACPCore

class ExperiencePlatformExtensionRequestListener : ACPExtensionListener {
    private let TAG = "ExperiencePlatformExtensionListener"
    
    override func hear(_ event: ACPExtensionEvent) {
        
        // get parent extension
        guard let parentExtension = self.extension as? ExperiencePlatformInternal else {
            ACPCore.log(ACPMobileLogLevel.warning, tag: TAG, message: "Unable to hear event '\(event.eventUniqueIdentifier)' as parent extension is not instance of ExperiencePlatformInternal.")
            return
        }
        
        // Handle SharedState events
        if event.eventType == ExperiencePlatformConstants.eventTypeAdobeHub {
            guard let eventData = event.eventData else {
                ACPCore.log(ACPMobileLogLevel.debug, tag: TAG, message: "Adobe Hub event contains no data. Cannot process event '\(event.eventUniqueIdentifier)'")
                return
            }
            
            let stateOwner = eventData[ExperiencePlatformConstants.SharedState.stateowner] as? String
            if stateOwner == ExperiencePlatformConstants.SharedState.Configuration.stateOwner {
                // kick event queue processing
                parentExtension.processEventQueue(event)
            }
        } else if event.eventType == ExperiencePlatformConstants.eventTypeExperiencePlatform &&
            event.eventSource == ExperiencePlatformConstants.eventSourceExtensionRequestContent {
            // Handle Platform Extension events
            parentExtension.processAddEvent(event)
        }
    }
}

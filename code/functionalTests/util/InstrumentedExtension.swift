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
import XCTest

/// Instrumented extension that registers a wildcard listener for intercepting events in current session. Use it along with `FunctionalTestBase`
class InstrumentedExtension : ACPExtension {
    private static let logTag = "InstrumentedExtension"
    
    override init() {
        super.init()
        
        try? api.registerWildcardListener(InstrumentedWildcardListener.self)
    }
    
    override func name() -> String? {
        "com.adobe.InstrumentedExtension"
    }
    
    override func version() -> String? {
        "1.0.0"
    }
    
    override func onUnregister() {
        super.onUnregister()
        
        // if the shared states are not used in the next registration they can be cleared in this method
        try? api.clearSharedEventStates()
    }
    
    // MARK: Event Processors
    
    /// Process `getSharedStateFor` requests
    /// - Parameter event: event sent from `getSharedStateFor` which specifies the shared state `stateowner` to retrieve
    func processSharedStateRequest(_ event: ACPExtensionEvent) {
        guard let eventData = event.eventData, !eventData.isEmpty  else { return }
        guard let owner = eventData[FunctionalTestConst.EventDataKey.stateOwner] as? String else { return }
        
        var responseData: [AnyHashable : Any?] = [FunctionalTestConst.EventDataKey.stateOwner : owner, FunctionalTestConst.EventDataKey.state : nil]
        if let state = try? api.getSharedEventState(owner, event: event) {
            responseData[FunctionalTestConst.EventDataKey.state] = state
        }
        
        guard let responseEvent = try? ACPExtensionEvent(name: "Get Shared State Response",
                                                         type: FunctionalTestConst.EventType.instrumentedExtension,
                                                         source: FunctionalTestConst.EventSource.sharedStateResponse,
                                                         data: responseData as [AnyHashable: Any]) else {
                                                            ACPCore.log(ACPMobileLogLevel.debug, tag: InstrumentedExtension.logTag, message: "ProcessSharedStateRequest failed to create response event.")
                                                            return
        }
        
        ACPCore.log(ACPMobileLogLevel.debug, tag: InstrumentedExtension.logTag, message: "ProcessSharedStateRequest Responding with shared state \(String(describing: responseData))")
        
        // dispatch paired response event with shared state data
        guard let _ = try? ACPCore.dispatchResponseEvent(responseEvent, request: event) else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: InstrumentedExtension.logTag, message: "ProcessSharedStateRequest failed to dispatch response event.")
            return
        }
    }
    
    func unregisterExtension() {
        ACPCore.log(ACPMobileLogLevel.debug, tag: InstrumentedExtension.logTag, message: "Unregistering the Instrumented extension from the Event Hub")
        self.api.unregisterExtension()
    }
}


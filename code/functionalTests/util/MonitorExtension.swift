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

class MonitorExtension : ACPExtension {
    static let eventType = "com.adobe.eventType.MonitorExtension"
    static let eventSourceSharedState = "com.adobe.eventSource.requestState"
    static let eventSourceResponse = "com.adobe.eventSource.response"
    
    /// Enable debug log messages
    static var debug: Bool = false
    
    override init() {
        super.init()
        
        do {
            try api.registerListener(MonitorListener.self,
                                     eventType: MonitorExtension.eventType,
                                     eventSource: MonitorExtension.eventSourceSharedState)
        } catch {
            log("Failed to register Monitor Listener: \(error.localizedDescription)")
        }
    }
    
    override func name() -> String? {
        "com.adobe.MonitorExtension"
    }
    
    override func version() -> String? {
        "0.1.0"
    }
    
    override func onUnregister() {
        super.onUnregister()
        
        // if the shared states are not used in the next registration they can be cleared in this method
        try? api.clearSharedEventStates()
    }
    
    // MARK: Public APIs
    
    /// Get the shared state for the specified `stateOwner`
    /// - Parameter stateOwner: the owner of the shared state (typically the name of the extension)
    /// - Returns: latest shared state of the given `stateOwner` or nil if no shared state was found
    public static func getSharedStateFor(_ stateOwner:String) -> [AnyHashable : Any]? {
        log("Get shared state for \(stateOwner)")
        guard let event = try? ACPExtensionEvent(name: "Get Shared State",
                                                 type: MonitorExtension.eventType,
                                                 source: MonitorExtension.eventSourceSharedState,
                                                 data: ["stateowner" : stateOwner]) else {
                                                    log("GetSharedStateFor failed to create request event.")
                                                    return nil
        }
        
        var returnedState: [AnyHashable:Any]? = nil
        let semaphore = DispatchSemaphore(value: 0)
        
        try? ACPCore.dispatchEvent(withResponseCallback: event) { (event) in
            
            if let eventData = event.eventData {
                returnedState = eventData["state"] as? [AnyHashable:Any]
            }
            semaphore.signal()
        }
        
        let timeoutResult = semaphore.wait(timeout: .now() + 5)
        log("GetSharedState timeout result \(timeoutResult)")
        return returnedState
    }
    
    // MARK: Event Processors
    
    /// Process `getSharedStateFor` requests
    /// - Parameter event: event sent from `getSharedStateFor` which specifies the shared state `stateowner` to retrieve
    func processSharedStateRequest(_ event: ACPExtensionEvent) {
        guard let eventData = event.eventData, !eventData.isEmpty  else {
            return
        }
        
        guard let owner = eventData["stateowner"] as? String else {
            return
        }
        
        let state = try? api.getSharedEventState(owner, event: event)
        let responseData: [AnyHashable : Any]?
        if let state = state {
            responseData = ["state" : state]
        } else {
            responseData = [:]
        }
        
        
        guard let responseEvent = try? ACPExtensionEvent(name: "Get Shared State",
                                                         type: MonitorExtension.eventType,
                                                         source: MonitorExtension.eventSourceResponse,
                                                         data: responseData) else {
                                                            log("ProcessSharedStateRequest failed to create response event.")
                                                            return
        }
        
        log("ProcessSharedStateRequest Responding with shared state \(String(describing: responseData))")
        
        guard let _ = try? ACPCore.dispatchResponseEvent(responseEvent, request: event) else {
            log("ProcessSharedStateRequest failed to dispatch response event.")
            return
        }
    }
    
    // MARK: Private Helpers
    
    /// Print message to console if `MonitorExtension.debug` is true
    /// - Parameter message: message to log to console
    private func log(_ message: String) {
        MonitorExtension.log(message)
    }
    
    /// Print message to console if `MonitorExtension.debug` is true
    /// - Parameter message: message to log to console
    private static func log(_ message: String) {
        if MonitorExtension.debug {
            print("[MonitorExtension] \(message)")
        }
    }
    
}

class MonitorListener : ACPExtensionListener {
    override func hear(_ event: ACPExtensionEvent) {
        guard let parentExtension = self.extension as? MonitorExtension else {
            return
        }
        
        switch (event.eventSource) {
        case MonitorExtension.eventSourceSharedState:
            parentExtension.processSharedStateRequest(event)
        default:
            return
        }
    }
}

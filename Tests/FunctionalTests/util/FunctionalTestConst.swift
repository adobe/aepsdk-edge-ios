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

enum FunctionalTestConst {

    enum EventType {
        static let EDGE = "com.adobe.eventType.edge"
        static let INSTRUMENTED_EXTENSION = "com.adobe.eventType.instrumentedExtension"
        static let HUB = "com.adobe.eventType.hub"
        static let CONFIGURATION = "com.adobe.eventType.configuration"
        static let IDENTITY = "com.adobe.eventType.identity"
    }

    enum EventSource {
        static let REQUEST_CONTENT = "com.adobe.eventSource.requestContent"
        static let RESPONSE_CONTENT = "com.adobe.eventSource.responseContent"
        static let ERROR_RESPONSE_CONTENT = "com.adobe.eventSource.errorResponseContent"
        static let SHARED_STATE_REQUEST = "com.adobe.eventSource.requestState"
        static let SHARED_STATE_RESPONSE = "com.adobe.eventSource.responseState"
        static let UNREGISTER_EXTENSION = "com.adobe.eventSource.unregisterExtension"
        static let SHARED_STATE = "com.adobe.eventSource.sharedState"
        static let RESPONSE_IDENTITY = "com.adobe.eventSource.responseIdentity"
        static let REQUEST_IDENTITY = "com.adobe.eventSource.requestIdentity"
        static let BOOTED = "com.adobe.eventSource.booted"
    }

    enum EventDataKey {
        static let STATE_OWNER = "stateowner"
        static let STATE = "state"
    }

    enum SharedState {
        static let CONFIGURATION = "com.adobe.module.configuration"
    }
    enum Defaults {
        static let WAIT_EVENT_TIMEOUT: TimeInterval = 2
        static let WAIT_SHARED_STATE_TIMEOUT: TimeInterval = 3
        static let WAIT_NETWORK_REQUEST_TIMEOUT: TimeInterval = 2
        static let WAIT_TIMEOUT: UInt32 = 1 // used when no expectation is set
    }

    static let EX_EDGE_INTERACT_URL_STR = "https://edge.adobedc.net/ee/v1/interact"
}

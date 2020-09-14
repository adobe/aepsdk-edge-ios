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

struct FunctionalTestConst {
    private init() {}

    struct EventType {
        private init() {}
        static let experiencePlatform = "com.adobe.eventType.experiencePlatform"
        static let instrumentedExtension = "com.adobe.eventType.instrumentedExtension"
        static let eventHub = "com.adobe.eventType.hub"
        static let configuration = "com.adobe.eventType.configuration"
        static let identity = "com.adobe.eventType.identity"
    }

    struct EventSource {
        private init() {}
        static let requestContent = "com.adobe.eventSource.requestContent"
        static let responseContent = "com.adobe.eventSource.responseContent"
        static let errorResponseContent = "com.adobe.eventSource.errorResponseContent"
        static let sharedStateRequest = "com.adobe.eventSource.requestState"
        static let sharedStateResponse = "com.adobe.eventSource.responseState"
        static let unregisterExtension = "com.adobe.eventSource.unregisterExtension"
        static let sharedState = "com.adobe.eventSource.sharedState"
        static let responseIdentity = "com.adobe.eventSource.responseIdentity"
        static let requestIdentity = "com.adobe.eventSource.requestIdentity"
        static let booted = "com.adobe.eventSource.booted"
    }

    struct EventDataKey {
        private init() {}
        static let stateOwner = "stateowner"
        static let state = "state"
    }

    struct Defaults {
        static let waitEventTimeout: TimeInterval = 2
        static let waitSharedStateTimeout: TimeInterval = 3
        static let waitNetworkRequestTimeout: TimeInterval = 2
        static let waitTimeout: UInt32 = 1 // used when no expectation was set
    }
}

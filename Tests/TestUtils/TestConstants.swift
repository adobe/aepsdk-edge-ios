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

enum TestConstants {

    enum EventName {
        static let CONTENT_COMPLETE = "AEP Response Complete"
    }

    enum EventType {
        static let EDGE = "com.adobe.eventType.edge"
        static let INSTRUMENTED_EXTENSION = "com.adobe.eventType.instrumentedExtension"
        static let HUB = "com.adobe.eventType.hub"
        static let CONFIGURATION = "com.adobe.eventType.configuration"
        static let IDENTITY = "com.adobe.eventType.identity"
        static let CONSENT = "com.adobe.eventType.edgeConsent"
    }

    enum EventSource {
        static let CONTENT_COMPLETE = "com.adobe.eventSource.contentComplete"
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
        static let LOCATION_HINT_RESULT = "locationHint:result"
        static let STATE_STORE = "state:store"
    }

    enum EventDataKey {
        static let STATE_OWNER = "stateowner"
        static let STATE = "state"
    }

    enum SharedState {
        static let CONFIGURATION = "com.adobe.module.configuration"
        static let IDENTITY = "com.adobe.edge.identity"
    }
    enum Defaults {
        static let WAIT_EVENT_TIMEOUT: TimeInterval = 2
        static let WAIT_SHARED_STATE_TIMEOUT: TimeInterval = 3
        static let WAIT_NETWORK_REQUEST_TIMEOUT: TimeInterval = 2
        static let WAIT_TIMEOUT: UInt32 = 1 // used when no expectation is set
    }

    enum DataStoreKeys {
        static let STORE_NAME = "AEPEdge"
        static let STORE_PAYLOADS = "storePayloads"
    }

    static let EX_EDGE_INTERACT_PROD_URL_STR = "https://edge.adobedc.net/ee/v1/interact"
    static let EX_EDGE_INTERACT_PRE_PROD_URL_STR = "https://edge.adobedc.net/ee-pre-prd/v1/interact"
    static let EX_EDGE_INTERACT_INTEGRATION_URL_STR = "https://edge-int.adobedc.net/ee/v1/interact"

    static let EX_EDGE_CONSENT_PROD_URL_STR = "https://edge.adobedc.net/ee/v1/privacy/set-consent"
    static let EX_EDGE_CONSENT_PRE_PROD_URL_STR = "https://edge.adobedc.net/ee-pre-prd/v1/privacy/set-consent"
    static let EX_EDGE_CONSENT_INTEGRATION_URL_STR = "https://edge-int.adobedc.net/ee/v1/privacy/set-consent"

    static let EX_EDGE_INTERACT_PROD_URL_STR_OR2_LOC = "https://edge.adobedc.net/ee/or2/v1/interact"
    static let OR2_LOC = "or2"

    static let EX_EDGE_MEDIA_PROD_URL_STR = "https://edge.adobedc.net/ee/va/v1/sessionstart"
    static let EX_EDGE_MEDIA_PRE_PROD_URL_STR = "https://edge.adobedc.net/ee-pre-prd/va/v1/sessionstart"
    static let EX_EDGE_MEDIA_INTEGRATION_URL_STR = "https://edge-int.adobedc.net/ee/va/v1/sessionstart"
}

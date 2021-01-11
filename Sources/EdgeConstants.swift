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

enum EdgeConstants {

    static let EXTENSION_NAME = "com.adobe.edge"
    static let EXTENSION_VERSION = "1.0.0-beta.2"
    static let FRIENDLY_NAME = "AEPEdge"

    enum EventSource {
        static let ERROR_RESPONSE_CONTENT = "com.adobe.eventSource.errorResponseContent"
    }

    enum EventName {
        static let REQUEST_CONTENT = "AEP Request Event"
        static let RESPONSE_CONTENT = "AEP Response Event Handle"
        static let ERROR_RESPONSE_CONTENT = "AEP Error Response"
    }

    enum Defaults {
        static let NETWORK_REQUEST_MAX_RETRIES: UInt = 5
        static let RECORD_SEPARATOR: String = "\u{0000}"
        static let LINE_FEED: String = "\n"
    }

    enum EventDataKeys {
        static let EDGE_REQUEST_ID = "requestId"
        static let REQUEST_EVENT_ID = "requestEventId"
        static let DATASET_ID = "datasetId"
        static let GLOBAL_PRIVACY = "global.privacy"
    }

    enum DataStoreKeys {
        static let STORE_NAME = "AEPEdge"
        static let STORE_PAYLOADS = "storePayloads"
    }

    enum SharedState {
        static let STATE_OWNER = "stateowner"

        enum Configuration {
            static let STATE_OWNER_NAME = "com.adobe.module.configuration"
            static let CONFIG_ID = "edge.configId"
            static let ORG_ID = "experienceCloud.org"
        }

        enum Identity {
            static let STATE_OWNER_NAME = "com.adobe.module.identity"
            static let ECID = "mid"
        }
        enum Assurance {
            static let STATE_OWNER_NAME = "com.adobe.assurance"
            static let INTEGRATION_ID = "integrationid"
        }

        enum Lifecycle {
            static let STATE_OWNER_NAME = "com.adobe.module.lifecycle"
        }
    }

    enum JsonKeys {
        static let XDM = "xdm"
        static let DATA = "data"
        static let QUERY = "query"
        static let ECID = "ECID"
        static let TIMESTAMP = "timestamp"
        static let EVENT_ID = "_id"
        static let META = "meta"

        enum CollectMetadata {
            static let COLLECT = "collect"
            static let DATASET_ID = "datasetId"
        }

        enum Response {
            static let EVENT_HANDLE_TYPE_STORE = "state:store"

            enum Error {
                static let MESSAGE = "message"
                static let NAMESPACE = "namespace"
            }
        }
    }

    enum NetworkKeys {
        static let EDGE_ENDPOINT = "https://edge.adobedc.net/ee/v1"
        static let REQUEST_PARAM_CONFIG_ID = "configId"
        static let REQUEST_PARAM_REQUEST_ID = "requestId"
        static let DEFAULT_CONNECT_TIMEOUT: TimeInterval = 5
        static let DEFAULT_READ_TIMEOUT: TimeInterval = 5
        static let HEADER_KEY_ACCEPT = "accept"
        static let HEADER_KEY_CONTENT_TYPE = "Content-Type"
        static let HEADER_KEY_AEP_VALIDATION_TOKEN = "X-Adobe-AEP-Validation-Token"
        static let HEADER_VALUE_APPLICATION_JSON = "application/json"
        static let RETRY_INTERVAL: TimeInterval = 5
    }
}

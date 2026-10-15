//
// Copyright 2026 Adobe. All rights reserved.
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

// Constants owned by the consent-independent device-attributes (bypass) path.
// Declared as extensions so the shared `EdgeConstants.swift` is left untouched.

extension EdgeConstants {
    enum EventType {
        /// Request (E3, `requestContent`) and result (E4, `responseContent`) event type for the device-attributes path.
        static let EDGE_BYPASS_CONSENT = "com.adobe.eventType.edgeBypassConsent"
    }

    enum DataQueueLabels {
        /// Suffix appended to the Edge extension name to label the dedicated device-attributes queue.
        static let BYPASS_CONSENT_SUFFIX = ".bypassConsent"
    }

    enum BypassResult {
        enum Status {
            static let SUCCESS = "success"
            static let FAILED = "failed"
            static let DROPPED = "dropped"
        }

        enum Reason {
            static let MISSING_CONFIG = "missingConfig"
            static let INVALID_PAYLOAD = "invalidPayload"
            static let QUEUE_UNAVAILABLE = "queueUnavailable"
            static let NETWORK = "network"
        }
    }

    enum DeviceAttributes {
        /// HTTP status codes treated as a successful device-attributes request.
        static let SUCCESS_RESPONSE_CODES: Set<Int> = [200, 202]
        static let EDGE_NETWORK_SCOPE = "EdgeNetwork"

        enum ResponseKeys {
            static let HANDLE = "handle"
            static let TYPE = "type"
            static let PAYLOAD = "payload"
            static let TITLE = "title"
            static let REPORT = "report"
            static let ERRORS = "errors"
        }
    }
}

extension EdgeConstants.EventName {
    static let BYPASS_RESULT = "Device Attributes Response"
}

extension EdgeConstants.EventDataKeys {
    enum BypassResult {
        static let STATUS = "status"
        static let REASON = "reason"
        static let HTTP_STATUS = "httpStatus"
        static let REQUEST_EVENT_ID = EdgeConstants.EventDataKeys.REQUEST_EVENT_ID
    }
}

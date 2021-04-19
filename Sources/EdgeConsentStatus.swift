//
// Copyright 2021 Adobe. All rights reserved.
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

enum ConsentStatus: String, RawRepresentable, Codable {
    case yes = "y"
    case no = "n"
    case pending = "p"

    typealias RawValue = String

    /// Initializes the appropriate `ConsentStatus` enum for the given `rawValue`
    /// - Parameter rawValue: a `RawValue` representation of a `ConsentStatus` enum, default is pending
    public init(rawValue: RawValue) {
        switch rawValue {
        case "y":
            self = .yes
        case "n":
            self = .no
        default:
            self = EdgeConstants.Defaults.COLLECT_CONSENT_PENDING
        }
    }

    /// Extracts the collect consent value from the provided event data payload, if encoding fails it returns the default `EdgeConstants.Defaults.CONSENT_PENDING`
    /// - Parameter eventData: consent preferences update payload
    /// - Returns: the collect consent value extracted from the payload, or pending if the decoding failed
    static func getCollectConsentOrDefault(eventData: [String: Any]) -> ConsentStatus {
        // if collect consent not set yet, use default (pending)
        guard let consents = eventData[EdgeConstants.SharedState.Consent.CONSENTS] as? [String: Any],
              let collectConsent = consents[EdgeConstants.SharedState.Consent.COLLECT] as? [String: Any],
              let collectConsentValue = collectConsent[EdgeConstants.SharedState.Consent.VAL] as? String else {
            return EdgeConstants.Defaults.COLLECT_CONSENT_PENDING
        }

        return ConsentStatus(rawValue: collectConsentValue)
    }
}

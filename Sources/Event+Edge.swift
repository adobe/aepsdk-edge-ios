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

import AEPCore
import Foundation

/// Adds convenience properties to an `Event` for the Edge extension
extension Event {

    /// Returns true if this `Event` has `EventType.edge` and `EventSource.updateConsent`, otherwise false
    var isUpdateConsentEvent: Bool {
        return type == EventType.edge && source == EventSource.updateConsent
    }

    /// Returns true if this `Event` has `EventType.edge` and `EventSource.requestContent`, otherwise false
    var isExperienceEvent: Bool {
        return type == EventType.edge && source == EventSource.requestContent
    }

    /// Returns true if this `Event` has `EventType.genericIdentity` and `EventSource.requestReset`, otherwise false
    var isResetIdentitiesEvent: Bool {
        return type == EventType.genericIdentity && source == EventSource.requestReset
    }
}

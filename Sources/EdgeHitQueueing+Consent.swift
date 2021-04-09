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

import AEPServices
import Foundation

extension HitQueuing {
    /// Based on `status` determines if we should continue processing hits or if we should suspend processing and clear hits
    /// - Parameter status: the current collect consent status
    func handleCollectConsentChange(status: ConsentStatus) {
        switch status {
        case .yes:
            beginProcessing()
        case .no:
            clear()
            beginProcessing()
            Log.debug(label: EdgeConstants.LOG_TAG, "EdgeHitQueue - Collect consent set to (n), clearing the Edge queue.")
        case .pending:
            suspend()
            Log.debug(label: EdgeConstants.LOG_TAG, "EdgeHitQueue - Collect consent is pending, suspending the Edge queue until (y/n).")
        }
    }
}

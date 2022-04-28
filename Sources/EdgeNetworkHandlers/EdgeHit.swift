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

import AEPCore
import Foundation

/// Protocol used for defining hits to Experience Edge service
protocol EdgeHit {

    /// The Edge endpoint
    var endpoint: EdgeEndpoint { get }

    /// The Edge configuration identifier
    var configId: String { get }

    /// Unique identifier for the Edge request
    var requestId: String { get }

    /// The network request payload for this `EdgeHit`
    func getPayload() -> String?

    /// Retrieves the `Streaming` settings for this `EdgeHit` or nil if not enabled
    func getStreamingSettings() -> Streaming?
}

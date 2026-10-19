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

/// Outcome of a device-attributes network request.
enum DeviceAttributesNetworkResult: Equatable {
    /// The request was accepted (HTTP 200 or 202). The response body is not used.
    case success(httpStatus: Int)
    /// The request failed with a recoverable error and should be retried after `interval` seconds.
    case retry(interval: TimeInterval)
    /// The request failed with an unrecoverable error; `httpStatus` is nil when no response code was received.
    case failed(httpStatus: Int?)
}

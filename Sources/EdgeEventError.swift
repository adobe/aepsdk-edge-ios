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

/// Error information for a single Experience Event, delivered to an `EdgeCallbackWithError` registered via
/// `Edge.sendEvent(experienceEvent:callback:)`, mirroring `aepsdk-edge-android`'s public `EdgeEventError`.
@objc(AEPEdgeEventError)
public class EdgeEventError: NSObject {

    /// Namespaced error code
    @objc public let type: String?

    /// Error code info
    @objc public let status: Int

    /// Error message
    @objc public let title: String?

    /// Detailed message of the error
    @objc public let detail: String?

    init(type: String?, status: Int, title: String?, detail: String?) {
        self.type = type
        self.status = status
        self.title = title
        self.detail = detail
    }

    override public var description: String {
        "EdgeEventError(type: \(type ?? "nil"), status: \(status), title: \(title ?? "nil"), detail: \(detail ?? "nil"))"
    }
}

extension EdgeResponseError {
    /// Projects this internal wire-format error onto the public `EdgeEventError` DTO, mirroring
    /// `aepsdk-edge-android`'s `NetworkResponseHandler.buildEdgeEventError`. The internal `report`
    /// (containing `eventIndex`, used only for response-to-event attribution) is intentionally dropped.
    func asPublicEdgeEventError() -> EdgeEventError {
        EdgeEventError(type: type, status: status ?? 0, title: title, detail: detail)
    }
}

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

/// A callback registered with `Edge.sendEvent(experienceEvent:callback:)` to receive both the response
/// handles and any per-event errors for a sent Experience Event, mirroring `aepsdk-edge-android`'s
/// `EdgeCallbackWithError`.
@objc(AEPEdgeCallbackWithError)
public protocol EdgeCallbackWithError: AnyObject {

    /// Invoked when the request is complete, with the `EdgeEventHandle`(s) received from the Adobe
    /// Experience Platform Edge Network for this event. May be invoked on a different thread. Always
    /// invoked exactly once per registered event, regardless of whether any errors were also received.
    func onComplete(_ handles: [EdgeEventHandle])

    /// Invoked when one or more errors are received from the Adobe Experience Platform Edge Network for
    /// this event. May be invoked on a different thread, and is only invoked when at least one error was
    /// received - warnings do not trigger this callback.
    func onError(_ errors: [EdgeEventError])
}

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

import AEPEdge
import AEPServices
import Foundation

class ResponseHandler: EdgeResponseHandler {
    var onResponseUpdateCalled: Bool = false
    var onErrorUpdateCalled: Bool = false
    var onCompleteCalled: Bool = false

    func onResponseUpdate(eventHandle: EdgeEventHandle) {
        self.onResponseUpdateCalled = true
        Log.debug(label: "ResponseHandler", "Edge response has been received...")
    }

    func onErrorUpdate(error: EdgeEventError) {
        self.onErrorUpdateCalled = true
        Log.debug(label: "ResponseHandler", "Edge error message has been received...")
    }

    func onComplete() {
        self.onCompleteCalled = true
        Log.debug(label: "ResponseHandler", "Edge request completed...")
    }
}

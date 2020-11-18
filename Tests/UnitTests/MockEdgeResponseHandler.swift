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

@testable import AEPEdge
import Foundation

class MockEdgeResponseHandler: EdgeResponseHandler {
    var onResponseReceivedData: [String: Any] = [:] // latest data received in the onResponse callback
    var onResponseCalledTimes = 0 // the number of times onResponse was called
    var onErrorUpdateData: EdgeEventError?// latest error received in the onErrorUpdate callback
    var onErrorUpdateCalledTimes = 0 // the number of times onResponse was called
    var onCompleteCalledTimes = 0 // the number of times onComplete was called

    func onResponseUpdate(eventHandle: EdgeEventHandle) {
        onResponseCalledTimes += 1
        onResponseReceivedData = eventHandle.asDictionary() ?? [:]
    }

    func onErrorUpdate(error: EdgeEventError) {
        onErrorUpdateCalledTimes += 1
        onErrorUpdateData = error
    }

    func onComplete() {
        onCompleteCalledTimes += 1
    }
}

extension EdgeEventHandle {
    func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
}

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

import Foundation

/// Internal response callback protocol, used by the `EdgeNetworkService` to capture the response from the Adobe Experience Edge server.
protocol ResponseCallback {

    /// This method is called when the response was successfully fetched from the Experience Edge server
    /// for the associated event; this callback may be called multiple times for the same event, based on the
    /// data coming from the server
    /// - Parameter jsonResponse: response from the server as JSON formatted string
    func onResponse(jsonResponse: String)

    /// This method is called when the  Experience Edge server returns an error for the associated event
    /// - Parameter jsonError: error from server as JSON formatted string
    func onError(jsonError: String)

    /// This method is called when the network connection was closed and there is no more stream
    /// pending for marking a network request as complete. This can be used for running cleanup jobs
    /// after a network response is received.
    func onComplete()
}

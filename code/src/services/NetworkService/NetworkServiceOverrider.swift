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

/// Used to set the `HttpConnectionPerformer` instance being used to override the network stack
public class NetworkServiceOverrider {
    // queue used to ensure concurrent mutations of the performer
    private let queue = DispatchQueue(label: "com.adobe.networkserviceoverrider", attributes: .concurrent)
    private var internalPerformer:HttpConnectionPerformer?
    public static let shared = NetworkServiceOverrider()
    
    private init(){}
    
    /// Current HttpConnectionPerformer, nil if NetworkServiceOverrider is not set or `reset()` was called before
    public var performer: HttpConnectionPerformer? {
        self.queue.sync { self.internalPerformer}
    }
    
    /// Sets a new `HttpConnectionPerformer` to override default network activity.
    /// - Parameter with: `HttpConnectionPerformer` new performer to be used in place of default network stack.
    public func enableOverride(with : HttpConnectionPerformer) {
        print("NetworkServiceOverrider - Enabling network override.")
        self.queue.async(flags: .barrier) { self.internalPerformer = with }
    }
    
    /// Resets currently set `HttpConnectionPerformer` and allows the SDK to use the default network stack for network requests.
    public func reset() {
        print("NetworkServiceOverrider - Disabling network override, using default network service.")
        self.queue.async(flags: .barrier) { self.internalPerformer = nil }
    }
}

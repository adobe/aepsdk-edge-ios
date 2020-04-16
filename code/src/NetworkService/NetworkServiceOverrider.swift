//
// ADOBE CONFIDENTIAL
//
// Copyright 2020 Adobe
// All Rights Reserved.
//
// NOTICE: All information contained herein is, and remains
// the property of Adobe and its suppliers, if any. The intellectual
// and technical concepts contained herein are proprietary to Adobe
// and its suppliers and are protected by all applicable intellectual
// property laws, including trade secret and copyright laws.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from Adobe.
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

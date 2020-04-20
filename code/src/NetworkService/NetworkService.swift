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

protocol NetworkService {
    
    /// Initiates an asynchronous network connection to the specified NetworkRequest.url. This API uses `URLRequest.CachePolicy.reloadIgnoringLocalCache`.
    /// - Parameters:
    ///   - networkRequest: the `NetworkRequest` used for this connection
    ///   - completionHandler:Optional completion handler which is called once the `HttpConnection` is available; it can be called from an `HttpConnectionPerformer` if `NetworkServiceOverrider` is enabled.
    ///   In case of a network error, timeout or an unexpected error, the `HttpConnection` is nil
    func connectAsync(networkRequest: NetworkRequest, completionHandler: ((HttpConnection) -> Void)?)
}

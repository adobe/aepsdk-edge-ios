/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

public class AEPServiceProvider {
    public static let shared = AEPServiceProvider()

    // Provide thread safety on the getters and setters
    private let barrierQueue = DispatchQueue(label: "AEPServiceProvider.barrierQueue", attributes: .concurrent)

    private var overrideNetworkService: NetworkService?
    private var defaultNetworkService = AEPNetworkService()

    public var networkService: NetworkService {
            get {
                return barrierQueue.sync {
                    return overrideNetworkService ?? defaultNetworkService
                }
            }
            set {
                barrierQueue.async(flags: .barrier) {
                    self.overrideNetworkService = newValue
                }
            }
        }
}

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

@testable import AEPServices
import Foundation

extension FileManager {

    func clearCache() {
        if let url = self.urls(for: .cachesDirectory, in: .userDomainMask).first {

            do {
                try self.removeItem(at: URL(fileURLWithPath: "\(url.relativePath)/com.adobe.edge"))
                if let dqService = ServiceProvider.shared.dataQueueService as? DataQueueService {
                    _ = dqService.threadSafeDictionary.removeValue(forKey: "com.adobe.edge")
                }
            } catch {
                print("ERROR DESCRIPTION: \(error)")
            }
        }

    }

}

//
// Copyright 2023 Adobe. All rights reserved.
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

public func extractEnvironmentVariable<T: RawRepresentable>(keyName: String, enum: T.Type) -> T? where T.RawValue == String {
    guard let environmentString = ProcessInfo.processInfo.environment[keyName] else {
        print("Unable to find valid \(keyName) value (raw value: \(String(describing: ProcessInfo.processInfo.environment[keyName]))).")
        return nil
    }

    guard let enumCase = T(rawValue: environmentString) else {
        print("Unable to create valid enum case of type \(T.Type.self) from environment variable value: \(environmentString)")
        return nil
    }

    return enumCase
}

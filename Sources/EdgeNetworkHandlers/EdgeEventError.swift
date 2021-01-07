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

/// Error information for a sent EdgeRequest
struct EdgeEventError: Codable, Equatable {
    /// Error message
    let title: String?

    /// Detailed message of the error
    let detail: String?

    /// Error code info
    let status: Int?

    /// Namespaced error code
    let type: String?

    /// Encodes the event to which this error is attached as the index in the events array in EdgeRequest
    let eventIndex: Int?

    /// A report for the error containing additional information
    let report: EdgeErrorReport?
}

// MARK: - EdgeErrorReport
struct EdgeErrorReport: Codable, Equatable {
    // An array of errors represented as strings
    let errors: [String]?

    /// Request ID corresponding to the error
    let requestId: String?

    /// The organization ID
    let orgId: String?
}

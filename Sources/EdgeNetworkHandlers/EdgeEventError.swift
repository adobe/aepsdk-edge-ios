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

    /// A report for the error containing additional information
    let report: EdgeErrorReport?

    init(title: String?, detail: String?, status: Int?, type: String?, report: EdgeErrorReport?) {
        self.title = title
        self.detail = detail
        self.status = status
        self.type = type
        self.report = report
    }

    init(title: String?, detail: String?) {
        self.title = title
        self.detail = detail
        self.status = nil
        self.type = nil
        self.report = nil
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case title
        case detail
        case status
        case type
        case report
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let unwrapped = title { try container.encodeIfPresent(unwrapped, forKey: .title) }
        if let unwrapped = detail { try container.encodeIfPresent(unwrapped, forKey: .detail) }
        if let unwrapped = status { try container.encodeIfPresent(unwrapped, forKey: .status) }
        if let unwrapped = type { try container.encodeIfPresent(unwrapped, forKey: .type) }
        if let unwrapped = report, unwrapped.shouldEncode() { try container.encodeIfPresent(unwrapped, forKey: .report) }
    }
}

// MARK: - EdgeErrorReport
struct EdgeErrorReport: Codable, Equatable {

    /// Encodes the event to which this error is attached as the index in the events array in EdgeRequest
    let eventIndex: Int?

    // An array of errors represented as strings
    let errors: [String]?

    /// Request ID corresponding to the error
    let requestId: String?

    /// The organization ID
    let orgId: String?

    init(eventIndex: Int?, errors: [String]?, requestId: String?, orgId: String?) {
        self.eventIndex = eventIndex
        self.errors = errors
        self.requestId = requestId
        self.orgId = orgId
    }

    // Encode this report if it contains `errors`, `requestId`, or `orgId`.
    public func shouldEncode() -> Bool {
        return errors != nil
            || requestId != nil
            || orgId != nil
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case eventIndex
        case errors
        case requestId
        case orgId
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // skip eventIndex when encoding
        if let unwrapped = errors { try container.encodeIfPresent(unwrapped, forKey: .errors)}
        if let unwrapped = requestId { try container.encodeIfPresent(unwrapped, forKey: .requestId)}
        if let unwrapped = orgId { try container.encodeIfPresent(unwrapped, forKey: .orgId)}
    }
}

//
// Copyright 2024 Adobe. All rights reserved.
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

enum IntegrationTestConstants {
    enum EnvironmentKeys {
        static let EDGE_LOCATION_HINT = "EDGE_LOCATION_HINT"
        static let TAGS_MOBILE_PROPERTY_ID = "TAGS_MOBILE_PROPERTY_ID"
    }

    enum EdgeLocationHint: String, CaseIterable {
        /// Australia
        case AUS3 = "aus3"
        /// India
        case IND1 = "ind1"
        /// Ireland
        case IRL1 = "irl1"
        /// Japan
        case JPN3 = "jpn3"
        /// Oregon, USA
        case OR2 = "or2"
        /// Singapore
        case SGP3 = "sgp3"
        /// Virginia, USA
        case VA6 = "va6"
    }

    // Primarily used in the context of GitHub Action workflows to transform preset location hint
    // options into the intended actual location hint value.
    enum LocationHintMapping {
        static let EMPTY_STRING = "Empty string: \"\""
        static let INVALID = "Invalid"
        static let NONE = "(None)"
    }

    enum TagsMobilePropertyId {
        static let PROD = "94f571f308d5/6b1be84da76a/launch-023a1b64f561-development"
    }
}

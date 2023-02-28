/*
 Copyright 2022 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

/// Environment: Production
/// Org: AEM Assets Departmental - Campaign (906E3A095DC834230A495FD6@AdobeOrg)
/// Sandbox: Prod (VA7)
/// Data Collection tag: AJO - IAM E2E Automated Tests
/// App Surface: AJO - IAM E2E Automated tests (com.adobe.ajoinbounde2etestsonly)
/// Datastream: cjm-prod-va7 (0814ac07-ffeb-44c4-8633-85301d5e721c)
/// AppID for SDK configuration: 3149c49c3910/8398c2585133/launch-1780400a22e8-development

/// Environment: Production
/// Org: CJM Prod AUS5 (404C2CDA605B7E960A495FCE@AdobeOrg)
/// Sandbox: Prod (AUS5)
/// Data Collection tag: AJO - IAM E2E Automated Tests
/// App Surface: AJO - IAM E2E Automated tests (com.adobe.ajoinbounde2etestsonly)
/// Datastream: cjm-prod-aus5 (40b09983-9d1e-4472-af7d-947290ad8480)
/// AppID for SDK configuration: 3269cfd2f1f9/73343fae78b8/launch-b2d301f72010-development

/// Environment: Production
/// Org: CJM Prod NLD2 (4DA0571C5FDC4BF70A495FC2@AdobeOrg)
/// Sandbox: Prod (NLD2)
/// Data Collection tag: AJO - IAM E2E Automated Tests
/// App Surface: AJO - IAM E2E Automated tests (com.adobe.ajoinbounde2etestsonly)
/// Datastream: cjm-prod-nld2 (3e808bee-74f7-468f-be1d-99b498f36fa8)
/// AppID for SDK configuration: bf7248f92b53/1d83dbc6cd95/launch-3102a655964f-development

/// Environment: Stage
/// Org: CJM Stage (745F37C35E4B776E0A49421B@AdobeOrg)
/// Sandbox: AJO Web (VA7)
/// Data Collection tag: AJO - IAM E2E Automated Tests
/// App Surface: AJO - IAM E2E Automated tests (com.adobe.ajoinbounde2etestsonly)
/// Datastream: ajo-stage: Production Environment (19fc5fe9-37df-46da-8f5c-9eeff4f75ed9)
/// AppID for SDK configuration: staging/1b50a869c4a2/8a2b5f4bc2f0/launch-302971d67c36-development

enum Environment: String {
    case prodVA7 = "prodVA7"
    case prodAUS5 = "prodAUS5"
    case prodNLD2 = "prodNLD2"
    case stageVA7 = "stageVA7"
    
    /// Gets the current environment from the Info.plist file
    /// If the bundle is unavailable or does not contain the correct setting,
    /// this method returns `Environment.prodVA7`.
    ///
    /// - returns: the environment to use for testing
    static func get() -> Environment {
        // need access to Info.plist for reading out the test environment
        guard let infoDictionary = Bundle.main.infoDictionary else {
            return .prodVA7
        }
        
        guard let env = infoDictionary["ADOBE_ENVIRONMENT"] as? String else {
            return .prodVA7
        }
        
        return Environment(rawValue: env) ?? .prodVA7
    }
}

extension Environment {
    var appId: String {
        switch self {
        case .prodVA7:
            return "3149c49c3910/8398c2585133/launch-1780400a22e8-development"
        case .prodAUS5:
            return "3269cfd2f1f9/73343fae78b8/launch-b2d301f72010-development"
        case .prodNLD2:
            return "bf7248f92b53/1d83dbc6cd95/launch-3102a655964f-development"
        case .stageVA7:
            return "staging/1b50a869c4a2/8a2b5f4bc2f0/launch-302971d67c36-development"
        }
    }
    
    var configurationUpdates: [String: Any]? {
        guard isStaging else {
            return nil
        }
        
        return ["edge.environment": "int"]
    }
    
    private var isStaging: Bool {
        switch self {
        case .prodVA7, .prodAUS5, .prodNLD2:
            return false
        case .stageVA7:
            return true        
        }
    }
}

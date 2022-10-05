//
// Copyright 2022 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

/// Imports the various Edge extensions and other AEP extensions that enable sending event
/// data to the Edge Network, and power other features. The `import` statement makes it available
/// to use in the code below.
//* Edge Tutorial - code section (1/3)
import AEPAssurance
import AEPCore
import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
import AEPLifecycle
// Edge Tutorial - code section (1/3) */

import Compression
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // TODO: Set up the preferred Environment File ID from your mobile property configured in Data Collection UI
    private let ENVIRONMENT_FILE_ID = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let appState = application.applicationState
//* Edge Tutorial - code section (2/3)
        /// Sets the log level of Core (which handles the core functionality used by extensions like networking,
        /// data conversions, etc.) to `trace`, which provides more granular details on app logic; this can be
        /// helpful in debugging or troubleshooting issues.
        MobileCore.setLogLevel(.trace)
        /// This sets the environment file ID which is the mobile property configuration set up in the first section;
        /// this will apply the extension settings in our app.
        MobileCore.configureWith(appId: ENVIRONMENT_FILE_ID)
        /// Registers the extensions with Core, getting them ready to run in the app.
        MobileCore.registerExtensions([
            Assurance.self,
            Consent.self,
            Edge.self,
            Identity.self,
            Lifecycle.self
        ], {
            if appState != .background {
                // Only start lifecycle if the application is not in the background
                MobileCore.lifecycleStart(additionalContextData: nil)
            }
        })
// Edge Tutorial - code section (2/3) */
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // To handle deeplink on iOS versions 12 and below
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
//* Edge Tutorial - code section (3/3)
        /// Enables deep linking to connect to Assurance. This is the method used for iOS versions 12 and below.
        Assurance.startSession(url: url)
// Edge Tutorial - code section (3/3) */
        return true
    }
}

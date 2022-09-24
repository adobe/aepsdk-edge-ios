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

import AEPCore
import AEPEdge
import AEPEdgeConsent
import AEPEdgeIdentity
import Compression
import UIKit

#if os(iOS)
import AEPAssurance
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // TODO: Set up the Environment File ID from your Launch property for the preferred environment
    private let LAUNCH_ENVIRONMENT_FILE_ID = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        MobileCore.setLogLevel(.trace)
        MobileCore.configureWith(appId: LAUNCH_ENVIRONMENT_FILE_ID)
        var extensions: [NSObject.Type] = [Edge.self, Identity.self, Consent.self]

        // MARK: TODO remove this once Assurance has tvOS support.
        #if os(iOS)
        extensions.append(contentsOf: [Assurance.self])
        #endif
        MobileCore.registerExtensions(extensions)
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
        #if os(iOS)
        Assurance.startSession(url: url)
        #endif
        return true
    }
}

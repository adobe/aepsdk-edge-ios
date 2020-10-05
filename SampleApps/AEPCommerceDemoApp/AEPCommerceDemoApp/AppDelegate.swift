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

import AEPAssurance
import AEPCore
import AEPExperiencePlatform
import AEPIdentity
import AEPLifecycle
import ACPCore
import AEPServices
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // TODO: Set up the Environment File ID from your Launch property for the preferred environment
    private let LAUNCH_ENVIRONMENT_FILE_ID = ""

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        MobileCore.setLogLevel(level: .trace)
        MobileCore.configureWith(appId: LAUNCH_ENVIRONMENT_FILE_ID)

        AEPAssurance.registerExtension()
        ACPCore.registerExtensions([Identity.self, Lifecycle.self, ExperiencePlatform.self])

        // only start lifecycle if the application is not in the background
        if application.applicationState != .background {
            MobileCore.lifecycleStart(additionalContextData: nil)
        }
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        MobileCore.lifecycleStart(additionalContextData: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        MobileCore.lifecyclePause()
    }

    // To handle deeplink on iOS versions 12 and below
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AEPAssurance.startSession(url)
        return true
    }
}

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

import ACPGriffon
import AEPCore
import AEPExperiencePlatform
import AEPIdentity
import AEPLifecycle
import AEPServices
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        MobileCore.setLogLevel(level: .trace)
        Log.debug(label: "AppDelegate", "Testing with AEPExperiencePlatform.")

        // Option 1 : Configuration : Inline
        // var config = [String: String]()
        // config["global.privacy"] = "optedin"
        // config["experienceCloud.org"] = "FAF554945B90342F0A495E2C@AdobeOrg"
        // config["experiencePlatform.configId"] = "d3d079e7-130e-4ec1-88d7-c328eb9815c4"

        // Option 2 : Configuration : From a Launch property
        //         MobileCore.configureWith(appId: "94f571f308d5/e3fc566f21d5/launch-a7a05abd3c78-development")

        // Option 3 :  Configuration : From ADBMobileConfig.json file
        let filePath = Bundle.main.path(forResource: "ADBMobileConfig", ofType: "json")
        MobileCore.configureWith(filePath: filePath)

        Identity.registerExtension()
        Lifecycle.registerExtension()
        ACPGriffon.registerExtension()
        ExperiencePlatform.registerExtension()
        MobileCore.start({
            //            MobileCore.updateConfigurationWith(configDict: config)
        })

        // only start lifecycle if the application is not in the background
        if application.applicationState != .background {
            MobileCore.lifecycleStart(nil)
        }
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        MobileCore.lifecycleStart(nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        MobileCore.lifecyclePause()
    }
}

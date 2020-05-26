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

import UIKit
import ACPExperiencePlatform
import ACPCore
import ACPGriffon
import xdmlib

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        ACPCore.setLogLevel(ACPMobileLogLevel.debug)
        ACPCore.log(ACPMobileLogLevel.debug, tag: "AppDelegate", message: String("Testing with ACPExperiencePlatform."))
        ACPIdentity.registerExtension()
        ACPLifecycle.registerExtension()
        ACPSignal.registerExtension()
        ACPGriffon.registerExtension()
        ACPExperiencePlatform.registerExtension()
        ACPGriffon.registerExtension()
        // Option 1 : Configuration : Inline
        // var config = [String: String]()
        // config["global.privacy"] = "optedin"
        // config["experienceCloud.org"] = "3E2A28175B8ED3720A495E23@AdobeOrg"
        // config["experiencePlatform.configId"] = "fd4f4820-00e1-4226-bd71-49bf0b7e3150"
        
        // Option 2 : Configuration : From a Launch property
        // ACPCore.configure(withAppId: "94f571f308d5/e3fc566f21d5/launch-a7a05abd3c78-development")
        
        // Option 3 :  Configuration : From ADBMobileConfig.json file
        let filePath = Bundle.main.path(forResource: "ADBMobileConfig", ofType: "json")
        ACPCore.configureWithFile(inPath: filePath)
        
        ACPIdentity.registerExtension()
        ACPLifecycle.registerExtension()
        ACPCore.start({
            //   ACPCore.updateConfiguration(config)
            ACPCore.lifecycleStart(nil)
        })
        return true
    }
}


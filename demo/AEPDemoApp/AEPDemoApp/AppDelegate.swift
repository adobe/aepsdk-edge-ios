//
//  AppDelegate.swift
//  AEPDemoApp
//
//  Created by lind on 5/21/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

import UIKit
import ACPCore
import ACPExperiencePlatform

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        ACPCore.setLogLevel(ACPMobileLogLevel.verbose)
        ACPIdentity.registerExtension()
        ACPExperiencePlatform.registerExtension()
        ACPCore.start {
            ACPCore.updateConfiguration(["global.privacy": "optedin",
            "experienceCloud.org": "3E2A28175B8ED3720A495E23@AdobeOrg",
            "experiencePlatform.configId": "fd4f4820-00e1-4226-bd71-49bf0b7e3150"])
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}


// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import PackageDescription

let package = Package(
    name: "AEPExperiencePlatform",
    platforms: [.iOS(.v10)],
    products: [
        .library(name: "AEPExperiencePlatform", targets: ["AEPExperiencePlatform"]),
        .library(name: "AEPExperiencePlatformStatic", type: .static, targets: ["AEPExperiencePlatform"]),
        .library(name: "AEPExperiencePlatformDynamic", type: .dynamic, targets: ["AEPExperiencePlatform"])
    ],
    dependencies: [
        .package(url: "https://github.com/adobe/aepsdk-core-ios.git", .branch("main"))
    ],
    targets: [
        .target(name: "AEPExperiencePlatform",
                dependencies: ["AEPCore"],
                path: "Sources"),
        .testTarget(name: "AEPDemoAppSwiftUI",
                    dependencies: ["AEPExperiencePlatform", "AEPIdentity"],
                    path: "SampleApps/AEPDemoAppSwiftUI"),
        .testTarget(name: "FunctionalTests",
                    dependencies: ["AEPExperiencePlatform", "AEPIdentity"],
                    path: "Tests/FunctionalTests"),
        .testTarget(name: "UnitTests",
                    dependencies: ["AEPExperiencePlatform", "AEPIdentity"],
                    path: "Tests/UnitTests"),
        .testTarget(name: "AEPCommerceDemoApp",
                    dependencies: ["AEPExperiencePlatform", "AEPIdentity", "AEPLifecycle"],
                    path: "SampleApps/AEPCommerceDemoApp")
    ]
)

// swift-tools-version:5.0
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
    ],
    dependencies: [
        .package(url: "https://github.com/adobe/aepsdk-core-ios.git", .branch("main")),
    ],
    targets: [
        .target(name: "AEPExperiencePlatform",
                dependencies: ["AEPCore", "AEPServices"],
                path: "code/src"),
	.target(name: "AEPDemoAppSwiftUI",
		dependencies: ["AEPCore", "AEPServices", "AEPIdentity"],
		path: "demo/AEPDemoAppSwiftUI"),        
        .target(name: "functionalTests",
                dependencies: ["AEPCore", "AEPServices", "AEPIdentity"],
                path: "code/functionalTests"),
	.target(name: "AEPCommerceDemoApp",
                dependencies: ["AEPCore", "AEPServices", "AEPIdentity", "AEPLifecycle"],
                path: "demo/AEPCommerceDemoApp"),
    ]
)

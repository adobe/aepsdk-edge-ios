// swift-tools-version:5.3
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
    name: "AEPEdge",
    platforms: [.iOS(.v12), .tvOS(.v12)],
    products: [
        .library(name: "AEPEdge", targets: ["AEPEdge"])
    ],
    dependencies: [
        .package(url: "https://github.com/adobe/aepsdk-core-ios.git", .upToNextMajor(from: "5.1.0")),
        .package(url: "https://github.com/adobe/aepsdk-edgeidentity-ios.git", .upToNextMajor(from: "5.0.0"))
    ],
    targets: [
        .target(name: "AEPEdge",
                dependencies: [
                    .product(name: "AEPCore", package: "aepsdk-core-ios"),
                    .product(name: "AEPEdgeIdentity", package: "aepsdk-edgeidentity-ios")
                ],
                path: "Sources")
    ]
)

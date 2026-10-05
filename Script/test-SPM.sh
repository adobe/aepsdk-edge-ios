#!/bin/bash
#
# Copyright 2021 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

set -e # Any subsequent(*) commands which fail will cause the shell script to exit immediately

PROJECT_NAME=TestProject

# Clean up.
rm -rf $PROJECT_NAME

mkdir -p $PROJECT_NAME && cd $PROJECT_NAME

# Create the package.
xcrun swift package init

# Create the Package.swift.
echo "// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: \"TestProject\",
    defaultLocalization: \"en-US\",
    platforms: [
        .iOS(.v12), .tvOS(.v12)
    ],
    products: [
        .library(
            name: \"TestProject\",
            targets: [\"TestProject\"]
        )
    ],
    dependencies: [
        .package(name: \"AEPCore\", url: \"https://github.com/shushinde/aepsdk-core-ios.git\", .upToNextMajor(from: \"5.13.0\")),
        .package(name: \"AEPEdgeIdentity\", url: \"https://github.com/shushinde/aepsdk-edgeidentity-ios.git\", .upToNextMajor(from: \"5.2.0\")),
        .package(name: \"AEPEdge\", path: \"../\")
    ],
    targets: [
        .target(
            name: \"TestProject\",
            dependencies: [
                .product(name: \"AEPCore\", package: \"AEPCore\"),
                .product(name: \"AEPIdentity\", package: \"AEPCore\"),
                .product(name: \"AEPLifecycle\", package: \"AEPCore\"),
                .product(name: \"AEPServices\", package: \"AEPCore\"),
                .product(name: \"AEPSignal\", package: \"AEPCore\"),
                .product(name: \"AEPEdgeIdentity\", package: \"AEPEdgeIdentity\"),
                .product(name: \"AEPEdge\", package: \"AEPEdge\"),
            ])
    ]
)
" >Package.swift

xcrun swift package update

# Archive for generic iOS device
echo '############# Archive for generic iOS device ###############'
xcodebuild archive -scheme TestProject -destination 'generic/platform=iOS'

# Build for generic iOS device
echo '############# Build for generic iOS device ###############'
xcodebuild build -scheme TestProject -destination 'generic/platform=iOS'

# Build for x86_64 iOS simulator
echo '############# Build for x86_64 iOS simulator ###############'
xcodebuild build -scheme TestProject -destination 'generic/platform=iOS Simulator' ARCHS=x86_64

# Ensure tvOS SDK is available before generic tvOS builds (release CI downloads iOS only).
echo '############# Download tvOS platform if needed ###############'
xcodebuild -downloadPlatform tvOS

# Archive for generic tvOS device
echo '############# Archive for generic tvOS device ###############'
xcodebuild archive -scheme TestProject -destination 'generic/platform=tvOS'

# Build for generic tvOS device
echo '############# Build for generic tvOS device ###############'
xcodebuild build -scheme TestProject -destination 'generic/platform=tvOS'

# Build for x86_64 tvOS simulator
echo '############# Build for x86_64 tvOS simulator ###############'
xcodebuild build -scheme TestProject -destination 'generic/platform=tvOS Simulator' ARCHS=x86_64

# Clean up.
cd ../
rm -rf $PROJECT_NAME

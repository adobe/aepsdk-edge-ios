# Adobe Experience Platform Edge Network Mobile Extension

[![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-edge-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange)](https://cocoapods.org/pods/AEPEdge)
[![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-edge-ios?label=SPM&logo=apple&logoColor=white&color=orange)](https://github.com/adobe/aepsdk-edge-ios/releases)
[![CircleCI](https://img.shields.io/circleci/project/github/adobe/aepsdk-edge-ios/main.svg?label=Build&logo=circleci)](https://circleci.com/gh/adobe/workflows/aepsdk-edge-ios)
[![Code Coverage](https://img.shields.io/codecov/c/github/adobe/aepsdk-edge-ios/main.svg?label=Coverage&logo=codecov)](https://codecov.io/gh/adobe/aepsdk-edge-ios/branch/main)

## About this project

The Adobe Experience Platform Edge Network mobile extension enables data transmission to the Edge Network from a mobile application. This extension enables the implementation of Adobe Experience Cloud capabilities, allowing multiple Adobe solutions to be used through a single network call and forwarding the information to Adobe Experience Platform.

The Edge Network mobile extension is part of the [Adobe Experience Platform Mobile SDK](https://developer.adobe.com/client-sdks) and requires the `AEPCore` and `AEPServices` extensions for event handling. The `AEPEdgeIdentity` extension is also required for identity management, such as managing Experience Cloud IDs (ECID).

For more details, see the [Adobe Experience Platform Edge Network](https://developer.adobe.com/client-sdks/documentation/edge-network/) documentation.

## Requirements
- Xcode 15 (or newer)
- Swift 5.1 (or newer)

## Installation

The following installation options are currently supported:

### CocoaPods

Refer to the [CocoaPods documentation](https://guides.cocoapods.org/using/using-cocoapods.html) for more details.

```ruby
# Podfile
use_frameworks!

# For app development, include all of the following dependencies
target 'YOUR_TARGET_NAME' do
  pod 'AEPCore'
  pod 'AEPEdge'
  pod 'AEPEdgeIdentity'
end

# For extension development, include AEPCore, AEPEdge, and their dependencies
target 'YOUR_TARGET_NAME' do
  pod 'AEPCore'
  pod 'AEPEdge'
end
```

Replace `YOUR_TARGET_NAME` in the `Podfile`, and then, in the Podfile directory, run:

```shell
$ pod install
```

### Swift Package Manager

Refer to the [Swift Package Manager documentation](https://github.com/apple/swift-package-manager) for more details.

To add the `AEPEdge` package to the application, select:

**File > Add Package Dependencies** from the Xcode menu.

> [!NOTE]
> Menu options may vary depending on the Xcode version being used.

Enter the repository URL for the `AEPEdge` package: `https://github.com/adobe/aepsdk-edge-ios.git`.

When prompted, specify a version or a range of versions for the version rule.

Alternatively, to add `AEPEdge` directly to the dependencies in a project with a `Package.swift` file, use the following configuration:

```swift
dependencies: [
    .package(url: "https://github.com/adobe/aepsdk-edge-ios.git", .upToNextMajor(from: "5.0.0"))
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["AEPEdge"],
        path: "your/path"
    )
]
```

### Binaries

To generate an `AEPEdge.xcframework`, use the following command:

```shell
make archive
```

The generated xcframework will be located in the `build` folder. Drag and drop the `.xcframeworks` into the app target in Xcode.

## Development

To set up the environment after cloning or downloading the project for the first time, run the following command from the root directory:

```shell
make pod-install
```

To update the environment, use the following command:

```shell
make pod-update
```

### Open the Xcode workspace

To open the workspace in Xcode, run the following command from the root directory of the repository:

```shell
make open
```

### Command line integration

To run all test suites from the command line, use the following command:

```shell
make test
```

### Code style

This project uses [SwiftLint](https://github.com/realm/SwiftLint) to check and enforce Swift style and conventions. Style checks are automatically applied when the project is built from Xcode.

To install the required tools and enable the Git pre-commit hook for automatic style correction on each commit, update the project's Git config `core.hooksPath` by running:

```shell
make setup-tools
```

## Related Projects

| Project | Description |
| --- | --- |
| [Core](https://github.com/adobe/aepsdk-core-ios) | The Core extension represents the foundation of the Adobe Experience Platform Mobile SDK. |
| [Consent for Edge Network](https://github.com/adobe/aepsdk-edgeconsent-ios) | The Consent for Edge Network extension enables consent preferences collection from your mobile app when using the Adobe Experience Platform Mobile SDK and the Edge Network extension. |
| [Identity for Edge Network](https://github.com/adobe/aepsdk-edgeidentity-ios) | The Identity for Edge Network extension enables handling of user identity data from a mobile app when using the Adobe Experience Platform Mobile SDK and the Edge Network extension. |
| [Lifecycle for Edge Network](https://github.com/adobe/aepsdk-core-ios) | The Lifecycle for Edge Network extension enables application lifecycle data collection from your mobile app when using the Adobe Experience Platform Mobile SDK and the Edge Network extension. |
| [Assurance](https://github.com/adobe/aepsdk-assurance-ios) | The Assurance extension helps you inspect, proof, simulate, and validate how you collect data or serve experiences in your mobile app. |

## Contributing

Contributions are welcomed! See the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.

## Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.

## Security policy

See the [SECURITY POLICY](SECURITY.md) for more details.

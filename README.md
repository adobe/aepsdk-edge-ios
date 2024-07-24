# Adobe Experience Platform Edge Network Mobile Extension

[![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-edge-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange)](https://cocoapods.org/pods/AEPEdge)
[![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-edge-ios?label=SPM&logo=apple&logoColor=white&color=orange)](https://github.com/adobe/aepsdk-edge-ios/releases)
[![CircleCI](https://img.shields.io/circleci/project/github/adobe/aepsdk-edge-ios/main.svg?label=Build&logo=circleci)](https://circleci.com/gh/adobe/workflows/aepsdk-edge-ios)
[![Code Coverage](https://img.shields.io/codecov/c/github/adobe/aepsdk-edge-ios/main.svg?label=Coverage&logo=codecov)](https://codecov.io/gh/adobe/aepsdk-edge-ios/branch/main)

## About this project

The Adobe Experience Platform Edge Network mobile extension allows you to send data to the Adobe  Edge Network from a mobile application. This extension allows you to implement Adobe Experience Cloud capabilities in a more robust way, serve multiple Adobe solutions though one network call, and simultaneously forward this information to the Adobe Experience Platform.

The Edge Network mobile extension is an extension for the [Adobe Experience Platform SDK](https://developer.adobe.com/client-sdks) and requires the `AEPCore` and `AEPServices` extensions for event handling, as well as the `AEPEdgeIdentity` extension for retrieving the identities, such as ECID.

To learn more about this extension, read the [Adobe Experience Platform Edge Network](https://developer.adobe.com/client-sdks/documentation/edge-network/) documentation.

## Requirements
- Xcode 15 (or newer)
- Swift 5.1 (or newer)

## Installation

These are currently the supported installation options:

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

# for app development, include all the following pods
target 'YOUR_TARGET_NAME' do
  	pod 'AEPEdge'
  	pod 'AEPCore'
  	pod 'AEPEdgeIdentity'
end

# for extension development, include AEPCore, AEPEdge and their dependencies
target 'YOUR_TARGET_NAME' do

  	pod 'AEPEdge'
  	pod 'AEPCore'
end
```

Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```ruby
$ pod install
```

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPEdge Package to your application, from the Xcode menu select:

`File > Add Packages...`

> **Note**
>  The menu options may vary depending on the version of Xcode being used.

Enter the URL for the AEPEdge package repository: `https://github.com/adobe/aepsdk-edge-ios.git`.

When prompted, input a specific version or a range of versions for Version rule.

Alternatively, if your project has a `Package.swift` file, you can add AEPEdge directly to your dependencies:

```
dependencies: [
	.package(url: "https://github.com/adobe/aepsdk-edge-ios.git", .upToNextMajor(from: "5.0.0"))
],
targets: [
   	.target(name: "YourTarget",
    		dependencies: ["AEPEdge"],
          	path: "your/path")
]
```

### Binaries

To generate an `AEPEdge.xcframework`, run the following command:

~~~
make archive
~~~

This generates the xcframework under the `build` folder. Drag and drop all the `.xcframeworks` to your app target in Xcode.

## Development

The first time you clone or download the project, you should run the following from the root directory to setup the environment:

~~~
make pod-install
~~~

Subsequently, you can make sure your environment is updated by running the following:

~~~
make pod-update
~~~

#### Open the Xcode workspace
Open the workspace in Xcode by running the following command from the root directory of the repository:

~~~
make open
~~~

#### Command line integration

You can run all the test suites from command line:

~~~
make test
~~~

### Code Style

This project uses [SwiftLint](https://github.com/realm/SwiftLint) to check and enforce the Swift style and conventions. Style checks are automatically applied when the project is built from Xcode.

To install the necessary tools and enable the Git pre-commit hook to autocorrect the style on each commit, run the following to update the project's git config `core.hooksPath`:

~~~
make setup-tools
~~~

## Related Projects

| Project                                                                              | Description                                                  |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------ |
| [AEPCore Extensions](https://github.com/adobe/aepsdk-core-ios)                       | The AEPCore and AEPServices represent the foundation of the Adobe Experience Platform SDK. |
| [AEPConsent Extension](https://github.com/adobe/aepsdk-edgeconsent-ios)              | The AEPConsent extension enables consent preferences collection from your mobile app when using the AEP Mobile SDK and the Edge Network extension. |
| [AEPLifecycle Extension](https://github.com/adobe/aepsdk-core-ios)                   | The AEPLifecycle extension helps collect application Lifecycle metrics and any additional context data provided by the application developer when using AEP SDK and the AEP Edge Network extension. |
| [AEPEdgeIdentity Extension](https://github.com/adobe/aepsdk-edgeidentity-ios)        | The AEPEdgeIdentity extension enables handling of user identity data from a mobile app when using AEP SDK and the AEP Edge Network extension. |
| [AEP SDK Sample App for iOS](https://github.com/adobe/aepsdk-sample-app-ios)         | Contains iOS sample apps for the AEP SDK. Apps are provided for both Objective-C and Swift implementations. |
| [AEP SDK Sample App for Android](https://github.com/adobe/aepsdk-sample-app-android) | Contains Android sample app for the AEP SDK.                 |
## Contributing

Contributions are welcomed! Read the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.

## Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.

## Security policy

See the [SECURITY POLICY](SECURITY.md) for more details.
<!-- test -->
# Adobe Experience Platform Edge Mobile Extension

## BETA

AEPEdge is currently in beta. Use of this code is by invitation only and not otherwise supported by Adobe. Please contact your Adobe Customer Success Manager to learn more.

By using the Beta, you hereby acknowledge that the Beta is provided "as is" without warranty of any kind. Adobe shall have no obligation to maintain, correct, update, change, modify or otherwise support the Beta. You are advised to use caution and not to rely in any way on the correct functioning or performance of such Beta and/or accompanying materials.

## About this project

The AEP Edge Mobile extension allows you to send data to the Adobe Experience Platform (AEP) from a mobile application. This extension allows you to implement Adobe Experience Cloud capabilities in a more robust way, serve multiple Adobe solutions though one network call, and simultaneously forward this information to the Adobe Experience Platform.

The Adobe Experience Platform Edge Mobile Extension is an extension for the [Adobe Experience Platform SDK](https://github.com/Adobe-Marketing-Cloud/acp-sdks).

To learn more about this extension, read [Adobe Experience Platform Edge Mobile Extension](https://aep-sdks.gitbook.io/docs/beta/experience-platform-extension).

## Current version
The Adobe Experience Platform Edge Mobile extension for iOS is currently in Beta development.

## Installation

### Binaries

To generate an `AEPEdge.xcframework`, run the following command:

```
make archive
```

This will generate the xcframework under the `build` folder. Drag and drop all the .xcframeworks to your app target.

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
	pod 'AEPEdge', :git => 'git@github.com:adobe/aepsdk-edge-ios.git', :branch => 'main'
  	pod 'AEPCore', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'main'
  	pod 'AEPServices', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'main'
  	pod 'AEPRulesEngine', :git => 'git@github.com:adobe/aepsdk-rulesengine-ios.git', :branch => 'main'
end
```

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPEdge Package to your application, from the Xcode menu select:

`File > Swift Packages > Add Package Dependency...`

Enter the URL for the AEPEdge package repository: `https://github.com/adobe/aepsdk-edge-ios.git`.

When prompted, make sure you change the branch to `main`. (Once the repo is public, we will reference specific tags/versions instead of a branch)

Alternatively, if your project has a `Package.swift` file, you can add AEPEdge directly to your dependencies:

```
dependencies: [
	.package(url: "https://github.com/adobe/aepsdk-edge-ios.git", .branch: "dev"),
targets: [
   	.target(name: "YourTarget",
    				dependencies: ["AEPEdge"],
          	path: "your/path"),
    ]
]
```

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

## Setup Demo Application
The AEP Commerce Demo application is a sample app which demonstrates how to send commerce data to Adobe Experience Platform by using the Adobe Experience Platform Mobile Extension.

If this is the first time you use this application, start by creating the XDM Schema and Dataset required for it, as well as creating your Edge Configuration identifier. Here are the steps to [Generate Environment Identifier](https://aep-sdks.gitbook.io/docs/beta/experience-platform-extension/experience-platform-setup).

Setup the environment by running the following from the root directory of the repository:

~~~
make pod-install
~~~

Subsequently, you can make sure your environment is updated by running the following:

~~~
make pod-update
~~~

Open the AEPCommerceDemoApp workspace in Xcode by running the following command from the root directory of the repository:

~~~
make open-app
~~~

Configure the Launch Mobile Property and set up the Environment File ID in the app. Follow these steps to [Configure the demo app](https://aep-sdks.gitbook.io/docs/beta/experience-platform-extension/commerce-demo-app-setup#configure-the-demo-app).

You are now all set to start testing with this app.

## Contributing

Contributions are welcomed! Read the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.

## Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.

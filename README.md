# Adobe Experience Platform Mobile Extension


## About this project

The Experience Platform Mobile extension allows you to send data to the Adobe Experience Platform from a mobile application. This extension allows you to implement Adobe Experience Cloud capabilities in a more robust way, serve multiple Adobe solutions though one network call, and simultaneously forward this information to the Adobe Experience Platform.

The Adobe Experience Platform Mobile Extension is an extension for the [Adobe Experience Platform SDK](https://github.com/Adobe-Marketing-Cloud/acp-sdks).

## Current version
The Experience Platform Mobile extension for iOS is currently in Alpha development.

### Installation

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
From command line you can build the project for a simulator by running the following command:

~~~
make build
~~~

To build the project for release, run the following command and find the lib and .swiftmodule files under `out/AEPExperiencePlatform-<version>.zip`:

~~~
make build-all
~~~

To bundle the Commerce Demo application, run the following command and find the archive under `out/AEPCommerceDemoApp-<version>.zip`:

~~~
make archive-app
~~~

You can also run the unit test suite from command line:

~~~
make test
~~~

### Setup Demo Application
The AEP Commerce Demo application is a sample app which demonstrates how to send commerce data to Adobe Experience Platform by using the Adobe Experience Platform Mobile Extension.

Follow the command line instructions above to build the project and bundle the demo application. With both `AEPCommerceDemoApp-<version>.zip` and `AEPExperiencePlatform-<version>.zip` in the same folder, run the following commands in a terminal:

~~~
unzip AEPCommerceDemoApp-<version>.zip
unzip AEPExperiencePlatform-<version>.zip -d AEPCommerceDemoApp/libs
cd AEPCommerceDemoApp
pod install
open AEPCommerceDemoApp.xcworkspace
~~~

### Contributing

Contributions are welcomed! Read the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.

### Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.

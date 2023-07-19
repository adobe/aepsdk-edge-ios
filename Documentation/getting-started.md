# Getting started

## Before starting

The Adobe Experience Platform Edge Network extension has the following peer dependencies, which must be installed to use the Edge Network extension:
- [AEPCore](https://github.com/adobe/aepsdk-core-ios#readme)
- [AEPEdgeIdentity](https://github.com/adobe/aepsdk-edgeidentity-ios#readme)

## Configure the Edge Network extension in Data Collection UI
1. Log into [Adobe Experience Platform Data Collection](https://experience.adobe.com/data-collection).
2. From **Tags**, locate or search for your Tag mobile property.
3. In your mobile property, select **Extensions** tab.
4. On the **Catalog** tab, locate or search for the **Adobe Experience Platform Edge Network** extension, and select **Install**.
5. Select the **Datastream** you would like to use per environment. Read more about [datastreams](#datastreams) below.
6. Set up the **Domain configuration** by either using the automatically populated domin, or a first party domain mapped to an Adobe-provisioned Edge Network domain. For more information, see [domain configuration](#domain-configuration) below.
7. Select **Save**.
8. Follow the [publishing process](https://developer.adobe.com/client-sdks/documentation/getting-started/create-a-mobile-property/#publish-the-configuration) to update SDK configuration.

### Datastreams

If no datastream was previously created, see [Configure datastreams](https://developer.adobe.com/client-sdks/documentation/getting-started/configure-datastreams/) before moving to the next step.

Select the desired datastream per each environment from the corresponding drop-down lists. If your organization uses multiple sandboxes, select the **Sandbox** first, then select the **Datastream** for each environment.

The datastream used by the client-side implementation is one of the following:

- the _Production_ environment configuration when the Data Collection Tags library is published to production (in the Published column in the publishing flow).
- the _Staging_ environment configuration when the Data Collection Tags library is published to staging (in the Submitted column in the publishing flow).
- the _Development_ environment configuration when the Data Collection Tags library is in development (in the Development column in the publishing flow).

### Domain configuration

The value under the **Edge Network domain** field is used for requests to Adobe Experience Platform Edge Network and it usually follows the format `<company>.data.adobedc.net`, where `<company>` is the unique namespace associated to your Adobe organization.

If you have a first-party domain mapped to the Adobe-provisioned Edge Network domain, you can enter it here. For more details about how to configure or maintain a first-party domain, see [Adobe-Managed Certificate Program](https://experienceleague.adobe.com/docs/core-services/interface/administration/ec-cookies/cookies-first-party.html?lang=en#adobe-managed-certificate-program).

> **Note**
> The domain name is expected to be just the domain without any protocol or trailing slashes. If no domain is provided, by default the `edge.adobedc.net` domain is used.

## Add the Edge Network extension to your app

### Download the Edge extension

#### Using Swift Package Manager

To add the AEPEdge Package to your application, from the Xcode menu select:

`File > Add Packages...`

> **Note**
>  The menu options may vary depending on the version of Xcode being used.

Enter the URL for the AEPEdge package repository: `https://github.com/adobe/aepsdk-edge-ios.git`.

When prompted, input a specific version or a range of versions for Version rule.

Alternatively, if your project has a `Package.swift` file, you can add AEPEdge directly to your dependencies:

```swift
dependencies: [
  .package(url: "https://github.com/adobe/aepsdk-core-ios.git", .upToNextMajor(from: "4.0.0"))
  .package(url: "https://github.com/adobe/aepsdk-edge-ios.git", .upToNextMajor(from: "4.0.0"))
  .package(url: "https://github.com/adobe/aepsdk-edgeidentity-ios.git", .upToNextMajor(from: "4.0.0"))
],
targets: [
    .target(name: "YourTarget",
        dependencies: ["AEPCore", "AEPEdge", "AEPEdgeIdentity"],
            path: "your/path")
]
```

#### Using CocoaPods

1. Add the Mobile Core and Identity for Edge Network extensions to your project using CocoaPods. Add the following pods in your `Podfile`:

  ```ruby
  use_frameworks!
  target 'YourTargetApp' do
     pod 'AEPCore'
     pod 'AEPEdge'
     pod 'AEPEdgeIdentity'
  end
  ```

2. Install [CocoaPods](https://cocoapods.org/) dependencies. Replace `YourTargetApp` and then, in the `Podfile` directory, type:

  ```bash
  $ pod install
  ```

### Import and register Edge extension

Import the Mobile Core, Edge Network, and Identity for Edge Network libraries and register the Edge Network and Identity for Edge Network extensions with MobileCore:

#### Swift
  ```swift
  // AppDelegate.swift
  import AEPCore
  import AEPEdge
  import AEPEdgeIdentity
  ```

  ```swift
  // AppDelegate.swift
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    MobileCore.registerExtensions([Identity.self, Edge.self], {
       MobileCore.configureWith(appId: "yourEnvironmentID")
     })
     ...
  }
  ```

#### Objective-C
  ```objectivec
  // AppDelegate.h
  @import AEPCore;
  @import AEPEdge;
  @import AEPEdgeIdentity;
  ```

  ```objectivec
  // AppDelegate.m
  - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
      [AEPMobileCore registerExtensions:@[AEPMobileEdgeIdentity.class, AEPMobileEdge.class] completion:^{
      ...
    }];
    [AEPMobileCore configureWithAppId: @"yourEnvironmentID"];
    ...
  }
  ```

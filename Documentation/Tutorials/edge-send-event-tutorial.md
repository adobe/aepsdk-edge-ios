# Implementing the Edge extension to send event data to the Edge Network

## Table of Contents
- [Implementing the Edge extension to send event data to the Edge Network](#implementing-the-edge-extension-to-send-event-data-to-the-edge-network)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
    - [Environment](#environment)
  - [Adobe Experience Platform setup](#adobe-experience-platform-setup)
    - [1. Create a schema](#1-create-a-schema)
    - [2. Create a datastream](#2-create-a-datastream)
    - [3. Create a property](#3-create-a-property)
    - [4. Configure a Rule to Forward Lifecycle metrics to Platform](#4-configure-a-rule-to-forward-lifecycle-metrics-to-platform)
      - [Create a rule](#create-a-rule)
      - [Select an event](#select-an-event)
      - [Define the action](#define-the-action)
      - [Save the rule and rebuild your property](#save-the-rule-and-rebuild-your-property)
    - [5. Publish changes](#5-publish-changes)
  - [Client-side implementation](#client-side-implementation)
    - [1. Get a copy of the files (tutorial app code) and initial setup](#1-get-a-copy-of-the-files-tutorial-app-code-and-initial-setup)
    - [1. Install the Edge extensions using dependency manager (CocoaPods)](#1-install-the-edge-extensions-using-dependency-manager-cocoapods)
    - [2. Update tutorial app code to enable Edge features](#2-update-tutorial-app-code-to-enable-edge-features)
    - [Consent for Edge extension](#consent-for-edge-extension)
    - [Identity for Edge extension](#identity-for-edge-extension)
    - [Lifecycle for Edge extension](#lifecycle-for-edge-extension)
    - [3. Run app](#3-run-app)
    - [4. `sendEvent` implementation examples](#4-sendevent-implementation-examples)
  - [Validation with Assurance](#validation-with-assurance)
    - [1. Set up the Assurance session](#1-set-up-the-assurance-session)
    - [2. Connect to the app](#2-connect-to-the-app)
    - [3. Assurance Event transactions view - check for Edge events](#3-assurance-event-transactions-view---check-for-edge-events)

## Overview
This hands-on tutorial provides end-to-end instructions on how to implement the Edge extension to send event data to the Edge Network from a fresh implementation state.

```mermaid
graph LR;
    step1(Set up configuration for<br/>Adobe Experience Platform) --> 
    step2(Enable Edge features in app<br/>Send event data to the Edge Network) --> 
    step3(Add Assurance<br/>Verify event data formats)
```

### Environment
- macOS machine with a recent version of Xcode installed
- Cocoapods installed

## Adobe Experience Platform setup
Before any app changes we need to set up some configuration items on the Adobe Experience Platform (AEP) side. The end goal of this section is to create a mobile property that controls the configuration settings for the various AEP extensions used in this tutorial.

First we need to create an XDM schema (the format for data that the Edge Network uses) and configure a datastream (controls where the data will go). 

### 1. Create a schema  
At a high level, a schema is a definition for the structure of your data; what properties you are expecting, what format they should be in, and checks for the actual values coming in.  

1. Go to the [Adobe Experience Platform](https://experience.adobe.com/#/platform), using your Adobe ID credentials to log in if prompted.

2. Navigate to the Data Collection UI by clicking the nine-dot menu in the top right (**1**), and selecting `Data Collection` (**2**)  
<img src="../Assets/edge-send-event-tutorial/aep-data-collection.png" alt="Going from Assurance to Data Collection" width="1100"/>

1. Click `Schemas` in the left navigation window  
<img src="../Assets/edge-send-event-tutorial/data-collection-tags.png" alt="Going from Assurance to Data Collection" width="1100"/>

4. In the schemas view, click the `+ Create schema` button in the top right (**1**), then select `XDM ExperienceEvent` (**2**)
<img src="../Assets/edge-send-event-tutorial/data-collection-schemas.png" alt="Creating new XDM ExperienceEvent schema" width="1100"/>

Once in the new schema creation view, notice the schema class is `XDM ExperienceEvent` (**1**); schemas adhere to specific class types which just means that they have some predefined properties and behaviors within the Edge platform. In this case, `XDM ExperienceEvent` creates the base properties you see in the `Structure` section that help define some baseline data for each Experience Event. 

5. Give the new schema a name and description (**2**) to help identify it.
6. Click the `+ Add` button (**3**) next to the `Field groups` section under `Composition`.

<details>
  <summary> What is a field group?</summary><p>

A schema is made up of building blocks called field groups.

Think of field groups as blueprints for specific groups of data; the data properties describing things like: the current device in use, products and contents/state of carts, information about the users themselves, etc. 

For example, the `Commerce Details` field group has properties for common commerce-related data like: 
- Product information (SKU, name, quantity)
- Cart state (abandons, product add sources, etc.). 
 
This logical grouping helps organize individual data properties into easily understandable sections. They are even reusable! Once you define a field group, you can use it in any schema that has a compatible class (some field groups only make sense with the capabilities of certain schema classes). There are two types of field groups available:

1. Adobe defined - standardized templates of common use-cases and datasets created and updated by Adobe
    - Note that Adobe Experience Platform services implicitly understand standard field groups and can provide additional functionality on top of just reading and writing data. That's why it is strongly recommended that you use standard field groups wherever possible.
2. Custom defined - any field group outside of the Adobe defined ones that users can use to create their own custom collections of data properties  

See the [Field Groups section in the Basics of schema composition](https://experienceleague.adobe.com/docs/experience-platform/xdm/schema/composition.html?lang=en#field-group) for an in depth look at how field groups work in the context of XDM schemas.

</p></details>

<img src="../Assets/edge-send-event-tutorial/schema-creation.png" alt="Initial schema creation view" width="1100"/>

In our case, we're going to add three Adobe defined field groups to our schema:  
- AEP Mobile Lifecycle Details
- Adobe Experience Edge Autofilled Environment Details
- Commerce Details

You can use the search box (**1**) to look up the names (**2**) of the three field groups required for this section. Note the owner of each of the schemas should be **Adobe** (**3**).
<img src="../Assets/edge-send-event-tutorial/schema-field-group-1.png" alt="Add field group to schema" width="1100"/>

<details>
  <summary> Hints for using the <b>Add field groups</b> tool</summary><p>

(<b>1</b>) The Industry filter selections let you quickly narrow down field groups based on the selected industry; another useful tool to find relevant field groups for your use-case.

(<b>2</b>) The inspector icon lets you see the field group structure, and the info icon presents a card with the field group name, industry, and description.

(<b>3</b>) Popularity: shows how many organizations are using the field group across the Adobe Experience Platform; can potentially be a good place to start in terms of finding which field groups may be the most useful for your needs.

(<b>4</b>) Selected field groups are shown on the right side of the window, where you can quickly see what field groups have been selected so far, and remove individual or all field groups from the current add session.  

<img src="../Assets/edge-send-event-tutorial/schema-field-group-hints.png" alt="Add field group window hints" width="1100"/>  

</p></details>

Verify that all the required field groups are present in the right side info panel (**1**), then click **Add field groups** (**2**). 
<img src="../Assets/edge-send-event-tutorial/schema-field-group-selected.png" alt="Add required field groups" width="1100"/>  

Verify that the required field groups are present under the **Field groups** section (**1**) and the properties associated with those field groups are present under the **Structure** section (**2**), then click **Save** (**3**).
<img src="../Assets/edge-send-event-tutorial/schema-with-field-groups.png" alt="Schema with required field groups" width="1100"/>  

<details>
  <summary> Hints for using the schema creator tool </summary><p>

To quickly see what properties are from a given field group, click the field group under the **Field groups** section (**1**). The properties are highlighted in the **Structure** section (**2**).

<img src="../Assets/edge-send-event-tutorial/schema-tool-selection.png" alt="Schema tool selecting a field group example" width="1100"/>  

To see only the properties from a given field group, click the selection box next to the field group (**1**). The properties are filtered to only the selected field group in the **Structure** section (**2**).

<img src="../Assets/edge-send-event-tutorial/schema-tool-filtering.png" alt="Schema tool filtering on a field group example" width="1100"/>  

</p></details>

### 2. Create a datastream

<details>
  <summary> What is a datastream? </summary><p>

A datastream is a server-side configuration on Platform Edge Network that controls where data goes. Datastreams ensure that incoming data is routed to Adobe Experience Cloud applications and services (like Analytics) appropriately. For more information, see the [datastreams documentation](https://experienceleague.adobe.com/docs/experience-platform/edge/datastreams/overview.html?lang=en) or this [video](https://experienceleague.adobe.com/docs/platform-learn/data-collection/edge-network/configure-datastreams.html?lang=en).

In order to send data to the Edge Network, the datastream must be configured with the Adobe Experience Platform service.

</p></details>

Click **Datastreams** under **DATA COLLECTION** in the left side navigation panel.

<img src="../Assets/edge-send-event-tutorial/datastreams-navigation.png" alt="Datastream in Data Collection Navigation" width="1100"/>  

Click **New Datastream** in the top right.

<img src="../Assets/edge-send-event-tutorial/datastreams-main-view.png" alt="Create new datastream" width="1100"/>  

Give the datastream an identifying name and description (**1**), then pick the schema created in the previous section using the dropdown menu (**2**). Then click **Save** (**3**). We will be returning to this datastream later on.

<img src="../Assets/edge-send-event-tutorial/datastreams-new-datastream.png" alt="Set datastream values" width="1100"/>  

### 3. Create a property

Next, we need to create a property for mobile. A property is basically a bundled configuration for AEP extensions. It controls the configuration settings available for each extension, allowing you to modify their functionality. 

Click **Tags** (**1**) under **DATA COLLECTION** in the left-side navigation panel.

<img src="../Assets/edge-send-event-tutorial/data-collection-tags-navigation.png" alt="Navigating to tags" width="1100"/>  

Click **New Property** (**1**) to create a new property.

<img src="../Assets/edge-send-event-tutorial/tags-main-view.png" alt="Navigating to tags" width="1100"/>  

Enter an identifying name for the new property in the **Name** textfield (**1**), select **Mobile** (**2**) under **Platform**, then click **Save** (**3**).

<img src="../Assets/edge-send-event-tutorial/tags-create-property.png" alt="Navigating to tags" width="1100"/>  

Find and click the mobile property for this tutorial (**2**), optionally using the search box to help quickly narrow down the search (**1**).

<img src="../Assets/edge-send-event-tutorial/property-search.png" alt="Finding desired mobile property" width="1100"/>  

Click **Extensions** (**2**) in the left-side navigation panel, under **AUTHORING**. Notice there are some extensions are that installed by default (**1**).

<img src="../Assets/edge-send-event-tutorial/mobile-property-extensions.png" alt="Finding desired mobile property" width="1100"/>  

Click **Catalog** (**1**) and (optionally) use the search box (**2**) to find the required extensions; click the **Install** button in an extension card to install the extension. 

<img src="../Assets/edge-send-event-tutorial/mobile-property-catalog.png" alt="Catalog search example" width="1100"/>  

We will be installing the following AEP extension configurations:

<details>
  <summary> Adobe Experience Platform Edge Network </summary><p>

Open the **Catalog** and install the `Adobe Experience Platform Edge Network` extension configuration.

<img src="../Assets/edge-send-event-tutorial/mobile-property-catalog-edge.png" alt="Catalog search for Adobe Experience Platform Edge Network" width="1100"/>  

In the extension configuration settings window, set the datastream for each environment (**1**) to the one created for this tutorial. Then click `Save` (**2**)

<img src="../Assets/edge-send-event-tutorial/mobile-property-edge-settings.png" alt="Edge extension settings" width="1100"/>  

</p></details>

<details>
  <summary> Identity </summary><p>

Open the **Catalog** and install the **Identity** extension configuration. There are no settings for this extension.

<img src="../Assets/edge-send-event-tutorial/mobile-property-catalog-identity.png" alt="Catalog search for Identity" width="1100"/>  

</p></details>

<details>
  <summary> Consent </summary><p>

Open the **Catalog** and install the **Consent** extension configuration.

<img src="../Assets/edge-send-event-tutorial/mobile-property-catalog-consent.png" alt="Catalog search for Consent" width="1100"/>  

In the extension configuration settings window, the **Default Consent Level** should be set to **Yes** by default (**1**); for the tutorial app this setting is fine as-is, however when using this configuration in production apps, it should reflect the requirements of the company's actual data collection policy for the app. 

<img src="../Assets/edge-send-event-tutorial/mobile-property-consent-settings.png" alt="Consent extension settings" width="1100"/>  

</p></details>

You should see the following after all the extensions are installed: 

<img src="../Assets/edge-send-event-tutorial/mobile-property-edge-extensions.png" alt="All installed extensions" width="1100"/>  

### 4. Configure a Rule to Forward Lifecycle metrics to Platform

The Lifecycle for Edge Network extension dispatches application foreground and background events to the Mobile SDK. Create a rule to forward these events to the Adobe Experience Platform Edge Network.

#### Create a rule
1. On the Rules tab, select Create New Rule.
2. Give your rule an easily recognizable name in your list of rules. In this example, the rule is named "Forward Lifecycle XDM events to Edge Network".

> **Info**  
> If you do not have existing rules for this property, the Create New Rule button will be in the middle of the screen. If your property has rules, the button will be in the top right of the screen.

#### Select an event
1. Under the Events section, select Add.
2. From the Extension dropdown list, select Mobile Core.
3. From the Event Type dropdown list, select Foreground.
4. Select Keep Changes.
5. Under the Events section again, select the plus icon to add another Event.
6. From the Extension dropdown list, select Mobile Core.
7. From the Event Type dropdown list, select Background.
8. Select Keep Changes.

<img src="../Assets/edge-send-event-tutorial/lifecycle-rule-1.png" alt="All installed extensions" width="1100"/>  

#### Define the action
1. Under the Actions section, select Add.
2. From the Extension dropdown list, select Adobe Experience Platform Edge Network.
3. From the Action Type dropdown list, select Forward event to Edge Network.
4. Select Keep Changes.

<img src="../Assets/edge-send-event-tutorial/lifecycle-rule-2.png" alt="All installed extensions" width="1100"/>  

#### Save the rule and rebuild your property
1. After you complete your configuration, verify that your rule looks like the following:
2. Select Save.
3. Rebuild your mobile property and deploy it to the correct environment.

<img src="../Assets/edge-send-event-tutorial/lifecycle-rule-3.png" alt="All installed extensions" width="1100"/>  

### 5. Publish changes
1. Click **Publishing Flow** under **PUBLISHING** in the left-side navigation window.
2. Click **Add Library** in the top left.
3. Set a name for the property, and set the environment to Development
4. Click **Add All Changed Resources** 
5. Click **Save & Build to Development**

## Client-side implementation

Now that the server side configuration is complete, we can install the extensions in the app and enable extension functionality by making some code updates.

### 1. Get a copy of the files (tutorial app code) and initial setup
1. Open the code repository: https://github.com/adobe/aepsdk-edge-ios/tree/dev
2. Click **Code** in the top right 
3. In the window that opens, click **Download ZIP**; by default it should land in your **Downloads** folder.
   - Optionally, move the ZIP to your **Documents** folder
4. Unzip the archived file by double clicking it, and keep this Finder window open, as we will need it later.

Now we can use the tutorial app to go through the changes required to install the Edge extension.

5. Open the Terminal app
   - **Applications** -> **Utilities** -> **Terminal**
   - Open Spotlight search (CMD + Space) and search for "terminal", the select the **Terminal** app to open it.
6. Type the following characters, but do not press return yet: `c` + `d` + `SPACE`  
You should see the following in your terminal: "cd " (the space after `cd` is important!).
```bash
cd 
```
7. Return to your Finder window that has the unzipped repository folder. Click and drag the folder into your Terminal window that has the `cd ` command typed. You should see something like: `cd /Users/tim/Documents/aepsdk-edge-ios/Tutorials/EdgeTutorialAppStart`  
8. Then press `return` to execute the command.

<details>
  <summary> What is <code>cd</code>? What did I just do? </summary><p>

`cd` is the terminal command for change directory; the command above changes your terminal's active directory to the repository we just copied.

The long string after is the full path (kind of like an address) to the code repository folder: `/Users/tim/Documents/aepsdk-edge-ios/Tutorials/EdgeTutorialAppStart`, taken together, this command changes our terminal window context to the tutorial app code folder!

</p></details>

Now that we're in the project directory, there's some setup we have to do; the app depends on packages which are not installed with the repository. To install them, run the command:

```bash
pod update
```

<details>
  <summary> Using Swift package manager instead? </summary><p>

**Swift Package Manager**
This tutorial assumes a project using Cocoapods for package dependency management, but if following along with a project that uses Swift package manager, refer to the [README for instructions on how to add the EdgeBridge package](../../README.md#swift-package-managerhttpsgithubcomappleswift-package-manager).

</p></details>

You should see the dependency manager CocoaPods installing the various packages required by the project. 

<details>
  <summary> Expected output </summary><p>

```
tim@Tims-MacBook-Pro aepsdk-edgebridge-ios % pod update
Update all pods
Updating local specs repositories
Analyzing dependencies
Downloading dependencies
Installing AEPAssurance (3.0.1)
Installing AEPCore (3.7.1)
Installing AEPEdge (1.4.1)
Installing AEPEdgeConsent (1.0.1)
Installing AEPEdgeIdentity (1.1.0)
Installing AEPLifecycle (3.7.1)
Installing AEPRulesEngine (1.2.0)
Installing AEPServices (3.7.1)
Generating Pods project
Integrating client project
Pod installation complete! There are 7 dependencies from the Podfile and 8 total pods installed.
tim@Tims-MacBook-Pro aepsdk-edgebridge-ios % 
```

</p></details>

### 1. Install the Edge extensions using dependency manager (CocoaPods)
With the project set up, our next task is to install the Edge extensions for our tutorial app. We can easily do this by updating the file that controls the package dependencies for the repository. 

1. Open the project using the command:
```bash
open EdgeTutorialAppStart.xcworkspace
```

This should automatically open the Xcode IDE. In Xcode:
1. Click the dropdown chevron next to `Pods` in the left-side navigation panel.
2. Click the `Podfile` file.   
   
You should see a section like the following: 

```ruby
target 'EdgeTutorialAppStart' do
=begin
  pod 'AEPAssurance'
  pod 'AEPCore'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent'
  pod 'AEPEdgeIdentity'
  pod 'AEPLifecycle'
  pod 'AEPServices'
=end
end
```
Add a pound symbol `#` in front of the `=begin` and `=end` like so:

```ruby
target 'EdgeTutorialAppStart' do
#=begin
  pod 'AEPAssurance'
  pod 'AEPCore'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent'
  pod 'AEPEdgeIdentity'
  pod 'AEPLifecycle'
  pod 'AEPServices'
#=end
end
```

<details>
  <summary> What does the <code>#</code> do? </summary><p>

The `#` symbol is how to comment out lines of code in the programming language Ruby (which our Podfile is written in). Commenting out code allows you to quickly deactivate code, or write documentation/notes. In our case, we're commenting out the lines that create a block comment (the multi-line version of comments) in Ruby, activating all the code between those two lines!

</p></details>

3. Go back to your terminal window and run:
```bash
pod update
```
Cocoapods will use the newly updated configuration file to install the new packages (all of the new Edge extensions we want!), which will allow us to use the Edge extensions' features in the app's code. 

### 2. Update tutorial app code to enable Edge features
There are three files we need to update to enable the features we want from the Edge extension. Thankfully, all of the code changes are contained in block comments like the Podfile so you only have to make a few updates!

1. Click the dropdown chevron next to `EdgeTutorialAppStart` in the left-side navigation panel to open the project.
2. Click the dropdown chevron next to `EdgeTutorialAppStart` to open the directory holding the code files.
3. Click the `AppDelegate.swift` file.
4. First update the `ENVIRONMENT_FILE_ID` value to the mobile property ID published in the first section.

Inside this file, you will see code blocks for this tutorial that are greyed out, because they are block commented out. They are marked by the header and footer:  
`Edge Tutorial - code section (n/m)`  
Where `n` is the current section and `m` is the total number of sections in the file.

To activate the code, simply add a forward slash `/` at the front of the header:
```swift
/* Edge Tutorial - code section (1/2)
```
To:
```swift
//* Edge Tutorial - code section (1/2)
```
Make sure to uncomment all sections within the file (the total will tell you how many sections there are).

<details>
  <summary> What am I uncommenting in <code>AppDelegate.swift</code>? </summary><p>

**Section 1**: imports the various Edge extensions and other AEP extensions that enable sending event data to Edge, and power other features. The `import` statement makes it available to use in the code below.

**Section 2**: In order:
1. Sets the log level of Core (which handles the core functionality used by extensions, like networking, data conversions, etc.) to `trace`, which provides more granular details on app logic; this can be helpful in debugging or troubleshooting issues.
2. This sets the environment file ID which is the mobile property configuration we set up in the first section; this will apply the extension settings in our app.
3. Registers the extensions with Core, getting them ready to run in the app.

**Section 3**: Enables deep linking to connect to Assurance (which we will cover in depth in a later section); this is the method used for iOS versions 12 and below.

</p></details>

Repeat this process for the `SceneDelegate.swift` and `ContentView.swift` files.

<details>
  <summary> What am I uncommenting in <code>SceneDelegate.swift</code>? </summary><p>

**Section 1**: Imports the Assurance (covered later) and Core extensions for use in the code below.

The next two code sections are functionality that is enabled by the [AEP Lifecycle](https://aep-sdks.gitbook.io/docs/foundation-extensions/lifecycle-for-edge-network) extension; the extension's main purpose is to track the app's state, basically when the app starts, or is closed, or crashes, etc.

**Section 2**: Enables the [`lifecycleStart` API](https://aep-sdks.gitbook.io/docs/foundation-extensions/mobile-core/lifecycle/lifecycle-api-reference#lifecycle-start) that tracks when the app is opened.

**Section 3**: Enables the [`lifecyclePause` API](https://aep-sdks.gitbook.io/docs/foundation-extensions/mobile-core/lifecycle/lifecycle-api-reference#lifecycle-pause) that tracks when the app is closed.

Notice that both of these APIs rely on the developer to place them in the proper iOS app lifecycle functions; that is, iOS has built-in functions that are called by the operating system that give the app notices that it is about to enter an active state, or go into a background state, etc. A proper Lifecycle extension implementation requires that the developer places the API calls in the required iOS lifecycle functions. See the full guide on [implementing Lifecycle](https://aep-sdks.gitbook.io/docs/foundation-extensions/mobile-core/lifecycle).

**Section 4**: Enables deep linking to connect to Assurance; this is the method used for iOS versions 13 and above.

</p></details>

<details>
  <summary> What am I uncommenting in <code>ContentView.swift</code>? </summary><p>

**Section 1**: Imports the Core extension for use in the code below.

**Section 2**: Creates an Experience Event with an event payload that conforms to the XDM schema we set up earlier. This event is an example of a product add.

**Section 3**: Creates an Experience Event with an event payload that conforms to the XDM schema we set up earlier. This event is an example of a product view.

</p></details>

### Consent for Edge extension
The [Consent for Edge](https://aep-sdks.gitbook.io/docs/foundation-extensions/consent-for-edge-network) mobile extension enables you to collect user data tracking consent preferences from your mobile app when using AEP and the Edge extension. The default consent settings should be set in alignment with your organization's user data privacy requirements. See the guide on [ingesting data using the Consents and Preferences data type](https://experienceleague.adobe.com/docs/experience-platform/xdm/data-types/consents.html#ingest).

[API documentation](https://aep-sdks.gitbook.io/docs/foundation-extensions/consent-for-edge-network/api-reference)

### Identity for Edge extension
The [Identity for Edge](https://aep-sdks.gitbook.io/docs/foundation-extensions/identity-for-edge-network) mobile extension enables identity management when using AEP and the Edge extension. You can control IDs associated with the user like custom IDs, advertising IDs, etc.

[API documentation](https://aep-sdks.gitbook.io/docs/foundation-extensions/identity-for-edge-network/api-reference)

### Lifecycle for Edge extension
The [Lifecycle for Edge](https://aep-sdks.gitbook.io/docs/foundation-extensions/lifecycle-for-edge-network) extension enables you to collect app lifecycle data from your mobile app when using AEP and the Edge extension. This includes data like app start, stop, and crashes, device type, device OS, etc.

[API documentation](https://aep-sdks.gitbook.io/docs/foundation-extensions/mobile-core/lifecycle/lifecycle-api-reference)

### 3. Run app   
In Xcode: 
1. Set the app target (**1**) to **EdgeTutorialAppStart** (if not already).
2. Choose which destination device (**2**) to run it on (either simulator or physical device. In this case it is set to the iPhone 13 Pro simulator). 
3. Click the play button (**3**).

<img src="../Assets/edge-send-event-tutorial/xcode-install-app.png" alt="Creating a new session in Assurance step 1" width="1100"/>

You should see your application running on the device you selected, with logs being displayed in the debug console in Xcode. 

<img src="../Assets/edge-send-event-tutorial/app-first-launch.png" alt="Creating a new session in Assurance step 1" width="400"/>

> **Note**
> If the debug console area is not shown by default, activate it by selecting:  
> View -> Debug Area -> Show Debug Area

### 4. `sendEvent` implementation examples   
With Edge extension successfully installed and registered, you can make `sendEvent` calls, which will be processed by the Edge extension and sent to the Edge network.

Check `ContentView.swift` for implementation examples of product add and view events. You can see the data payloads that are to be sent with the calls. Notice that they conform to the Commerce XDM schema structure we set up in the first section.

The first button shows an example of using an XDM object that adheres to the `XDMSchema` protocol provided by the Edge extension; basically, this is a way to construct the event data using a structured blueprint with value checks and other handy developer features. It gives developers a more robust framework to interact with the data values.

The second button shows an example of using a data dictionary to construct the event data. This method provides more flexibility, but can potentially be more error prone. 

## Validation with Assurance
With the server side configuration and app setup complete, we can take a look at the live event flow using Assurance, the AEP tool for inspecting all events that Adobe extensions send out in real time. Using Assurance, we can see the Experience Events sent out by the Edge extension are formatted how we want.

### 1. Set up the Assurance session  
1. In the browser, navigate to [Assurance](https://experience.adobe.com/griffon) and login using your Adobe ID credentials.
2. Click **Create Session** in the top right.
![Create session in Assurance](../Assets/edge-send-event-tutorial/assurance-create-session.jpg)  
3. In the **Create New Session** dialog, click **Start** (**1**)  
<img src="../Assets/edge-send-event-tutorial/assurance-create-session-1.png" alt="Creating a new session in Assurance step 1" width="400"/>

4. Enter a name (**1**) to identify the session (can be any desired name) 
5. Use Base URL value (**2**) (including the colon and double forward slashes!): `aepedgetutorialappstart://`   
6. Click **Next** (**3**)  
<img src="../Assets/edge-send-event-tutorial/assurance-create-session-2.png" alt="Creating a new session in Assurance step 2" width="400"/>

<details>
  <summary> What is a base URL? </summary><p>

The Base URL is the ID used launch your app via deep linking. An Assurance session URL is generated by combining this app ID with the Assurance session's own unique ID. For example in the session URL:  
`myapp://?adb_validation_sessionid=a3a1b9d5-0b1e-40bf-a732-954ed1d6491f`  
In its component parts:  
1. `myapp://` is the ID required by the device's operating system to open the correct app  
2. `?adb_validation_sessionid=a3a1b9d5-0b1e-40bf-a732-954ed1d6491f` is the unique session ID Assurance uses to initiate the connection to your session.

In total, to connect an app to Assurance you need:  
On the app side:
1. The app URL to be set to a unique value
2. Code to accept opening the app via deep linking, and what to do with the incoming Assurance session ID (in our case, using it to initiate a connection with our Assurance session; examples of this can be found in the tutorial app)

On the Assurance session side:
1. The base URL to be set to the same value as the app URL (Assurance handles the rest of the connection link setup)

> **Note**  
> In Xcode the app URL can be configured using these steps:
> 1. Select the project in the navigator.
> 2. Select the app target in the `Targets` section, in the project configuration window.
> 3. Select the `Info` tab.
> 4. Set the desired deep linking URL.
> ![Xcode deeplink app url config](../Assets/edge-send-event-tutorial/xcode-deeplink-app-url-config.jpg)
> Please note that there is still code on the application side that is required for the app to respond to deep links; see the [guide on adding Assurance to your app](https://aep-sdks.gitbook.io/docs/foundation-extensions/adobe-experience-platform-assurance#add-the-aep-assurance-extension-to-your-app). For general implementation recommendations and best practices, see Apple's guide on [Defining a custom URL scheme for your app](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)

</p></details>


When presented with this window, your new Assurance session is ready to go, and it is now possible to connect the app to the session.  
<img src="../Assets/edge-send-event-tutorial/assurance-create-session-qr.png" alt="Creating a new session in Assurance step 3 - QR code" width="400"/>
<img src="../Assets/edge-send-event-tutorial/assurance-create-session-link.png" alt="Creating a new session in Assurance step 3 - Session link" width="400"/>

### 2. Connect to the app   

<details>
  <summary> Details on connecting to Assurance </summary><p>

There are two primary ways to connect an app instance to an Assurance session:
1. QR Code: available with **Scan QR Code** option selected. Only works with physical devices, as it requires a physical device's camera to scan the code.
2. Session Link: available with **Copy Link** option selected. Works with both physical and simulated devices.

Note that both methods require setup on the app code side to allow for deep linking (see the section **What is a base URL?** under [Set up the Assurance session](#1-set-up-the-assurance-session)).

To access these connection methods, click **Session Details** in the top right of the Assurance session page:  
<img src="../Assets/edge-send-event-tutorial/assurance-session-details-qr.png" alt="Assurance Session Details - QR code" width="400"/>
<img src="../Assets/edge-send-event-tutorial/assurance-session-details-link.png" alt="Assurance Session Details - Session link" width="400"/>

You can edit both the **Session Name** and **Base URL**; changes to the **Base URL** value will automatically be reflected in both the QR code and session link.

</p></details>

To connect to Assurance, we will use the session link method:
1. Copy the session link; you can click the icon of a double overlapping box to the right of the link to copy it.
    - If using a physical device, it may be helpful to have a way to send this link to the device (ex: Airdrop, email, text, etc.). Alternatively, you can use the camera on your physical device to scan the QR code.
2. Open Safari (or other web browser).
3. Paste the Assurance session link copied from step 1 into the URL/search text field and enter, or use **Paste and Go**.
    - If using the simulator, it is possible to enable the paste menu by clicking in the text field twice, with a slight pause between clicks.
4. A new dialog box should open requesting to open the tutorial app, tap **OK** (**1**).

<img src="../Assets/edge-send-event-tutorial/assurance-ios-link-connection.png" alt="Assurance Session Details - Session link" width="400"/>
<img src="../Assets/edge-send-event-tutorial/assurance-ios-link-connection-dialog.png" alt="Assurance Session Details - Session link" width="400"/>  

5. App should open and show the Assurance PIN screen to authenticate the session connection; enter the PIN from the session details and tap **Connect** (**1**).

<img src="../Assets/edge-send-event-tutorial/assurance-ios-pin.png" alt="Assurance Session Start - iOS simulator" width="400"/>

<details>
  <summary> Help! I got an error, what do I do? </summary><p>

When using the link, if you see the error: "Safari cannot open the page because the address is invalid"

<img src="../Assets/edge-send-event-tutorial/assurance-ios-link-connection-error.png" alt="Assurance Session Details - Session link" width="400"/>  

1. Make sure that the base URL for the Assurance session is set to the correct value (`aepedgetutorialappstart://`), and try recopying the link and submitting again.
   - For instructions on how to change the base URL value, see the section **Details on connecting to Assurance** under [Connect to the app](#2-connect-to-the-app)
2. Make sure that the tutorial app is installed on the device. If it was already installed, try uninstalling it and reinstalling it.

If in the app, after entering the PIN code and tapping **Connect**, you see the error: "Invalid Mobile SDK Configuration The Experience Cloud organization identifier is unavailable. Ensure SDK configuration is setup correctly. See documentation for more detail."

1. Make sure that the mobile property used has Assurance installed, and that the property has been properly published.
2. Make sure that the mobile property ID is set in the `ENVIRONMENT_FILE_ID` variable in `AppDelegate.swift`, then rebuild the app.

</p></details>


<details>
  <summary> Connecting using QR code </summary><p>

To connect using QR code:
Prerequisites (see [Set up the Assurance session](#1-set-up-the-assurance-session) for details on QR code requirements):
- Running app on a **physical device** with camera that can scan QR codes
- App URL for deep linking is configured
- App code for receiving link and connecting to Assurance is implemented

1. Use physical device's camera to scan the QR code, which when tapped, should trigger a confirmation dialog to open the app.
2. App should open and show the Assurance PIN screen to authenticate the session connection; enter the PIN from the session details and tap **Connect**

</p></details>

Once connected to Assurance, in the tutorial app, an Adobe Experience Platform icon (**1**) will appear in the top right corner of the screen with a green dot indicating a connected session.  
<img src="../Assets/edge-send-event-tutorial/ios-assurance-connection.png" alt="Assurance Session Start - Web UI after connection" width="400"/>  

In the web-based Assurance session, there is also an indicator in the top right that shows the number of connected sessions (which in this case should now show a green dot with "1 Client Connected" (**1**)).  
<img src="../Assets/edge-send-event-tutorial/assurance-session-start.jpg" alt="Assurance Session Start - Web UI after connection" width="800"/>  

Notice how in the Assurance session Events view (**2**), there are already events populating as a consequence of the connection of the mobile app to the Assurance session (**3**); the Assurance extension itself emits events about the session connection and subsequently captures these events to display in the web-based session viewer. You can expect Assurance to capture all events processed by the AEP SDK from all other extensions as well.  

### 3. Assurance Event transactions view - check for Edge events  
In order to see Edge events, in the connected app instance:
1. Tap either **Product add event** or **Product view event** to send an Experience Event to the Edge Network! 
   - Behind the scenes the buttons use the `sendEvent` API from the Edge extension. This event will be captured by the Assurance extension and shown in the web session viewer.

<img src="../Assets/edge-send-event-tutorial/ios-trigger-event.png" alt="Simulator tracking buttons" width="400"/>

1. Click the `AEP Request Event` event (**1**) in the events table to see the event details in the right side window.
2. Click the **RAW EVENT** dropdown (**2**) in the event details window to see the event data payload. 
3. Verify that the `ACPExtensionEventData` matches what was sent by the Edge `sendEvent` API.

<img src="../Assets/edge-send-event-tutorial/assurance-validate-send-event.png" alt="Simulator tracking buttons" width="800"/>

> **Note**
> The two top level properties `xdm` and `data` are standard Edge event properties that are part of the Edge platform's XDM schema-based system for event data organization that enables powerful, customizable data processing. 

# Adobe Experience Platform Edge Network Extension iOS API Reference

## Prerequisites

Refer to the [Getting started guide](getting-started.md).

## API reference

- [extensionVersion](#extensionversion)
- [getLocationHint](#getLocationHint)
- [registerExtension](#registerextension)
- [resetIdentities](#resetidentities)
- [sendEvent](#sendevent)
- [setLocationHint](#setlocationhint)
- [Public Classes](#public-classes)
   - [XDM Schema](#xdm-schema)
   - [EdgeEventHandle](#edgeeventhandle)
   - [ExperienceEvent](#experienceevent)

------

### extensionVersion

The extensionVersion() API returns the version of the Edge Network extension.

#### Swift

##### Syntax
```swift
static var extensionVersion: String
```

##### Example
```swift
let extensionVersion = Edge.extensionVersion
```

#### Objective-C

##### Syntax
```objectivec
+ (nonnull NSString*) extensionVersion;
```

##### Example
```objectivec
NSString *extensionVersion = [AEPMobileEdge extensionVersion];
```

------

### getLocationHint

Gets the Edge Network location hint used in requests to Edge Network. The Edge Network location hint may be used when building the URL for Edge Network requests to hint at the server cluster to use.

#### Swift

##### Syntax
```swift
static func getLocationHint(completion: @escaping (String?, Error?) -> Void)
```
* `completion` is invoked with the location hint, or an `AEPError` if the request times out or an unexpected error occurs. The location hint value may be nil if the location hint expired or was not set. The default timeout is 1000ms. The completion handler may be invoked on a different thread.

##### Example
```swift
Edge.getLocationHint { (hint, error) in
  if let error = error {
    // Handle the error here
  } else {
    // Handle the hint here
  }
}
```

#### Objective-C

##### Syntax
```objectivec
+ (void) getLocationHint:^(NSString * _Nullable hint, NSError * _Nullable error)completion
```

##### Example
```objectivec
[AEPMobileEdge getLocationHint:^(NSString *hint, NSError *error) {
    // Handle the error and the hint here
}];
```

------

### resetIdentities

Resets current state of the Edge Network extension and clears previously cached content related to current identity, if any.

See [MobileCore.resetIdentities](https://developer.adobe.com/client-sdks/documentation/mobile-core/api-reference/#resetidentities) for more details.

------

### sendEvent

Sends an Experience event to Edge Network.

Starting with `AEPEdge` extension version **4.3.0** onwards, the `sendEvent` API supports optional Datastream overrides. This allows you to adjust your datastreams without the need for new ones or modifications to existing settings. The process involves two steps:

1. Define your Datastream configuration overrides on the [datastream configuration page](https://experienceleague.adobe.com/docs/experience-platform/datastreams/configure.html).
2. Send these overrides to the Edge Network using the sendEvent API.

#### Swift

##### Syntax
```swift
static func sendEvent(experienceEvent: ExperienceEvent, _ completion: (([EdgeEventHandle]) -> Void)? = nil)
```
* `experienceEvent` is the XDM [Experience Event](#experienceevent) sent to Edge Network.
* `completion` is an optional callback invoked when the request is complete and returns the associated [EdgeEventHandle](#edgeeventhandle)(s) received from  Edge Network. It may be invoked on a different thread.

##### Example
```swift
// Create Experience event from dictionary
var xdmData : [String: Any] = ["eventType" : "SampleXDMEvent",
                              "sample": "data"]
let experienceEvent = ExperienceEvent(xdm: xdmData)
```
```swift
// Example 1 - send the Experience event without handling the Edge Network response
Edge.sendEvent(experienceEvent: experienceEvent)
```
```swift
// Example 2 - send the Experience event and handle the Edge Network response onComplete
Edge.sendEvent(experienceEvent: experienceEvent) { (handles: [EdgeEventHandle]) in
  // Handle the Edge Network response
}
```

##### Example with Datastream ID override
```swift
// Create Experience event from dictionary
var xdmData : [String: Any] = ["eventType" : "SampleXDMEvent",
                              "sample": "data"]
let experienceEvent = ExperienceEvent(xdm: xdmData, datastreamIdOverride: "SampleDatastreamId")
```
```swift
// Example 1 - send the Experience event without handling the Edge Network response
Edge.sendEvent(experienceEvent: experienceEvent)
```
```swift
// Example 2 - send the Experience event and handle the Edge Network response onComplete
Edge.sendEvent(experienceEvent: experienceEvent) { (handles: [EdgeEventHandle]) in
  // Handle the Edge Network response
}
```

##### Example with Datastream config override
```swift
// Create Experience event from dictionary
var xdmData : [String: Any] = ["eventType" : "SampleXDMEvent",
                              "sample": "data"]

 let configOverrides: [String: Any] = [
                                        "com_adobe_experience_platform": [
                                          "datasets": [
                                            "event": [
                                              "datasetId": "SampleEventDatasetIdOverride"
                                            ],
                                            "profile": [
                                              "datasetId": "SampleProfileDatasetIdOverride"
                                            ]
                                          ]
                                        ],
                                        "com_adobe_analytics": [
                                          "reportSuites": [
                                            "rsid1",
                                            "rsid2",
                                            "rsid3"
                                            ]
                                        ],
                                        "com_adobe_identity": [
                                          "idSyncContainerId": "1234567"
                                        ],
                                        "com_adobe_target": [
                                          "propertyToken": "SamplePropertyToken"
                                        ]
                                      ]

let experienceEvent = ExperienceEvent(xdm: xdmData, datastreamConfigOverride: configOverrides)
```
```swift
// Example 1 - send the Experience event without handling the Edge Network response
Edge.sendEvent(experienceEvent: experienceEvent)
```
```swift
// Example 2 - send the Experience event and handle the Edge Network response onComplete
Edge.sendEvent(experienceEvent: experienceEvent) { (handles: [EdgeEventHandle]) in
  // Handle the Edge Network response
}
```

#### Objective-C

##### Syntax
```objectivec
+ (void) sendExperienceEvent:(AEPExperienceEvent * _Nonnull) completion:^(NSArray<AEPEdgeEventHandle *> * _Nonnull)completion
```

##### Example
```objectivec
// Create Experience event from dictionary:
NSDictionary *xdmData = @{ @"eventType" : @"SampleXDMEvent"};
NSDictionary *data = @{ @"sample" : @"data"};
AEPExperienceEvent* event = [[AEPExperienceEvent alloc]initWithXdm:xdmData data:data];
```
```objectivec
// Example 1 - send the Experience event without handling the Edge Network response
[AEPMobileEdge sendExperienceEvent:event completion:nil];
```
```objectivec
// Example 2 - send the Experience event and handle the Edge Network response onComplete
[AEPMobileEdge sendExperienceEvent:event completion:^(NSArray<AEPEdgeEventHandle *> * _Nonnull handles) {
  // Handle the Edge Network response
}];
```

##### Example with Datastream ID override
```objectivec
// Create Experience event from dictionary:
NSDictionary *xdmData = @{ @"eventType" : @"SampleXDMEvent"};
NSDictionary *data = @{ @"sample" : @"data"};
AEPExperienceEvent* event = [[AEPExperienceEvent alloc]initWithXdm:xdmData data:data datastreamIdOverride: @"SampleDatastreamIdOverride"];
```
```objectivec
// Example 1 - send the Experience event without handling the Edge Network response
[AEPMobileEdge sendExperienceEvent:event completion:nil];
```
```objectivec
// Example 2 - send the Experience event and handle the Edge Network response onComplete
[AEPMobileEdge sendExperienceEvent:event completion:^(NSArray<AEPEdgeEventHandle *> * _Nonnull handles) {
  // Handle the Edge Network response
}];
```


##### Example with Datastream config override
```objectivec
// Create Experience event from dictionary:
NSDictionary *xdmData = @{ @"eventType" : @"SampleXDMEvent"};
NSDictionary *data = @{ @"sample" : @"data"};
NSDictionary *configOverrides = @{ @"com_adobe_experience_platform" : @{
                                    @"datasets" : @{
                                        @"event" : @{
                                          @"datasetId": @"SampleEventDatasetIdOverride"
                                        },
                                        @"profile" : @{
                                          @"datasetId": @"SampleProfileDatasetIdOverride"
                                        }
                                      }
                                    },
                                    @"com_adobe_analytics" : @{
                                      @"reportSuites" : @[
                                        @"rsid1",
                                        @"rsid2",
                                        @"rsid3",
                                      ]
                                    },
                                    @"com_adobe_identity" : @{
                                      @"idSyncContainerId": @"1234567"
                                    },
                                    @"com_adobe_target" : @{
                                      @"propertyToken": @"SamplePropertyToken"
                                    }
                                  }

AEPExperienceEvent* event = [[AEPExperienceEvent alloc]initWithXdm:xdmData data:data datastreamConfigOverride: configOverrides];
```
```objectivec
// Example 1 - send the Experience event without handling the Edge Network response
[AEPMobileEdge sendExperienceEvent:event completion:nil];
```
```objectivec
// Example 2 - send the Experience event and handle the Edge Network response onComplete
[AEPMobileEdge sendExperienceEvent:event completion:^(NSArray<AEPEdgeEventHandle *> * _Nonnull handles) {
  // Handle the Edge Network response
}];
```
------

### setLocationHint

Sets the Edge Network location hint used in requests to Edge Network. Passing `nil` or an empty string (`""`) clears the existing location hint. Edge Network responses may overwrite the location hint to a new value when necessary to manage network traffic.

> **Warning**
> Use caution when setting the location hint. Only use valid [location hints for the `EdgeNetwork` scope](https://experienceleague.adobe.com/docs/experience-platform/edge-network-server-api/location-hints.html). An invalid location hint value will cause all Edge Network requests to fail with a `404` response code.

#### Swift

##### Syntax
```swift
@objc(setLocationHint:)
public static func setLocationHint(_ hint: String?)
```
- `hint` the Edge Network location hint to use when connecting to Edge Network.

##### Example
```swift
Edge.setLocationHint(hint)
```

#### Objective-C

##### Syntax
```objectivec
+ (void) setLocationHint: (NSString * _Nullable hint);
```

##### Example
```objectivec
[AEPMobileEdge setLocationHint:hint];
```

------

## Public Classes

### XDM Schema

The Edge Network extension provides the `XDMSchema` protocol that can be used to define the classes associated with your XDM schema in Experience Platform.

```swift
/// An interface representing a Platform XDM Event Data schema.
public protocol XDMSchema: Encodable {

    /// Returns the version of this schema as defined in the Adobe Experience Platform.
    /// - Returns: The version of this schema
    var schemaVersion: String { get }

    /// Returns the identifier for this schema as defined in the Adobe Experience Platform.
    /// The identifier is a URI where this schema is defined.
    /// - Returns: The URI identifier for this schema
    var schemaIdentifier: String { get }

    /// Returns the identifier for this dataset as defined in the Adobe Experience Platform.
    /// This is a system generated identifier for the Dataset the event belongs to.
    /// - Returns: The  identifier as a String for this dataset
    var datasetIdentifier: String { get }
}
```

### EdgeEventHandle

The `EdgeEventHandle` is a response fragment from Edge Network for a sent XDM Experience Event. One event can receive none, one, or multiple `EdgeEventHandle`(s) as response.
Use this class when calling the [sendEvent](#sendevent) API with `EdgeCallback`.


```swift
@objc(AEPEdgeEventHandle)
public class EdgeEventHandle: NSObject, Codable {
    /// Payload type
    @objc public let type: String?

    /// Event payload values
    @objc public let payload: [[String: Any]]?
}
```

### ExperienceEvent

Experience Event is the event to be sent to Edge Network. The XDM data is required for any Experience Event being sent using the Edge Network extension.


```swift
@objc(AEPExperienceEvent)
public class ExperienceEvent: NSObject {

    /// XDM formatted data, use an `XDMSchema` implementation for a better XDM data injection and format control
    @objc public let xdm: [String: Any]?

    /// Optional free-form data associated with this event
    @objc public let data: [String: Any]?

    /// Datastream identifier used to override the default datastream identifier set in the Edge configuration for this event
    @objc public private(set) var datastreamIdOverride: String?

    /// Datastream configuration used to override individual settings from the default datastream configuration for this event
    @objc public private(set) var datastreamConfigOverride: [String: Any]?

    /// Adobe Experience Platform dataset identifier, if not set the default dataset identifier set in the Edge Configuration is used
    @objc public private(set) var datasetIdentifier: String?

    /// Initialize an Experience Event with the provided event data
    /// - Parameters:
    ///   - xdm:  XDM formatted data for this event, passed as a raw XDM Schema data dictionary.
    ///   - data: Any free form data in a [String : Any] dictionary structure.
    @objc public init(xdm: [String: Any], data: [String: Any]? = nil) {...}

    /// Initialize an Experience Event with the provided event data
    /// - Parameters:
    ///   - xdm:  XDM formatted data for this event, passed as a raw XDM Schema data dictionary.
    ///   - data: Any free form data in a [String : Any] dictionary structure.
    ///   - datasetIdentifier: The Experience Platform dataset identifier where this event should be sent to; if not provided, the default dataset identifier set in the Edge configuration is used
    @objc public convenience init(xdm: [String: Any], data: [String: Any]? = nil, datasetIdentifier: String? = nil) {...}

    /// Initialize an Experience Event with the provided event data
    /// - Parameters:
    ///   - xdm:  XDM formatted data for this event, passed as a raw XDM Schema data dictionary.
    ///   - data: Any free form data in a [String : Any] dictionary structure.
    ///   - datastreamIdOverride: Datastream identifier used to override the default datastream identifier set in the Edge configuration for this event.
    ///   - datastreamConfigOverride: Datastream configuration used to override individual settings from the default datastream configuration for this event.
    @objc public convenience init(xdm: [String: Any], data: [String: Any]? = nil, datastreamIdOverride: String? = nil, datastreamConfigOverride: [String: Any]? = nil) {...}

    /// Initialize an Experience Event with the provided event data
    /// - Parameters:
    ///   - xdm: XDM formatted event data passed as an XDMSchema
    ///   - data: Any free form data in a [String : Any] dictionary structure.
    public init(xdm: XDMSchema, data: [String: Any]? = nil) {...}

    /// Initialize an Experience Event with the provided event data
    /// - Parameters:
    ///   - xdm: XDM formatted event data passed as an XDMSchema
    ///   - data: Any free form data in a [String : Any] dictionary structure.
    ///   - datastreamIdOverride: Datastream identifier used to override the default datastream identifier set in the Edge configuration for this event.
    ///   - datastreamConfigOverride: Datastream configuration used to override individual settings from the default datastream configuration for this event.
    public convenience init(xdm: XDMSchema, data: [String: Any]? = nil, datastreamIdOverride: String? = nil, datastreamConfigOverride: [String: Any]? = nil) {...}
}
```

#### Swift

##### Examples
Example 1: Set both the XDM and freeform data of an `ExperienceEvent`.
```swift
// Set freeform data of the Experience Event
var xdmData : [String: Any] = ["eventType" : "SampleXDMEvent",
                              "sample": "data"]

let experienceEvent = ExperienceEvent(xdm: xdmData, data: ["free": "form", "data": "example"])
```
Example 2: Create an `ExperienceEvent` event instance using a class that implements the `XDMSchema` protocol.
```swift
// Create an Experience Event from XDM Schema class implementations
import AEPEdge

public struct XDMSchemaExample : XDMSchema {
    public let schemaVersion = "1.0" // Returns the version of this schema as defined in the Adobe Experience Platform.
    public let schemaIdentifier = "" // The URI identifier for this schema
    public let datasetIdentifier = "" // The identifier for the Dataset this event belongs to.

    public init() {}

    public var eventType: String?
    public var otherField: String?

    enum CodingKeys: String, CodingKey {
    case eventType = "eventType"
    case otherField = "otherField"
    }
}

extension XDMSchemaExample {
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      if let unwrapped = eventType { try container.encode(unwrapped, forKey: .eventType) }
      if let unwrapped = otherField { try container.encode(unwrapped, forKey: .otherField) }
    }
}

...

// Create Experience Event from XDMSchema
var xdmData = XDMSchemaExample()
xdmData.eventType = "SampleXDMEvent"
xdm.otherField = "OtherFieldValue"
let event = ExperienceEvent(xdm: xdmData)
```
Example 3: Set a custom destination Dataset ID when creating an `ExperienceEvent` instance.
```swift
// Set the destination Dataset identifier of the Experience Event
var xdmData : [String: Any] = ["eventType" : "SampleXDMEvent",
                              "sample": "data"]

let experienceEvent = ExperienceEvent(xdm: xdmData, datasetIdentifier: "datasetIdExample")
```

#### Objective-C

##### Examples
Example 1: Set both the XDM and freeform data of an `ExperienceEvent`.
```objectivec
// Set the freeform data of the Experience event
NSDictionary *xdmData = @{ @"eventType" : @"SampleXDMEvent"};
NSDictionary *data = @{ @"sample" : @"data"};

AEPExperienceEvent *event = [[AEPExperienceEvent alloc] initWithXdm:xdmData data:data datasetIdentifier:nil];
```
Example 3: Set a custom destination Dataset ID when creating an `ExperienceEvent` instance.
```objectivec
// Set the destination Dataset identifier of the Experience Event
NSDictionary *xdmData = @{ @"eventType" : @"SampleXDMEvent"};

AEPExperienceEvent *event = [[AEPExperienceEvent alloc] initWithXdm:xdmData data:nil datasetIdentifier:@"datasetIdExample"];
```

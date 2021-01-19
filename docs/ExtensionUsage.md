# Edge API Usage

This document details the APIs provided by the AEP Edge extension, along with sample code snippets on how to properly use the APIs depending on if you are a mobile application developer or an AEP mobile extension developer.

## Edge extension usage for application developers

**Register the Edge extension with the AEP Mobile Core.**

###### Swift

In the AppDelegate application:didFinishLaunchingWithOptions, register the Edge extension along with the other AEP mobile SDK extensions.

```swift
MobileCore.registerExtensions([..., Identity.self, Edge.self])
```

###### Android

In the Application class in the onCreate() method, register the Edge extension along with the other AEP mobile SDK extensions before calling MobileCore.start(...)

```java
try {
  ...
  Identity.registerExtension();
  Edge.registerExtension();
} catch (Exception e) {
  e.printStackTrace();
}
MobileCore.start(new AdobeCallback() {
			@Override
			public void call(final Object o) {
					// processing after start
      }
}
```



**Read the Edge extension version**

###### Swift

```swift
print("Edge extension version: \(Edge.extensionVersion)")
```

###### Android

```java
Log.d("ExampleActivity", String.format("Edge extension version: ", Edge.extensionVersion()));
```



**Create Experience Event from Dictionary:**

**Note:** the xdmData passed in when creating an ExperienceEvent is a required parameter and it should be in XDM format based on the schema that is used in your Edge Configuration in Adobe Experience Launch UI.

###### Swift

```swift
var xdmData : [String: Any] = ["eventType" : "SampleXDMEvent",
                              "sample": "data"]
let experienceEvent = ExperienceEvent(xdm: xdmData)
```

###### Android

```java
Map<String, Object> xdmData = new HashMap<>();
xdmData.put("eventType", "SampleXDMEvent");
xdmData.put("sample", "data");
		
ExperienceEvent experienceEvent = new ExperienceEvent.Builder()
	.setXdmSchema(xdmData)
	.build();
```



**Create Experience Event from XDM Schema implementations:**

The AEP Edge extension provides an XDM Schema interface / protocol for you to create Classes for XDM Schema representations. In the example below the `XDMSchemaExample` is a representation of an XDM Schema originating from an Experience event, with two fields: `eventType` and `otherField`. It is recommended to use this example for complex XDM Schema implementations when you want to easily track the schema version of your implementation and update it with new fields in the future, as well as when you store these objects in memory or serialize/deserialize them in your own implementation.

###### Swift

```swift
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

###### Android

```swift
public class XDMSchemaExample implements com.adobe.marketing.mobile.xdm.Schema {
  private String eventType;
  private String otherField;
  
  public XDMSchemaExample() {}

	/**
	 * Returns the version number of this schema.
	 */
	@Override
	public String getSchemaVersion() { ... }

	/**
	 * Returns the unique schema identifier.
	 */
	@Override
	public String getSchemaIdentifier() { ... }

	/**
	 * Returns the unique dataset identifier. When this value is set the default Adobe Experience Platform Experience dataset configured in your Edge Configuration is overwritten.
	 */
	@Override
	public String getDatasetIdentifier() { ... }

	@Override
	public Map<String, Object> serializeToXdm() { 
  	Map<String, Object> map = new HashMap<>();
    if (this.eventType != null) {
			map.put("eventType", this.eventType);
		}
    
    if (this.otherField != null) {
			map.put("otherField", this.otherField);
		}
  }
  
  ...
  
	public String getEventType() {
		return this.eventType;
	}
  
  public void setEventType(final String newValue) {
		this.eventType = newValue;
	}
  
  public String getOtherField() {
		return this.otherField;
	}
  
  public void setOtherField(final String newValue) {
		this.otherField = newValue;
	}
}

// Create Experience Event from Schema
XDMSchemaExample xdmData = new XDMSchemaExample();
xdmData.setEventType("SampleXDMEvent");
xdmData.setOtherField("OtherFieldValue");

ExperienceEvent experienceEvent = new ExperienceEvent.Builder()
      															.setXdmSchema(xdmData)
																		.build();
```



**Add free form data to the Experience event:**

If you would like to add non-XDM formatted data to the Experience event, follow the examples below. This may be useful for data elements or rules use-cases.

###### Swift

```swift
let experienceEvent = ExperienceEvent(xdm: xdmData, data: ["free": "form", "data": "example"])
```

###### Android

```java
Map<String, Object> data = new HashMap<>();
data.put("free", "form");
data.put("data", "example");
ExperienceEvent experienceEvent = new ExperienceEvent.Builder()
  .setXdmSchema(xdmData)
  .setData(data)
  .build();
```



**Set the destination Dataset identifier to the current Experience event:**

If you would like to send an Experience event a specific Dataset in Adobe Experience Platform which is not the default Experience Event dataset configured in your Edge Configuration, follow the examples below:

###### Swift

```swift
let experienceEvent = ExperienceEvent(xdm: xdmData, datasetIdentifier: "datasetIdExample")
```

###### Android

```java
ExperienceEvent experienceEvent = new ExperienceEvent.Builder()
				.setXdmSchema(xdmData, "datasetIdExample")
				.build();
```



**Send an Experience Event:**

###### Swift

```swift
Edge.sendEvent(experienceEvent: experienceEvent)
```

###### Android

```java
Edge.sendEvent(experienceEvent, null);
```

The `sendEvent` API sends the `experienceEvent` to the Adobe Experience Edge Network. If a dataset ID is not set in the ExperienceEvent, then by default the `experienceEvent` is sent to the dataset configured in the application's Edge Configuration.



**Wait for responses from Adobe Experience Edge:**

###### Swift

```swift
Edge.sendEvent(experienceEvent: experienceEvent, { (handles: [EdgeEventHandle]) in
	for handle in handles {
  	// filter the handle you are interested in and process the handle (see handle.type and handle.payload)
    if handle.type == "personalization:decisions" && handle.payload != nil {
      // process handle.payload of type [[String: Any]]?
    }
  }
})
```

###### Android

```java
Edge.sendEvent(event, new EdgeCallback() {
  @Override
  public void onComplete(final List<EdgeEventHandle> handles) {
    if (handles == null) {
      return;
    }

    for (EdgeEventHandle handle : handles) {
      // filter the handle you are interested in and process the handle 
      // (see handle.getType() and handle.getPayload())
      if ("personalization:decisions".equals(handle.getType()) && handle.getPayload() != null) {
				// process the payload of type List<Map<String, Object>>
      }
    }
  }
```



## Edge extension usage for extension developers

**Create Experience Event:**

The XDM data is required for any Experience Event being sent using the AEP Edge mobile extension. Make sure that the `xdm` data block is following the XDM format of a known mixin, either publicly available or defined by the Adobe organization used by the application. Along with your XDM data it is encouraged that you set the `eventType` for the requests made by your extension, for easier tracking in the upstream services.

###### Swift

```swift
import AEPCore
...
let xdmData : [String: Any] = ["eventType" : "SampleXDMEvent",
                              "sample": "data"]
let eventData : [String: Any] = ["xdm": xdmData]
let experienceEvent = Event(name: "Sample Experience Event",
                   					type: EventType.edge,
                   					source: EventSource.requestContent,
                   					data: eventData)
```

###### Android

```java
import com.adobe.marketing.mobile.Event;
import com.adobe.marketing.mobile.MobileCore;
...
Map<String, Object> xdmData = new HashMap<>();
xdmData.put("eventType", "");
xdmData.put("sample", "data");
Map<String, Object> eventData = new HashMap<>();
eventData.put("xdm", eventData);

Event experienceEvent = new Event.Builder("Sample Experience Event", "com.adobe.eventType.edge", "com.adobe.eventSource.requestContent")
				.setEventData(eventData)
				.build();
```



**Set the destination Dataset identifier to the current Experience event:**

If you need to overwrite the destination dataset identifier for Adobe Experience Platform for your implementation, you can specify that in the event data as in the examples below:

###### Swift

```swift
let eventData : [String: Any] = ["xdm": xdmData, "datasetId": "datasetIdExample"]
...
```

###### Android

```java
Map<String, Object> eventData = new HashMap<>();
eventData.put("xdm", eventData);
eventData.put("datasetId", "datasetIdExample");
...
```



**Send an Experience Event:**

###### Swift

```swift
MobileCore.dispatch(event: experienceEvent)
```

###### Android

```java
MobileCore.dispatchEvent(experienceEvent, null);
```



**Wait for responses from Adobe Experience Edge:**

In order to process an Experience Edge event handle which is received as a response for an Experience event, register a listener for the Edge event handle type you are interested in. Here are a few examples of Edge event handle type: `personalization:decisions`, `identity:exchange` etc.

###### Swift

```swift
public class SampleExtension: Extension {
	...
  public func onRegistered() {
          registerListener(type: EventType.edge, source: "personalization:decisions", listener: receiveEdgeResponse(event:))
          ...
  }
  
  private func receiveEdgeResponse(event: Event) {
        // handle the Experience Edge event handle
    }
}
```

###### Android

```java
class SampleExtensionListener extends ExtensionListener {
  ...
	@Override
	public void hear(final Event event) {
    // handle the Experience Edge event handle
  }
}

class SampleExtension extends Extension {
  protected SampleExtension(final ExtensionApi extensionApi) {
  	super(extensionApi);
  	...
    getApi().registerEventListener("com.adobe.eventType.edge", "personalization:decisions", SampleExtensionListener.class, null);
  }
}
```

It is always recommended that you register listeners with reduced scope, for a particular Edge event handle type such as `personalization:decisions` in the example above. If you would like to be notified for all the Experience Edge event handles, you can use `EventSource.wildcard` (iOS) / `com.adobe.eventSource._wildcard_` (Android) as Event source.

## Sample events handled by the Edge extension

##### Handled events

###### Sample Experience Event

| Event Info        | Value                                                        |
| ----------------- | ------------------------------------------------------------ |
| Event name        | AEP Request Event                                            |
| Event type        | com.adobe.eventtype.edge                                     |
| Event source      | com.adobe.eventsource.requestcontent                         |
| Unique Identifier | Event UUID generated when the event is created, used as _id when sending the event to Experience Edge |
| Timestamp         | The timestamp when the event was created, used as XDM timestamp when sending data to Experience Edge |
| Event data        | Dictionary/Map containing XDM formatted data and free form data. Optional dataset identifier. |

_Event data example for Experience event:_

```json
{
  "xdm": {
    "eventType": "commerce.productViews",
    "commerce": {
      "productViews": {
        "value": 1
      }
    },
    "productListItems": [
      {
        "name": "Red",
        "SKU": "625–740"
      }
    ]
  },
  "data": {
    "free": "form",
    "data": "example"
  },
  "datasetId": "1234567"
}
```



##### Dispatched events

###### Sample Experience Edge response

| Event info        | Value                                                        |
| ----------------- | ------------------------------------------------------------ |
| Event name        | AEP Response Event Handle                                    |
| Event type        | com.adobe.eventtype.edge                                     |
| Event source      | personalization:decisions                                    |
| Unique identifier | Event UUID generated when the event is created               |
| Timestamp         | The timestamp when the event was created, after the response is received from the Experience Edge service |
| Event data        | Dictionary/Map containing:<br/>- **payload**: the event handle payloads list<br/>- **type**: the type of the payload, set by Konductor/Solutions. E.g. values: "state:store", "identity:exchange", "personalization:decisions"<br/>- **requestId**: the UUID of the ExEdge batch request (may be associated with multiple request events)<br/>- **eventRequestId** : the UUID of the request event for which this response event was received. |

_Event data example for Experience Edge Response event:_

```json
{
  "payload": [
    {
      "id": "4bc1df4b-dd63-4695-9d0b-27f06e03b631",
      "scope": "scopeExample",
      "items": [
        {
          "id": "xcore:fallback-offer:123",
          "schema": "https://ns.adobe.com/experience/offer-management/content-component-text",
          "data": {
            "id": "xcore:fallback-offer:123",
            "format": "text/plain",
            "language": [
              "en-us"
            ],
            "content": "sampleContent"
          }
        }
      ]
    }
  ],
  "type": "personalization:decisions",
  "requestId": "12345UUID",
  "eventRequestId": "AEPRequestEventUUIDvalue"
}
```

###### Sample Experience Edge error

**Note:** The Edge extension has a retry mechanism in case there are any recoverable response error codes. It is recommended that you do not retry sending events based on an `com.adobe.eventsource.errorresponsecontent` event as this can lead to double counting. This event should be used for logging or debugging purposes.

| Event info        | Value                                                        |
| ----------------- | ------------------------------------------------------------ |
| Event name        | AEP Error Response                                           |
| Event type        | com.adobe.eventtype.edge                                     |
| Event source      | com.adobe.eventsource.errorresponsecontent                   |
| Unique identifier | Event UUID generated when the event is created               |
| Timestamp         | The timestamp when the event was created, after the response error/warning is received from the Experience Edge service |
| Event data        | Dictionary/Map containing error details, usually a type, status and title. Other optional error details include detail, report errors and report cause:<br/>- **type**: the error type <br/>- **status**: error status <br/>- **title**: the error type for which the request has failed<br/>- **requestId**: the UUID of the ExEdge batch request (may be associated with multiple request events)<br/>- **eventRequestId**: the UUID of the request event for which this error event was received. |

_Event data example for Experience Edge Error event:_

```json
// example 1
{
  "requestId": "12345UUID",
  "eventRequestId": "AEPRequestEventUUIDvalue",
  "type": "https://ns.adobe.com/aep/errors/EXEG-0201-503",
  "status": 503,
  "title": "The 'com.adobe.experience.platform.example' service is temporarily unable to serve this request. Please try again later."
}

// example 2
{
  "requestId": "12345UUID",
  "eventRequestId": "AEPRequestEventUUIDvalue",
  "type": "https://ns.adobe.com/aep/errors/EXEG-0104-422",
  "status": 422,
  "title": "Unprocessable Entity",
  "detail": "Invalid request (report attached). Please check your input and try again.",
  "report": {
    "errors": [
      "error message 1",
      "error message 2",
      "error message 3"
    ]
  }
}
```



**Shared state and extension name**

com.adobe.edge

No data is shared as Shared state by the Edge extension in the current version. 
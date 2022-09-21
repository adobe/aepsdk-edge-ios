/*
 Copyright 2022 Adobe. All rights reserved.

 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/
package com.adobe.marketing.mobile.xdm;

import java.util.Map;
import java.util.HashMap;

/**
 * Class {@code MobileSDKApplicationSchema}
 *
 * <p/>
 * XDM Schema Java Object Generated 2020-10-01 15:23:09.629759 -0700 PDT m=+1.827036994 by XDMTool
 *
 * Title		:	Mobile SDK Application Schema
 * Version		:	1.2
 * ID			:	https://ns.adobe.com/acopprod3/schemas/711b0b9afc7162017bfe022cda7af34a15232797b4a69107
 * Alt ID		:	_acopprod3.schemas.711b0b9afc7162017bfe022cda7af34a15232797b4a69107
 * Type			:	schemas
 * IMS Org		:	FAF554945B90342F0A495E2C@AdobeOrg
 */
@SuppressWarnings("unused")
public class MobileSDKApplicationSchema implements com.adobe.marketing.mobile.xdm.Schema {
	private Application application;
	private Device device;
	private Environment environment;
	private String eventMergeId;
	private String eventType;
	private IdentityMap identityMap;
	private PlaceContext placeContext;
	private java.util.Date timestamp;

	public MobileSDKApplicationSchema() {}

	/**
	 * Returns the version number of this schema.
	 *
	 * @return the schema version number
	 */
	@Override
	public String getSchemaVersion() {
		return "1.2";
	}

	/**
	 * Returns the unique schema identifier.
	 *
	 * @return the schema ID
	 */
	@Override
	public String getSchemaIdentifier() {
		return "https://ns.adobe.com/acopprod3/schemas/711b0b9afc7162017bfe022cda7af34a15232797b4a69107";
	}

	/**
	 * Returns the unique dataset identifier.
	 *
	 * @return the dataset ID
	 */
	@Override
	public String getDatasetIdentifier() {
		return "5f05094a112ea71914bd169c";
	}

	@Override
	public Map<String, Object> serializeToXdm() {
		Map<String, Object> map = new HashMap<>();

		if (this.application != null) {
			map.put("application", this.application.serializeToXdm());
		}

		if (this.device != null) {
			map.put("device", this.device.serializeToXdm());
		}

		if (this.environment != null) {
			map.put("environment", this.environment.serializeToXdm());
		}

		if (this.eventMergeId != null) {
			map.put("eventMergeId", this.eventMergeId);
		}

		if (this.eventType != null) {
			map.put("eventType", this.eventType);
		}

		if (this.identityMap != null) {
			map.put("identityMap", this.identityMap.serializeToXdm());
		}

		if (this.placeContext != null) {
			map.put("placeContext", this.placeContext.serializeToXdm());
		}

		if (this.timestamp != null) {
			map.put("timestamp", com.adobe.marketing.mobile.xdm.Formatters.dateToISO8601String(this.timestamp));
		}

		return map;
	}


	/**
	 * Returns the Application property
	 * This mixin is used to capture application information related to an ExperienceEvent, including the name of the application, app version, installs, launches, crashes, and closures. It could be either the application targeted by the event like the send of a push notification or the application originating the event such as a click, or a login.
	 * @return {@link Application} value or null if the property is not set
	 */
	public Application getApplication() {
		return this.application;
	}

	/**
	 * Sets the Application property
	 * This mixin is used to capture application information related to an ExperienceEvent, including the name of the application, app version, installs, launches, crashes, and closures. It could be either the application targeted by the event like the send of a push notification or the application originating the event such as a click, or a login.
	 * @param newValue the new Application value
	 */
	public void setApplication(final Application newValue) {
		this.application = newValue;
	}
	/**
	 * Returns the Device property
	 * An identified device, application or device browser instance that is trackable across sessions, normally by cookies.
	 * @return {@link Device} value or null if the property is not set
	 */
	public Device getDevice() {
		return this.device;
	}

	/**
	 * Sets the Device property
	 * An identified device, application or device browser instance that is trackable across sessions, normally by cookies.
	 * @param newValue the new Device value
	 */
	public void setDevice(final Device newValue) {
		this.device = newValue;
	}
	/**
	 * Returns the Environment property
	 * Information about the surrounding situation the event observation occurred in, specifically detailing transitory information such as the network or software versions.
	 * @return {@link Environment} value or null if the property is not set
	 */
	public Environment getEnvironment() {
		return this.environment;
	}

	/**
	 * Sets the Environment property
	 * Information about the surrounding situation the event observation occurred in, specifically detailing transitory information such as the network or software versions.
	 * @param newValue the new Environment value
	 */
	public void setEnvironment(final Environment newValue) {
		this.environment = newValue;
	}
	/**
	 * Returns the ExperienceEvent merge ID property
	 * An ID to correlate or merge multiple Experience events together that are essentially the same event or should be merged. This is intended to be populated by the data producer prior to ingestion.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getEventMergeId() {
		return this.eventMergeId;
	}

	/**
	 * Sets the ExperienceEvent merge ID property
	 * An ID to correlate or merge multiple Experience events together that are essentially the same event or should be merged. This is intended to be populated by the data producer prior to ingestion.
	 * @param newValue the new ExperienceEvent merge ID value
	 */
	public void setEventMergeId(final String newValue) {
		this.eventMergeId = newValue;
	}
	/**
	 * Returns the Event Type property
	 * The primary event type for this time-series record.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getEventType() {
		return this.eventType;
	}

	/**
	 * Sets the Event Type property
	 * The primary event type for this time-series record.
	 * @param newValue the new Event Type value
	 */
	public void setEventType(final String newValue) {
		this.eventType = newValue;
	}
	/**
	 * Returns the IdentityMap property
	 *
	 * @return {@link IdentityMap} value or null if the property is not set
	 */
	public IdentityMap getIdentityMap() {
		return this.identityMap;
	}

	/**
	 * Sets the IdentityMap property
	 *
	 * @param newValue the new IdentityMap value
	 */
	public void setIdentityMap(final IdentityMap newValue) {
		this.identityMap = newValue;
	}
	/**
	 * Returns the Place context property
	 * The transient circumstances related to the observation. Examples include locale specific information such as weather, local time, traffic, day of the week, workday vs. holiday, and working hours.
	 * @return {@link PlaceContext} value or null if the property is not set
	 */
	public PlaceContext getPlaceContext() {
		return this.placeContext;
	}

	/**
	 * Sets the Place context property
	 * The transient circumstances related to the observation. Examples include locale specific information such as weather, local time, traffic, day of the week, workday vs. holiday, and working hours.
	 * @param newValue the new Place context value
	 */
	public void setPlaceContext(final PlaceContext newValue) {
		this.placeContext = newValue;
	}
	/**
	 * Returns the Timestamp property
	 * The time when an event or observation occurred.
	 * @return {@link java.util.Date} value or null if the property is not set
	 */
	public java.util.Date getTimestamp() {
		return this.timestamp;
	}

	/**
	 * Sets the Timestamp property
	 * The time when an event or observation occurred.
	 * @param newValue the new Timestamp value
	 */
	public void setTimestamp(final java.util.Date newValue) {
		this.timestamp = newValue;
	}
}


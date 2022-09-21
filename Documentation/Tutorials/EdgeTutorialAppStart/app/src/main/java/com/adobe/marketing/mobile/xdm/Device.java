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
 * Class {@code Device}
 * An identified device, application or device browser instance that is trackable across sessions, normally by cookies.
 *
 * XDM Property Java Object Generated 2020-10-01 15:23:09.634416 -0700 PDT m=+1.831694140 by XDMTool
 */
@SuppressWarnings("unused")
public class Device implements com.adobe.marketing.mobile.xdm.Property {
	private int colorDepth;
	private boolean isBackgroundPushEnabled;
	private boolean isLocationEnabled;
	private boolean isPushOptIn;
	private LocationPermissionEnum locationPermission;
	private String manufacturer;
	private String model;
	private String modelNumber;
	private int screenHeight;
	private ScreenOrientationEnum screenOrientation;
	private int screenWidth;
	private String typeID;
	private String typeIDService;
	private String type;

	public Device() {}

	@Override
	public Map<String, Object> serializeToXdm() {
		Map<String, Object> map = new HashMap<>();
		map.put("colorDepth", this.colorDepth);
		map.put("isBackgroundPushEnabled", this.isBackgroundPushEnabled);
		map.put("isLocationEnabled", this.isLocationEnabled);
		map.put("isPushOptIn", this.isPushOptIn);

		if (this.locationPermission != null) {
			map.put("locationPermission", this.locationPermission.toString());
		}

		if (this.manufacturer != null) {
			map.put("manufacturer", this.manufacturer);
		}

		if (this.model != null) {
			map.put("model", this.model);
		}

		if (this.modelNumber != null) {
			map.put("modelNumber", this.modelNumber);
		}

		map.put("screenHeight", this.screenHeight);

		if (this.screenOrientation != null) {
			map.put("screenOrientation", this.screenOrientation.toString());
		}

		map.put("screenWidth", this.screenWidth);

		if (this.typeID != null) {
			map.put("typeID", this.typeID);
		}

		if (this.typeIDService != null) {
			map.put("typeIDService", this.typeIDService);
		}

		if (this.type != null) {
			map.put("type", this.type);
		}

		return map;
	}

	/**
	 * Returns the Color depth property
	 * The number of colors the display is able to represent.
	 * @return int value
	 */
	public int getColorDepth() {
		return this.colorDepth;
	}

	/**
	 * Sets the Color depth property
	 * The number of colors the display is able to represent.
	 * @param newValue the new Color depth value
	 */
	public void setColorDepth(final int newValue) {
		this.colorDepth = newValue;
	}
	/**
	 * Returns the Background Push Enabled Flag property
	 * For devices like mobile , this tracks the system background push enabled permission status.
	 * @return boolean value
	 */
	public boolean getIsBackgroundPushEnabled() {
		return this.isBackgroundPushEnabled;
	}

	/**
	 * Sets the Background Push Enabled Flag property
	 * For devices like mobile , this tracks the system background push enabled permission status.
	 * @param newValue the new Background Push Enabled Flag value
	 */
	public void setIsBackgroundPushEnabled(final boolean newValue) {
		this.isBackgroundPushEnabled = newValue;
	}
	/**
	 * Returns the Location Enabled Flag property
	 * Indicates whether or not the device has location services enabled.
	 * @return boolean value
	 */
	public boolean getIsLocationEnabled() {
		return this.isLocationEnabled;
	}

	/**
	 * Sets the Location Enabled Flag property
	 * Indicates whether or not the device has location services enabled.
	 * @param newValue the new Location Enabled Flag value
	 */
	public void setIsLocationEnabled(final boolean newValue) {
		this.isLocationEnabled = newValue;
	}
	/**
	 * Returns the Push Opt In Flag property
	 * Indicates whether or not the device opted-in to receive push notifications.
	 * @return boolean value
	 */
	public boolean getIsPushOptIn() {
		return this.isPushOptIn;
	}

	/**
	 * Sets the Push Opt In Flag property
	 * Indicates whether or not the device opted-in to receive push notifications.
	 * @param newValue the new Push Opt In Flag value
	 */
	public void setIsPushOptIn(final boolean newValue) {
		this.isPushOptIn = newValue;
	}
	/**
	 * Returns the Location Permission property
	 * Tracks the device location permision attribute setting.
	 * @return {@link LocationPermissionEnum} value or null if the property is not set
	 */
	public LocationPermissionEnum getLocationPermission() {
		return this.locationPermission;
	}

	/**
	 * Sets the Location Permission property
	 * Tracks the device location permision attribute setting.
	 * @param newValue the new Location Permission value
	 */
	public void setLocationPermission(final LocationPermissionEnum newValue) {
		this.locationPermission = newValue;
	}
	/**
	 * Returns the Manufacturer property
	 * The name of the organization who owns the design and creation of the device, for example, 'Apple' is the manufacturer of the iPhone.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getManufacturer() {
		return this.manufacturer;
	}

	/**
	 * Sets the Manufacturer property
	 * The name of the organization who owns the design and creation of the device, for example, 'Apple' is the manufacturer of the iPhone.
	 * @param newValue the new Manufacturer value
	 */
	public void setManufacturer(final String newValue) {
		this.manufacturer = newValue;
	}
	/**
	 * Returns the Model property
	 * The name of the model for the device. This is the common, human-readable, or marketing name for the device. For example, the 'iPhone 6S' is a particular model of mobile phone.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getModel() {
		return this.model;
	}

	/**
	 * Sets the Model property
	 * The name of the model for the device. This is the common, human-readable, or marketing name for the device. For example, the 'iPhone 6S' is a particular model of mobile phone.
	 * @param newValue the new Model value
	 */
	public void setModel(final String newValue) {
		this.model = newValue;
	}
	/**
	 * Returns the Model number property
	 * The unique model number designation assigned by the manufacturer for this device. Model numbers are not versions, but unique identifiers that identify a particular model configuration. While the model for a particular phone might be 'iPhone 6S' the model number would be 'A1633', or 'A1634' based on configuration at the time of sale.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getModelNumber() {
		return this.modelNumber;
	}

	/**
	 * Sets the Model number property
	 * The unique model number designation assigned by the manufacturer for this device. Model numbers are not versions, but unique identifiers that identify a particular model configuration. While the model for a particular phone might be 'iPhone 6S' the model number would be 'A1633', or 'A1634' based on configuration at the time of sale.
	 * @param newValue the new Model number value
	 */
	public void setModelNumber(final String newValue) {
		this.modelNumber = newValue;
	}
	/**
	 * Returns the Screen height property
	 * The number of vertical pixels of the device's active display in the default orientation.
	 * @return int value
	 */
	public int getScreenHeight() {
		return this.screenHeight;
	}

	/**
	 * Sets the Screen height property
	 * The number of vertical pixels of the device's active display in the default orientation.
	 * @param newValue the new Screen height value
	 */
	public void setScreenHeight(final int newValue) {
		this.screenHeight = newValue;
	}
	/**
	 * Returns the Screen orientation property
	 * The current screen orientation such as "portrait" or "landscape".
	 * @return {@link ScreenOrientationEnum} value or null if the property is not set
	 */
	public ScreenOrientationEnum getScreenOrientation() {
		return this.screenOrientation;
	}

	/**
	 * Sets the Screen orientation property
	 * The current screen orientation such as "portrait" or "landscape".
	 * @param newValue the new Screen orientation value
	 */
	public void setScreenOrientation(final ScreenOrientationEnum newValue) {
		this.screenOrientation = newValue;
	}
	/**
	 * Returns the Screen width property
	 * The number of horizontal pixels of the device's active display in the default orientation.
	 * @return int value
	 */
	public int getScreenWidth() {
		return this.screenWidth;
	}

	/**
	 * Sets the Screen width property
	 * The number of horizontal pixels of the device's active display in the default orientation.
	 * @param newValue the new Screen width value
	 */
	public void setScreenWidth(final int newValue) {
		this.screenWidth = newValue;
	}
	/**
	 * Returns the Type identifier property
	 * An identifier for the device. This may be an identifier from 'DeviceAtlas' or another service that identifies the hardware that is being used.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getTypeID() {
		return this.typeID;
	}

	/**
	 * Sets the Type identifier property
	 * An identifier for the device. This may be an identifier from 'DeviceAtlas' or another service that identifies the hardware that is being used.
	 * @param newValue the new Type identifier value
	 */
	public void setTypeID(final String newValue) {
		this.typeID = newValue;
	}
	/**
	 * Returns the Type identifier service property
	 * The namespace of the service that is used to identify the device type.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getTypeIDService() {
		return this.typeIDService;
	}

	/**
	 * Sets the Type identifier service property
	 * The namespace of the service that is used to identify the device type.
	 * @param newValue the new Type identifier service value
	 */
	public void setTypeIDService(final String newValue) {
		this.typeIDService = newValue;
	}
	/**
	 * Returns the Type property
	 * Type of device being tracked.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getType() {
		return this.type;
	}

	/**
	 * Sets the Type property
	 * Type of device being tracked.
	 * @param newValue the new Type value
	 */
	public void setType(final String newValue) {
		this.type = newValue;
	}
}

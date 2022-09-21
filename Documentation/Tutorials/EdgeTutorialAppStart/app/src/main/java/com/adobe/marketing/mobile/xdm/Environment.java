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
 * Class {@code Environment}
 * Information about the surrounding situation the event observation occurred in, specifically detailing transitory information such as the network or software versions.
 *
 * XDM Property Java Object Generated 2020-10-01 15:23:09.632843 -0700 PDT m=+1.830120572 by XDMTool
 */
@SuppressWarnings("unused")
public class Environment implements com.adobe.marketing.mobile.xdm.Property {
	private BrowserDetails browserDetails;
	private String carrier;
	private int colorDepth;
	private ConnectionTypeEnum connectionType;
	private String domain;
	private String iSP;
	private String ipV4;
	private String ipV6;
	private String language;
	private String operatingSystem;
	private String operatingSystemVendor;
	private String operatingSystemVersion;
	private TypeEnum type;
	private int viewportHeight;
	private int viewportWidth;

	public Environment() {}

	@Override
	public Map<String, Object> serializeToXdm() {
		Map<String, Object> map = new HashMap<>();

		if (this.browserDetails != null) {
			map.put("browserDetails", this.browserDetails.serializeToXdm());
		}

		if (this.carrier != null) {
			map.put("carrier", this.carrier);
		}

		map.put("colorDepth", this.colorDepth);

		if (this.connectionType != null) {
			map.put("connectionType", this.connectionType.toString());
		}

		if (this.domain != null) {
			map.put("domain", this.domain);
		}

		if (this.iSP != null) {
			map.put("ISP", this.iSP);
		}

		if (this.ipV4 != null) {
			map.put("ipV4", this.ipV4);
		}

		if (this.ipV6 != null) {
			map.put("ipV6", this.ipV6);
		}

		if (this.language != null) {
			map.put("language", this.language);
		}

		if (this.operatingSystem != null) {
			map.put("operatingSystem", this.operatingSystem);
		}

		if (this.operatingSystemVendor != null) {
			map.put("operatingSystemVendor", this.operatingSystemVendor);
		}

		if (this.operatingSystemVersion != null) {
			map.put("operatingSystemVersion", this.operatingSystemVersion);
		}

		if (this.type != null) {
			map.put("type", this.type.toString());
		}

		map.put("viewportHeight", this.viewportHeight);
		map.put("viewportWidth", this.viewportWidth);

		return map;
	}

	/**
	 * Returns the Browser details property
	 * The browser specific details such as browser name, version, javascript version, user agent string, and accept language.
	 * @return {@link BrowserDetails} value or null if the property is not set
	 */
	public BrowserDetails getBrowserDetails() {
		return this.browserDetails;
	}

	/**
	 * Sets the Browser details property
	 * The browser specific details such as browser name, version, javascript version, user agent string, and accept language.
	 * @param newValue the new Browser details value
	 */
	public void setBrowserDetails(final BrowserDetails newValue) {
		this.browserDetails = newValue;
	}
	/**
	 * Returns the Mobile network carrier property
	 * A mobile network carrier or MNO, also known as a wireless service provider, wireless carrier, cellular company, or mobile network carrier, is a provider of services wireless communications that owns or controls all the elements necessary to sell and deliver services to an end user.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getCarrier() {
		return this.carrier;
	}

	/**
	 * Sets the Mobile network carrier property
	 * A mobile network carrier or MNO, also known as a wireless service provider, wireless carrier, cellular company, or mobile network carrier, is a provider of services wireless communications that owns or controls all the elements necessary to sell and deliver services to an end user.
	 * @param newValue the new Mobile network carrier value
	 */
	public void setCarrier(final String newValue) {
		this.carrier = newValue;
	}
	/**
	 * Returns the Color depth property
	 * The number of bits used for each color component of a single pixel.
	 * @return int value
	 */
	public int getColorDepth() {
		return this.colorDepth;
	}

	/**
	 * Sets the Color depth property
	 * The number of bits used for each color component of a single pixel.
	 * @param newValue the new Color depth value
	 */
	public void setColorDepth(final int newValue) {
		this.colorDepth = newValue;
	}
	/**
	 * Returns the Connection type property
	 * Internet connection type.
	 * @return {@link ConnectionTypeEnum} value or null if the property is not set
	 */
	public ConnectionTypeEnum getConnectionType() {
		return this.connectionType;
	}

	/**
	 * Sets the Connection type property
	 * Internet connection type.
	 * @param newValue the new Connection type value
	 */
	public void setConnectionType(final ConnectionTypeEnum newValue) {
		this.connectionType = newValue;
	}
	/**
	 * Returns the Domain property
	 * The domain of the users ISP.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getDomain() {
		return this.domain;
	}

	/**
	 * Sets the Domain property
	 * The domain of the users ISP.
	 * @param newValue the new Domain value
	 */
	public void setDomain(final String newValue) {
		this.domain = newValue;
	}
	/**
	 * Returns the Internet service provider property
	 * The name of the user's internet service provider.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getISP() {
		return this.iSP;
	}

	/**
	 * Sets the Internet service provider property
	 * The name of the user's internet service provider.
	 * @param newValue the new Internet service provider value
	 */
	public void setISP(final String newValue) {
		this.iSP = newValue;
	}
	/**
	 * Returns the IPv4 property
	 * The numerical label assigned to a device participating in a computer network that uses the Internet Protocol for communication.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getIpV4() {
		return this.ipV4;
	}

	/**
	 * Sets the IPv4 property
	 * The numerical label assigned to a device participating in a computer network that uses the Internet Protocol for communication.
	 * @param newValue the new IPv4 value
	 */
	public void setIpV4(final String newValue) {
		this.ipV4 = newValue;
	}
	/**
	 * Returns the IPv6 property
	 * The numerical label assigned to a device participating in a computer network that uses the Internet Protocol for communication.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getIpV6() {
		return this.ipV6;
	}

	/**
	 * Sets the IPv6 property
	 * The numerical label assigned to a device participating in a computer network that uses the Internet Protocol for communication.
	 * @param newValue the new IPv6 value
	 */
	public void setIpV6(final String newValue) {
		this.ipV6 = newValue;
	}
	/**
	 * Returns the Language property
	 * The language of the environment to represent the user's linguistic, geographical, or cultural preferences for data presentation.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getLanguage() {
		return this.language;
	}

	/**
	 * Sets the Language property
	 * The language of the environment to represent the user's linguistic, geographical, or cultural preferences for data presentation.
	 * @param newValue the new Language value
	 */
	public void setLanguage(final String newValue) {
		this.language = newValue;
	}
	/**
	 * Returns the Operating system property
	 * The name of the operating system used when the observation was made. The attribute should not contain any version information such as '10.5.3', but instead contain 'edition' designations such as 'Ultimate' or 'Professional'.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getOperatingSystem() {
		return this.operatingSystem;
	}

	/**
	 * Sets the Operating system property
	 * The name of the operating system used when the observation was made. The attribute should not contain any version information such as '10.5.3', but instead contain 'edition' designations such as 'Ultimate' or 'Professional'.
	 * @param newValue the new Operating system value
	 */
	public void setOperatingSystem(final String newValue) {
		this.operatingSystem = newValue;
	}
	/**
	 * Returns the Operating system vendor property
	 * The name of the operating system vendor used when the observation was made.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getOperatingSystemVendor() {
		return this.operatingSystemVendor;
	}

	/**
	 * Sets the Operating system vendor property
	 * The name of the operating system vendor used when the observation was made.
	 * @param newValue the new Operating system vendor value
	 */
	public void setOperatingSystemVendor(final String newValue) {
		this.operatingSystemVendor = newValue;
	}
	/**
	 * Returns the Operating system version property
	 * The full version identifier for the operating system used when the observation was made. Versions are generally numerically composed but may be in a vendor defined format.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getOperatingSystemVersion() {
		return this.operatingSystemVersion;
	}

	/**
	 * Sets the Operating system version property
	 * The full version identifier for the operating system used when the observation was made. Versions are generally numerically composed but may be in a vendor defined format.
	 * @param newValue the new Operating system version value
	 */
	public void setOperatingSystemVersion(final String newValue) {
		this.operatingSystemVersion = newValue;
	}
	/**
	 * Returns the Type property
	 * The type of the application environment.
	 * @return {@link TypeEnum} value or null if the property is not set
	 */
	public TypeEnum getType() {
		return this.type;
	}

	/**
	 * Sets the Type property
	 * The type of the application environment.
	 * @param newValue the new Type value
	 */
	public void setType(final TypeEnum newValue) {
		this.type = newValue;
	}
	/**
	 * Returns the Viewport height property
	 * The vertical size in pixels of the window the experience was displayed inside. For a web view event, the browser viewport height.
	 * @return int value
	 */
	public int getViewportHeight() {
		return this.viewportHeight;
	}

	/**
	 * Sets the Viewport height property
	 * The vertical size in pixels of the window the experience was displayed inside. For a web view event, the browser viewport height.
	 * @param newValue the new Viewport height value
	 */
	public void setViewportHeight(final int newValue) {
		this.viewportHeight = newValue;
	}
	/**
	 * Returns the Viewport width property
	 * The horizontal size in pixels of the window the experience was displayed inside. For a web view event, the browser viewport width.
	 * @return int value
	 */
	public int getViewportWidth() {
		return this.viewportWidth;
	}

	/**
	 * Sets the Viewport width property
	 * The horizontal size in pixels of the window the experience was displayed inside. For a web view event, the browser viewport width.
	 * @param newValue the new Viewport width value
	 */
	public void setViewportWidth(final int newValue) {
		this.viewportWidth = newValue;
	}
}

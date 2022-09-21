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
 * Class {@code BrowserDetails}
 * The browser specific details such as browser name, version, javascript version, user agent string, and accept language.
 *
 * XDM Property Java Object Generated 2020-10-01 15:23:09.635372 -0700 PDT m=+1.832649382 by XDMTool
 */
@SuppressWarnings("unused")
public class BrowserDetails implements com.adobe.marketing.mobile.xdm.Property {
	private String acceptLanguage;
	private boolean cookiesEnabled;
	private boolean javaEnabled;
	private boolean javaScriptEnabled;
	private String javaScriptVersion;
	private String javaVersion;
	private String name;
	private String quicktimeVersion;
	private boolean thirdPartyCookiesEnabled;
	private String userAgent;
	private String vendor;
	private String version;
	private int viewportHeight;
	private int viewportWidth;

	public BrowserDetails() {}

	@Override
	public Map<String, Object> serializeToXdm() {
		Map<String, Object> map = new HashMap<>();

		if (this.acceptLanguage != null) {
			map.put("acceptLanguage", this.acceptLanguage);
		}

		map.put("cookiesEnabled", this.cookiesEnabled);
		map.put("javaEnabled", this.javaEnabled);
		map.put("javaScriptEnabled", this.javaScriptEnabled);

		if (this.javaScriptVersion != null) {
			map.put("javaScriptVersion", this.javaScriptVersion);
		}

		if (this.javaVersion != null) {
			map.put("javaVersion", this.javaVersion);
		}

		if (this.name != null) {
			map.put("name", this.name);
		}

		if (this.quicktimeVersion != null) {
			map.put("quicktimeVersion", this.quicktimeVersion);
		}

		map.put("thirdPartyCookiesEnabled", this.thirdPartyCookiesEnabled);

		if (this.userAgent != null) {
			map.put("userAgent", this.userAgent);
		}

		if (this.vendor != null) {
			map.put("vendor", this.vendor);
		}

		if (this.version != null) {
			map.put("version", this.version);
		}

		map.put("viewportHeight", this.viewportHeight);
		map.put("viewportWidth", this.viewportWidth);

		return map;
	}

	/**
	 * Returns the Accept language property
	 * An IETF language tag (RFC 5646).
	 * @return {@link String} value or null if the property is not set
	 */
	public String getAcceptLanguage() {
		return this.acceptLanguage;
	}

	/**
	 * Sets the Accept language property
	 * An IETF language tag (RFC 5646).
	 * @param newValue the new Accept language value
	 */
	public void setAcceptLanguage(final String newValue) {
		this.acceptLanguage = newValue;
	}
	/**
	 * Returns the Allows cookies property
	 * The current user agent settings allow for the writing of cookies.'
	 * @return boolean value
	 */
	public boolean getCookiesEnabled() {
		return this.cookiesEnabled;
	}

	/**
	 * Sets the Allows cookies property
	 * The current user agent settings allow for the writing of cookies.'
	 * @param newValue the new Allows cookies value
	 */
	public void setCookiesEnabled(final boolean newValue) {
		this.cookiesEnabled = newValue;
	}
	/**
	 * Returns the Java enabled property
	 * If Java was enabled in the device this observation was made from.
	 * @return boolean value
	 */
	public boolean getJavaEnabled() {
		return this.javaEnabled;
	}

	/**
	 * Sets the Java enabled property
	 * If Java was enabled in the device this observation was made from.
	 * @param newValue the new Java enabled value
	 */
	public void setJavaEnabled(final boolean newValue) {
		this.javaEnabled = newValue;
	}
	/**
	 * Returns the JavaScript enabled property
	 * If JavaScript was enabled in the device this observation was made from.
	 * @return boolean value
	 */
	public boolean getJavaScriptEnabled() {
		return this.javaScriptEnabled;
	}

	/**
	 * Sets the JavaScript enabled property
	 * If JavaScript was enabled in the device this observation was made from.
	 * @param newValue the new JavaScript enabled value
	 */
	public void setJavaScriptEnabled(final boolean newValue) {
		this.javaScriptEnabled = newValue;
	}
	/**
	 * Returns the JavaScript version property
	 * The version of JavaScript supported during the observation.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getJavaScriptVersion() {
		return this.javaScriptVersion;
	}

	/**
	 * Sets the JavaScript version property
	 * The version of JavaScript supported during the observation.
	 * @param newValue the new JavaScript version value
	 */
	public void setJavaScriptVersion(final String newValue) {
		this.javaScriptVersion = newValue;
	}
	/**
	 * Returns the Java version property
	 * The version of Java supported during the observation.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getJavaVersion() {
		return this.javaVersion;
	}

	/**
	 * Sets the Java version property
	 * The version of Java supported during the observation.
	 * @param newValue the new Java version value
	 */
	public void setJavaVersion(final String newValue) {
		this.javaVersion = newValue;
	}
	/**
	 * Returns the Name property
	 * The application or browser name.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getName() {
		return this.name;
	}

	/**
	 * Sets the Name property
	 * The application or browser name.
	 * @param newValue the new Name value
	 */
	public void setName(final String newValue) {
		this.name = newValue;
	}
	/**
	 * Returns the Quicktime version property
	 * The version of Apple Quicktime supported during the observation.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getQuicktimeVersion() {
		return this.quicktimeVersion;
	}

	/**
	 * Sets the Quicktime version property
	 * The version of Apple Quicktime supported during the observation.
	 * @param newValue the new Quicktime version value
	 */
	public void setQuicktimeVersion(final String newValue) {
		this.quicktimeVersion = newValue;
	}
	/**
	 * Returns the Allows third-party cookies property
	 * If third-party cookies were enabled when this observation was made.
	 * @return boolean value
	 */
	public boolean getThirdPartyCookiesEnabled() {
		return this.thirdPartyCookiesEnabled;
	}

	/**
	 * Sets the Allows third-party cookies property
	 * If third-party cookies were enabled when this observation was made.
	 * @param newValue the new Allows third-party cookies value
	 */
	public void setThirdPartyCookiesEnabled(final boolean newValue) {
		this.thirdPartyCookiesEnabled = newValue;
	}
	/**
	 * Returns the User agent property
	 * The HTTP user-agent string from the client request.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getUserAgent() {
		return this.userAgent;
	}

	/**
	 * Sets the User agent property
	 * The HTTP user-agent string from the client request.
	 * @param newValue the new User agent value
	 */
	public void setUserAgent(final String newValue) {
		this.userAgent = newValue;
	}
	/**
	 * Returns the Vendor property
	 * The application or browser vendor.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getVendor() {
		return this.vendor;
	}

	/**
	 * Sets the Vendor property
	 * The application or browser vendor.
	 * @param newValue the new Vendor value
	 */
	public void setVendor(final String newValue) {
		this.vendor = newValue;
	}
	/**
	 * Returns the Version property
	 * The application or browser version.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getVersion() {
		return this.version;
	}

	/**
	 * Sets the Version property
	 * The application or browser version.
	 * @param newValue the new Version value
	 */
	public void setVersion(final String newValue) {
		this.version = newValue;
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

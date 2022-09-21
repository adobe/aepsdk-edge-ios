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
 * Class {@code Geo}
 * The geographic location where the experience was delivered.
 *
 * XDM Property Java Object Generated 2020-10-01 15:23:09.633668 -0700 PDT m=+1.830945333 by XDMTool
 */
@SuppressWarnings("unused")
public class Geo implements com.adobe.marketing.mobile.xdm.Property {
	private String city;
	private String countryCode;
	private String description;
	private int dmaID;
	private double elevation;
	private double latitude;
	private double longitude;
	private int msaID;
	private String postalCode;
	private String stateProvince;

	public Geo() {}

	@Override
	public Map<String, Object> serializeToXdm() {
		Map<String, Object> map = new HashMap<>();

		if (this.city != null) {
			map.put("city", this.city);
		}

		if (this.countryCode != null) {
			map.put("countryCode", this.countryCode);
		}

		if (this.description != null) {
			map.put("description", this.description);
		}

		map.put("dmaID", this.dmaID);
		map.put("elevation", this.elevation);
		map.put("latitude", this.latitude);
		map.put("longitude", this.longitude);
		map.put("msaID", this.msaID);

		if (this.postalCode != null) {
			map.put("postalCode", this.postalCode);
		}

		if (this.stateProvince != null) {
			map.put("stateProvince", this.stateProvince);
		}

		return map;
	}

	/**
	 * Returns the City property
	 * The name of the city.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getCity() {
		return this.city;
	}

	/**
	 * Sets the City property
	 * The name of the city.
	 * @param newValue the new City value
	 */
	public void setCity(final String newValue) {
		this.city = newValue;
	}
	/**
	 * Returns the Country code property
	 * The two-character [ISO 3166-1 alpha-2](https://datahub.io/core/country-list) code for the country.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getCountryCode() {
		return this.countryCode;
	}

	/**
	 * Sets the Country code property
	 * The two-character [ISO 3166-1 alpha-2](https://datahub.io/core/country-list) code for the country.
	 * @param newValue the new Country code value
	 */
	public void setCountryCode(final String newValue) {
		this.countryCode = newValue;
	}
	/**
	 * Returns the Description property
	 * A description of what the coordinates identify.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getDescription() {
		return this.description;
	}

	/**
	 * Sets the Description property
	 * A description of what the coordinates identify.
	 * @param newValue the new Description value
	 */
	public void setDescription(final String newValue) {
		this.description = newValue;
	}
	/**
	 * Returns the Designated market area property
	 * The Nielsen media research designated market area.
	 * @return int value
	 */
	public int getDmaID() {
		return this.dmaID;
	}

	/**
	 * Sets the Designated market area property
	 * The Nielsen media research designated market area.
	 * @param newValue the new Designated market area value
	 */
	public void setDmaID(final int newValue) {
		this.dmaID = newValue;
	}
	/**
	 * Returns the Elevation property
	 * The specific elevation of the defined coordinate. The value conforms to the [WGS84](http://gisgeography.com/wgs84-world-geodetic-system/) datum and is measured in meters.
	 * @return double value
	 */
	public double getElevation() {
		return this.elevation;
	}

	/**
	 * Sets the Elevation property
	 * The specific elevation of the defined coordinate. The value conforms to the [WGS84](http://gisgeography.com/wgs84-world-geodetic-system/) datum and is measured in meters.
	 * @param newValue the new Elevation value
	 */
	public void setElevation(final double newValue) {
		this.elevation = newValue;
	}
	/**
	 * Returns the Latitude property
	 * The signed vertical coordinate of a geographic point.
	 * @return double value
	 */
	public double getLatitude() {
		return this.latitude;
	}

	/**
	 * Sets the Latitude property
	 * The signed vertical coordinate of a geographic point.
	 * @param newValue the new Latitude value
	 */
	public void setLatitude(final double newValue) {
		this.latitude = newValue;
	}
	/**
	 * Returns the Longitude property
	 * The signed horizontal coordinate of a geographic point.
	 * @return double value
	 */
	public double getLongitude() {
		return this.longitude;
	}

	/**
	 * Sets the Longitude property
	 * The signed horizontal coordinate of a geographic point.
	 * @param newValue the new Longitude value
	 */
	public void setLongitude(final double newValue) {
		this.longitude = newValue;
	}
	/**
	 * Returns the Metropolitan statistical area property
	 * The metropolitan statistical area in the United States where the observation occurred.
	 * @return int value
	 */
	public int getMsaID() {
		return this.msaID;
	}

	/**
	 * Sets the Metropolitan statistical area property
	 * The metropolitan statistical area in the United States where the observation occurred.
	 * @param newValue the new Metropolitan statistical area value
	 */
	public void setMsaID(final int newValue) {
		this.msaID = newValue;
	}
	/**
	 * Returns the Postal code property
	 * The postal code of the location. Postal codes are not available for all countries. In some countries, this will only contain part of the postal code.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getPostalCode() {
		return this.postalCode;
	}

	/**
	 * Sets the Postal code property
	 * The postal code of the location. Postal codes are not available for all countries. In some countries, this will only contain part of the postal code.
	 * @param newValue the new Postal code value
	 */
	public void setPostalCode(final String newValue) {
		this.postalCode = newValue;
	}
	/**
	 * Returns the State or province property
	 * The state, or province portion of the observation. The format follows the [ISO 3166-2 (country and subdivision)][http://www.unece.org/cefact/locode/subdivisions.html] standard.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getStateProvince() {
		return this.stateProvince;
	}

	/**
	 * Sets the State or province property
	 * The state, or province portion of the observation. The format follows the [ISO 3166-2 (country and subdivision)][http://www.unece.org/cefact/locode/subdivisions.html] standard.
	 * @param newValue the new State or province value
	 */
	public void setStateProvince(final String newValue) {
		this.stateProvince = newValue;
	}
}

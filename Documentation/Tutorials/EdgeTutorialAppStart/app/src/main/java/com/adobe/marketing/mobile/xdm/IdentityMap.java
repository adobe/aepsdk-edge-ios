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
 * Class {@code IdentityMap}
 *
 *
 * XDM Property Java Object Generated 2020-10-01 15:23:09.633599 -0700 PDT m=+1.830876574 by XDMTool
 */
@SuppressWarnings("unused")
public class IdentityMap implements com.adobe.marketing.mobile.xdm.Property {
	private Items items;

	public IdentityMap() {}

	@Override
	public Map<String, Object> serializeToXdm() {
		Map<String, Object> map = new HashMap<>();

		if (this.items != null) {
			map.put("items", this.items.serializeToXdm());
		}

		return map;
	}

	/**
	 * Returns the Items property
	 *
	 * @return {@link Items} value or null if the property is not set
	 */
	public Items getItems() {
		return this.items;
	}

	/**
	 * Sets the Items property
	 *
	 * @param newValue the new Items value
	 */
	public void setItems(final Items newValue) {
		this.items = newValue;
	}
}

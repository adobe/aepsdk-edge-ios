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
 * Class {@code Items}
 *
 *
 * XDM Property Java Object Generated 2020-10-01 15:23:09.635183 -0700 PDT m=+1.832461000 by XDMTool
 */
@SuppressWarnings("unused")
public class Items implements com.adobe.marketing.mobile.xdm.Property {
	private AuthenticatedStateEnum authenticatedState;
	private String id;
	private boolean primary;

	public Items() {}

	@Override
	public Map<String, Object> serializeToXdm() {
		Map<String, Object> map = new HashMap<>();

		if (this.authenticatedState != null) {
			map.put("authenticatedState", this.authenticatedState.toString());
		}

		if (this.id != null) {
			map.put("id", this.id);
		}

		map.put("primary", this.primary);

		return map;
	}

	/**
	 * Returns the AuthenticatedState property
	 * The state this identity is authenticated as for this observed ExperienceEvent.
	 * @return {@link AuthenticatedStateEnum} value or null if the property is not set
	 */
	public AuthenticatedStateEnum getAuthenticatedState() {
		return this.authenticatedState;
	}

	/**
	 * Sets the AuthenticatedState property
	 * The state this identity is authenticated as for this observed ExperienceEvent.
	 * @param newValue the new AuthenticatedState value
	 */
	public void setAuthenticatedState(final AuthenticatedStateEnum newValue) {
		this.authenticatedState = newValue;
	}
	/**
	 * Returns the Identifier property
	 * Identity of the consumer in the related namespace.
	 * @return {@link String} value or null if the property is not set
	 */
	public String getId() {
		return this.id;
	}

	/**
	 * Sets the Identifier property
	 * Identity of the consumer in the related namespace.
	 * @param newValue the new Identifier value
	 */
	public void setId(final String newValue) {
		this.id = newValue;
	}
	/**
	 * Returns the Primary property
	 * Indicates this identity is the preferred identity. Is used as a hint to help systems better organize how identities are queried.
	 * @return boolean value
	 */
	public boolean getPrimary() {
		return this.primary;
	}

	/**
	 * Sets the Primary property
	 * Indicates this identity is the preferred identity. Is used as a hint to help systems better organize how identities are queried.
	 * @param newValue the new Primary value
	 */
	public void setPrimary(final boolean newValue) {
		this.primary = newValue;
	}
}

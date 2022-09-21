/*
 Copyright 2022 Adobe. All rights reserved.

 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.

----
 XDM Java Enum Generated 2020-10-01 15:23:09.630515 -0700 PDT m=+1.827792494 by XDMTool
----
*/
package com.adobe.marketing.mobile.xdm;

@SuppressWarnings("unused")
public enum TypeEnum {
	BROWSER("browser"), // Browser
	APPLICATION("application"), // Application
	IOT("iot"), // Internet of things
	EXTERNAL("external"), // External system
	WIDGET("widget"); // Application extension

	private final String value;

	TypeEnum(final String enumValue) {
		this.value = enumValue;
	}

	public String ToString() {
		return value;
	}
}

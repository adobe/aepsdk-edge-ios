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
 XDM Java Enum Generated 2020-10-01 15:23:09.630406 -0700 PDT m=+1.827683493 by XDMTool
----
*/
package com.adobe.marketing.mobile.xdm;

@SuppressWarnings("unused")
public enum ConnectionTypeEnum {
	DIALUP("dialup"), // Dial-up
	ISDN("isdn"), // ISDN
	BISDN("bisdn"), // BISDN
	DSL("dsl"), // DSL
	CABLE("cable"), // Cable
	WIRELESS_WIFI("wireless_wifi"), // Wireless wifi
	MOBILE("mobile"), // Mobile
	MOBILE_EDGE("mobile_edge"), // Mobile Edge
	MOBILE_2G("mobile_2g"), // Mobile 2G
	MOBILE_3G("mobile_3g"), // Mobile 3G
	MOBILE_LTE("mobile_lte"), // Mobile LTE
	T1("t1"), // T1
	T3("t3"), // T3
	OC3("oc3"), // OC3
	LAN("lan"), // LAN
	MODEM("modem"); // Modem

	private final String value;

	ConnectionTypeEnum(final String enumValue) {
		this.value = enumValue;
	}

	public String ToString() {
		return value;
	}
}

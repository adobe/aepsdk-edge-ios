/*
 Copyright 2020 Adobe. All rights reserved.

 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.

----
 XDM Swift Enum Generated 2020-06-25 16:18:51.496971 -0700 PDT m=+1.939211407 by XDMTool
----
*/
import Foundation

public enum ConnectionType:String, Encodable {
	case dialup = "dialup" // Dial-up
	case isdn = "isdn" // ISDN
	case bisdn = "bisdn" // BISDN
	case dsl = "dsl" // DSL
	case cable = "cable" // Cable
	case wirelessWifi = "wireless_wifi" // Wireless wifi
	case mobile = "mobile" // Mobile
	case mobileEdge = "mobile_edge" // Mobile Edge
	case mobile2g = "mobile_2g" // Mobile 2G
	case mobile3g = "mobile_3g" // Mobile 3G
	case mobileLte = "mobile_lte" // Mobile LTE
	case t1 = "t1" // T1
	case t3 = "t3" // T3
	case oc3 = "oc3" // OC3
	case lan = "lan" // LAN
	case modem = "modem" // Modem
	 
}

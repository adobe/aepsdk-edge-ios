//
// Copyright 2022 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

/* Edge Tutorial - code section (1/4)
import AEPCore
import AEPEdge
// Edge Tutorial - code section (1/4) */

import SwiftUI

struct ContentView: View {
    var body: some View {
        TrackView()
    }
}

struct TrackView: View {
    @State private var pushToken: Data?

    var body: some View {
        VStack {
            Button("Product add event", action: {
                // Dispatch an Experience Event which is handled by the
                // Edge extension which sends it to the Edge Network.
                
                var xdmData: [String: Any] = [
                  "eventType": "commerce.productViews",
                  "commerce": [
                    "productListAdds": [
                      "value": 1
                    ]
                  ],
                  "productListItems": [
                    [
                      "name":  "wide_brim_sunhat",
                      "SKU": "12345",
                      "quantity": 1
                    ]
                  ]
                ]
                
/* Edge Tutorial - code section (2/4)
                let experienceEvent = ExperienceEvent(xdm: xdmData)
                Edge.sendEvent(experienceEvent: experienceEvent)
// Edge Tutorial - code section (2/4) */
            }).padding()

            Button("Product view event", action: {
                // Dispatch an Experience Event which is handled by the
                // Edge extension which sends it to the Edge Network.
                
                var xdmData: [String: Any] = [
                  "eventType": "commerce.productViews",
                  "commerce": [
                    "productListViews": [
                      "value": 1
                    ]
                  ],
                  "productListItems": [
                    [
                      "name":  "wide_brim_sunhat",
                      "SKU": "12345"
                    ]
                  ]
                ]
                
/* Edge Tutorial - code section (3/4)
                let experienceEvent = ExperienceEvent(xdm: xdmData)
                Edge.sendEvent(experienceEvent: experienceEvent)
// Edge Tutorial - code section (3/4) */
            }).padding()

            Button("Trigger Consequence", action: {
                // Configure the Data Collection Mobile Property with a Rule to dispatch
                // an Analytics event when a PII event is dispatched in the SDK.
                // Without the rule, this button will not forward a track call to the Edge Network.
                
/* Edge Tutorial - code section (4/4)
                 MobileCore.collectPii(["key": "trigger"])
// Edge Tutorial - code section (4/4) */
            }).padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

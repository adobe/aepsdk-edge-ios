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

/// Imports the Edge extension for use in the code below.
/* Edge Tutorial - code section (1/3)
import AEPEdge
// Edge Tutorial - code section (1/3) */

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
            /// Creates and sends an add to cart commerce event to the Adobe Experience Edge, using an XDM object.
            Button("Product add event", action: {
                // Dispatch an Experience Event which is handled by the
                // Edge extension which sends it to the Edge Network.
                
                print("Sending XDM commerce cart add event")
                
                // Create list with the purchased items
                var product = ProductListItemsItem()
                product.name = "wide_brim_sunhat"
                product.priceTotal = 50
                product.sku = "12345"
                product.quantity = 1
                product.currencyCode = "USD"
                
                let productListItems: [ProductListItemsItem] = [product]
                
                var productAdd = ProductListAdds()
                productAdd.value = 1

                // Create Commerce object and add ProductListAdds details
                var commerce = Commerce()
                commerce.productListAdds = productAdd
                
                // Compose the XDM Schema object and set the event name
                var xdmData = MobileSDKCommerceSchema()
                xdmData.eventType = "commerce.productListAdds"
                xdmData.commerce = commerce
                xdmData.productListItems = productListItems

/// Creates an Experience Event with an event payload that conforms to the XDM schema set up in the Adobe Experience Platform. This event is an example of a product add.
/* Edge Tutorial - code section (2/3)
                let event = ExperienceEvent(xdm: xdmData)
                Edge.sendEvent(experienceEvent: event)
// Edge Tutorial - code section (2/3) */
                
                
            }).padding()
            /// Creates and sends an add to cart commerce event to the Adobe Experience Edge, using a custom dictionary.
            Button("Product view event", action: {
                // Dispatch an Experience Event which is handled by the
                // Edge extension which sends it to the Edge Network.
                
                let xdmData: [String: Any] = [
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
/// Creates an Experience Event with an event payload that conforms to the XDM schema set up in the Adobe Experience Platform. This event is an example of a product view.
/* Edge Tutorial - code section (3/3)
                let experienceEvent = ExperienceEvent(xdm: xdmData)
                Edge.sendEvent(experienceEvent: experienceEvent)
// Edge Tutorial - code section (3/3) */
            }).padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

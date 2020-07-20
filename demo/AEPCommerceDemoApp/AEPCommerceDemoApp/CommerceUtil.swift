//
// Copyright 2020 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import ACPCore
import AEPExperiencePlatform
import Foundation

/// This CommerceUtil Class encapsulates logic for creating Commerce objects and sending as
/// ExperiencePlatformEvents to the Experience Platform Extension.
///
/// The methods in this class are called throughout the commerce workflow to send information
/// to the Adobe Data Platform for user actions such as viewing product items, adding items to
/// a shopping cart, and purchasing items in a shopping cart, for example.
///
/// The methods are provided as an example usage and may not be indicative of every application's
/// use case. For example, a commerce.purchases action sets Order and PaymentsItem
/// from hardcoded values for simplicity.
///
/// Please review the XDM documentation for the
/// <a href="https://github.com/adobe/xdm/blob/master/docs/reference/context/experienceevent-commerce.schema.md">Experience Event Commerce Schema</a>
///  Mixin for more information.

class CommerceUtil {

    private static let logTag: String = "CommerceUtil"

    /// US dollar currency code
    private static let currencyCodeUsd: String = "USD"

    /// Default payment type
    private static let paymentType: String = "Cash"

    /// View(s) of a product has occurred.
    /// See <a href="https://github.com/adobe/xdm/blob/master/docs/reference/context/experienceevent.schema.md#xdmeventtype">Experience Event</a>
    private static let eventTypeCommerceProductViews: String = "commerce.productViews"

    /// Addition of a product to the product list has occurred. Example a product is added to a shopping cart.
    /// See <a href="https://github.com/adobe/xdm/blob/master/docs/reference/context/experienceevent.schema.md#xdmeventtype">Experience Event</a>
    private static let eventTypeCommerceProductListAdds: String = "commerce.productListAdds"

    /// Removal(s) of a product entry from a product list. Example a product is removed from a
    /// shopping cart.
    /// See <a href="https://github.com/adobe/xdm/blob/master/docs/reference/context/experienceevent.schema.md#xdmeventtype">Experience Event</a>
    private static let eventTypeCommerceProductListRemovals: String   = "commerce.productListRemovals"

    /// An action during a checkout process of a product list, there can be more than one checkout
    /// event if there are multiple steps in a checkout process. If there are multiple steps the
    /// event time information and referenced page or experience is used to identify the step
    /// individual events represent in order.
    /// See <a href="https://github.com/adobe/xdm/blob/master/docs/reference/context/experienceevent.schema.md#xdmeventtype">Experience Event</a>
    private static let eventTypeCommerceCheckouts: String = "commerce.checkouts"

    /// An order has been accepted. Purchase is the only required action in a commerce conversion.
    /// Purchase must have a product list referenced.
    /// See <a href="https://github.com/adobe/xdm/blob/master/docs/reference/context/experienceevent.schema.md#xdmeventtype">Experience Event</a>
    private static let eventTypeCommercePurchases: String = "commerce.purchases"

    /// Helper Method : Computes the total cost of a number of items.
    /// - Parameters :
    ///     - price              : The price of the product item.
    ///     - quantity      : The quantity of the items.
    /// - Returns:
    ///     - TotalCost         :   The total cost of the items
    private static func computeTotal(price: Double, quantity: Int) -> Double {
        return price * Double(quantity)
    }

    /// Helper Method :  Creates and returns the list of items added into the shoppring cart .
    /// - Returns:
    ///     -  [ProductListItemsItem] :   The lift of products added into the shopping cart
    private static func prepareProductList() -> [ProductListItemsItem]? {

        var itemsList: [ProductListItemsItem] = []
        for item in adbMobileShoppingCart.items {
            let productItem = createProductListItemsItem(productData: item.product.productData, quantity: item.product.quantity)
            if let unwrappedProductItem = productItem {
                itemsList.append(unwrappedProductItem)
            } else {
                ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "sendPurchaseXdmEvent - Cannot create '" + eventTypeCommercePurchases + "' event as given product item is null.")
            }
        }
        return itemsList
    }

    /// Creates and sends a product view event to the Adobe Data Platform.
    /// This method should be called when a product details are viewed.
    /// - Parameters:
    ///    - productData : The product details of the com.adobe.marketing.mobile.platform.app.ProductContent.ProductItem} item which was viewed
    static func sendProductViewXdmEvent(productData: ProductData) {

        ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "sendProductViewXdmEvent with item '" + productData.name + "'")
        let productItem = createProductListItemsItem(productData: productData, quantity: 0)

        if let unwrappedProductItem = productItem {
            createAndSendEvent(itemsList: [unwrappedProductItem], eventType: eventTypeCommerceProductViews)
        } else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "sendProductViewXdmEvent - Cannot create '" + eventTypeCommerceProductViews + "' event as given product item is null.")
        }
    }

    /// Creates and sends a product list add event to the Adobe Data Platform.
    /// This method should be called when a product is added to a shopping cart.
    /// - Parameters:
    ///    - productData : The product details of the com.adobe.marketing.mobile.platform.app.ProductContent.ProductItem} item which was added into the shopping cart.
    ///    - quantity       : The number of product items added.
    static func sendProductListAddXdmEvent(productData: ProductData, quantity: Int) {

        ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "sendProductListAddXdmEvent with item '" + productData.name + "'")
        let productItem = createProductListItemsItem(productData: productData, quantity: quantity)

        if let unwrappedProductItem = productItem {
            createAndSendEvent(itemsList: [unwrappedProductItem], eventType: eventTypeCommerceProductListAdds)
        } else {
            ACPCore.log(ACPMobileLogLevel.debug,
                        tag: logTag,
                        message: "sendProductListAddXdmEvent - Cannot create '" + eventTypeCommerceProductListAdds + "' event as given product item is null.")
        }
    }

    /// Creates and sends a product list remove event to the Adobe Data Platform.
    /// This method should be called when a product is removed from a shopping cart.
    /// - Parameters:
    ///    - productData : The product details of the com.adobe.marketing.mobile.platform.app.ProductContent.ProductItem} item which was removed from the shopping cart.
    ///    - quantity       : The number of product items that was added.
    static func sendProductListRemoveXdmEvent(productData: ProductData, quantity: Int) {

        ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "sendProductListRemoveXdmEvent with item '" + productData.name + "'")
        let productItem = createProductListItemsItem(productData: productData, quantity: quantity)

        if let unwrappedProductItem = productItem {
            createAndSendEvent(itemsList: [unwrappedProductItem], eventType: eventTypeCommerceProductListRemovals)
        } else {
            ACPCore.log(ACPMobileLogLevel.debug,
                        tag: logTag,
                        message: "sendProductListRemoveXdmEvent - Cannot create '" + eventTypeCommerceProductListRemovals + "' event as given product item is null.")
        }
    }

    /// Creates and sends a cart checkout event to the Adobe Data Platform.
    /// This method should be called when an action during the shopping cart checkout process is taken.
    /// There may be more than one checkout events if there are multiple steps in the checkout process.
    static func sendCheckoutXdmEvent() {

        ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "sendCheckoutXdmEvent")
        if let itemsList = prepareProductList() {
            createAndSendEvent(itemsList: itemsList, eventType: eventTypeCommerceCheckouts)
        } else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "sendCheckoutXdmEvent - Cannot create '" + eventTypeCommerceCheckouts + "' event as given product item is null.")
        }
    }

    /// Creates and sends a cart clean event to the Adobe Data Platform.
    /// This method should be called when an action during the shopping cart is being cleared.
    static func sendCartClearXdmEvent() {

        ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "sendCartClearXdmEvent")
        if let itemsList = prepareProductList() {
            createAndSendEvent(itemsList: itemsList, eventType: eventTypeCommerceProductListRemovals)
        } else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "sendCartClearXdmEvent - Cannot create '" + eventTypeCommerceProductListRemovals + "' event as given product item is null.")
        }
    }

    /// Creates and sends a cart purchase event to the Adobe Data Platform.
    /// This method should be called when a final purchase is made of a shopping cart.
    static func sendPurchaseXdmEvent() {

        ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "sendPurchaseXdmEvent")
        if let itemsList = prepareProductList() {

            /// Create PaymentItem which details the method of payment
            var paymentsItem = PaymentsItem()
            paymentsItem.currencyCode = currencyCodeUsd
            paymentsItem.paymentAmount = adbMobileShoppingCart.total
            paymentsItem.paymentType = paymentType

            /// Create the Order
            var order = Order()
            order.currencyCode = currencyCodeUsd
            order.priceTotal = adbMobileShoppingCart.total
            order.payments = [paymentsItem]

            /// Create Purchases action
            var purchases = Purchases()
            purchases.value = 1

            /// Create Commerce and add Purchases action and Order details
            var commerce = Commerce()
            commerce.order = order
            commerce.purchases = purchases

            var xdmData = MobileSDKCommerceSchema()
            xdmData.eventType = eventTypeCommercePurchases
            xdmData.commerce = commerce
            xdmData.productListItems = itemsList

            let event = ExperiencePlatformEvent(xdm: xdmData)
            let responseHandler = ResponseHandler()
            ExperiencePlatform.sendEvent(experiencePlatformEvent: event, responseHandler: responseHandler)
        } else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "sendPurchaseXdmEvent - Cannot create '" + eventTypeCommercePurchases + "' as no items were found in cart.")
        }
    }

    /// Helper method to construct and send the ExperiencePlatformEvent} to the Experience Platform Extension.
    /// - Parameters:
    ///    - itemsList   : The  list of ProductListItemsItem}s associated with this commerce event.
    ///    - eventType   : event type for the given commerce event.
    static func createAndSendEvent(itemsList: [ProductListItemsItem], eventType: String) {

        var commerce = Commerce()
        switch eventType {
        case eventTypeCommerceCheckouts:
            var checkouts = Checkouts()
            checkouts.value = 1
            commerce.checkouts = checkouts

        case eventTypeCommerceProductViews:
            var productViews = ProductViews()
            productViews.value = 1
            commerce.productViews = productViews

        case eventTypeCommerceProductListAdds:
            var productListAdds = ProductListAdds()
            productListAdds.value = 1
            commerce.productListAdds = productListAdds

        case eventTypeCommerceProductListRemovals:
            var productListRemovals = ProductListRemovals()
            productListRemovals.value = 1
            commerce.productListRemovals = productListRemovals

        case eventTypeCommercePurchases:
            var purchases = Purchases()
            purchases.value = 1
            commerce.purchases = purchases

        default:
            ACPCore.log(ACPMobileLogLevel.debug, tag: logTag, message: "Unknown event type when sending Commerce event. Ignoring event.")
            return
        }

        var xdmData = MobileSDKCommerceSchema()
        xdmData.eventType = eventType
        xdmData.commerce = commerce
        xdmData.productListItems = itemsList
        let event = ExperiencePlatformEvent(xdm: xdmData)
        let responseHandler = ResponseHandler()
        ExperiencePlatform.sendEvent(experiencePlatformEvent: event, responseHandler: responseHandler)
    }

    /// Helper method to convert an com.adobe.marketing.mobile.platform.app.ProductContent.ProductItem  to an
    /// ProductListItemsItem object.
    /// If quantity is zero, then only the name  and sku  are added to the ProductItem.
    /// - Parameters :
    ///     -  productData          : Information about a Product.
    ///     -  quantity                : The specified quantity of Product. If zero, quantity, price, and currency data are not added to the result.
    /// - Returns:
    ///     - ProductListItemsItem : A list of products populated from the given com.adobe.marketing.mobile.platform.app.ProductContent.ProductItem},
    /// or null if item} is null
    static func createProductListItemsItem(productData: ProductData, quantity: Int) -> ProductListItemsItem? {

        var productItem = ProductListItemsItem()
        productItem.name = productData.name
        productItem.sKU = productData.sku
        if quantity > 0 {
            productItem.currencyCode = productData.currency
            productItem.quantity = Int64(quantity)
            productItem.priceTotal = computeTotal(price: productData.price, quantity: quantity)
        }
        return productItem
    }
}

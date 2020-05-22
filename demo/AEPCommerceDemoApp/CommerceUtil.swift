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


import Foundation
import ACPExperiencePlatform
import ACPCore
import xdmlib

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

class CommerceUtil  {
    
    private static let LOG_TAG: String = "CommerceUtil"
    
    /// US dollar currency code
    
    private static let CURRENCY_CODE_USD: String = "USD"
    
    /// Default payment type
    
    private static let PAYMENT_TYPE: String = "Cash"
    
    /// View(s) of a product has occurred.
    /// See <a href="https://github.com/adobe/xdm/blob/master/docs/reference/context/experienceevent.schema.md#xdmeventtype">Experience Event</a>
    private static let EVENT_TYPE_COMMERCE_PRODUCT_VIEWS: String = "commerce.productViews"
    
    /// Addition of a product to the product list has occurred. Example a product is added to a shopping cart.
    /// See <a href="https://github.com/adobe/xdm/blob/master/docs/reference/context/experienceevent.schema.md#xdmeventtype">Experience Event</a>
    private static let EVENT_TYPE_COMMERCE_PRODUCT_LIST_ADDS: String = "commerce.productListAdds"
    
    /// Removal(s) of a product entry from a product list. Example a product is removed from a
    /// shopping cart.
    /// See <a href="https://github.com/adobe/xdm/blob/master/docs/reference/context/experienceevent.schema.md#xdmeventtype">Experience Event</a>
    private static let EVENT_TYPE_COMMERCE_PRODUCT_LIST_REMOVALS: String   = "commerce.productListRemovals"
    
    /// An action during a checkout process of a product list, there can be more than one checkout
    /// event if there are multiple steps in a checkout process. If there are multiple steps the
    /// event time information and referenced page or experience is used to identify the step
    /// individual events represent in order.
    /// See <a href="https://github.com/adobe/xdm/blob/master/docs/reference/context/experienceevent.schema.md#xdmeventtype">Experience Event</a>
    private static let EVENT_TYPE_COMMERCE_CHECKOUTS: String = "commerce.checkouts"
    
    /// An order has been accepted. Purchase is the only required action in a commerce conversion.
    /// Purchase must have a product list referenced.
    /// See <a href="https://github.com/adobe/xdm/blob/master/docs/reference/context/experienceevent.schema.md#xdmeventtype">Experience Event</a>
    private static let EVENT_TYPE_COMMERCE_PURCHASES: String = "commerce.purchases"
    
    /// Creates and sends a product view event to the Adobe Data Platform.
    /// A commerce.productViews} event is a Commerce} object with Commerce#setProductViews(ProductViews)}
    /// set, along with a ProductListItemsItem} list containing the details of the
    /// viewed product.
    /// This method should be called when a product details are viewed.
    /// - Parameters:
    ///    - productData : The product details of the com.adobe.marketing.mobile.platform.app.ProductContent.ProductItem} item which was viewed
    static func sendProductViewXdmEvent(productData:ProductData) {

        ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message: "sendProductViewXdmEvent with item '" + productData.name + "'")
        let productItem  = createProductListItemsItem(productData: productData, quantity: 0)
        
        guard let unwrappedProductItem = productItem else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message: "sendProductViewXdmEvent - Cannot create '" + EVENT_TYPE_COMMERCE_PRODUCT_VIEWS + "' event as given product item is null.")
            return;
        }
        var itemsList: [ProductListItemsItem] = []
        itemsList.append(unwrappedProductItem)
        createAndSendEvent(itemsList: itemsList,eventType: EVENT_TYPE_COMMERCE_PRODUCT_VIEWS)
    }
    
    /// Creates and sends a product list add event to the Adobe Data Platform.
    /// A commerce.productListAdds} event is a Commerce} object with
    /// Commerce#setProductListAdds(ProductListAdds)}
    /// set, along with a ProductListItemsItem} list containing the details of the
    /// added product.
    /// This method should be called when a product is added to a shopping cart.
    /// - Parameters:
    ///    - productData : The product details of the com.adobe.marketing.mobile.platform.app.ProductContent.ProductItem} item which was added into the shopping cart.
    ///    - quantity       : The number of product items added.
    static func sendProductListAddXdmEvent(productData: ProductData, quantity: Int) {
        
        ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message: "sendProductListAddXdmEvent with item '" + productData.name + "'")
        let productItem  = createProductListItemsItem(productData: productData, quantity: quantity)
        
        guard let unwrappedProductItem = productItem else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message:"sendProductListAddXdmEvent - Cannot create '" + EVENT_TYPE_COMMERCE_PRODUCT_LIST_ADDS + "' event as given product item is null.")
            return;
        }
        var itemsList: [ProductListItemsItem] = []
        itemsList.append(unwrappedProductItem)
        createAndSendEvent(itemsList: itemsList,eventType: EVENT_TYPE_COMMERCE_PRODUCT_LIST_ADDS)
    }
    
    /// Creates and sends a product list remove event to the Adobe Data Platform.
    /// A commerce.productListAdds} event is a Commerce} object with
    /// Commerce#setProductListRemovals(ProductListRemovals)}
    /// set, along with a ProductListItemsItem} list containing the details of the
    /// removed product.
    /// This method should be called when a product is removed from a shopping cart.
    /// - Parameters:
    ///    - productData : The product details of the com.adobe.marketing.mobile.platform.app.ProductContent.ProductItem} item which was removed from the shopping cart.
    ///    - quantity       : The number of product items that was added.
    static func sendProductListRemoveXdmEvent(productData: ProductData, quantity: Int) {
        
        ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message:"sendProductListRemoveXdmEvent with item '" + productData.name + "'")
        let productItem  = createProductListItemsItem(productData: productData, quantity: quantity)
        
        guard let unwrappedProductItem = productItem else {
            ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message:"sendProductListRemoveXdmEvent - Cannot create '" + EVENT_TYPE_COMMERCE_PRODUCT_LIST_REMOVALS + "' event as given product item is null.")
            return;
        }
        var itemsList: [ProductListItemsItem] = []
        itemsList.append(unwrappedProductItem)
        createAndSendEvent(itemsList: itemsList,eventType: EVENT_TYPE_COMMERCE_PRODUCT_LIST_REMOVALS)
    }
    
    /// Creates and sends a cart checkout event to the Adobe Data Platform.
    /// A commerce.checkouts} event is a Commerce} object with
    /// Commerce#setCheckouts(Checkouts)}
    /// set, along with a ProductListItemsItem} list containing the details of all the
    /// products in the shopping cart.
    /// This method should be called when an action during the shopping cart checkout process is taken.
    /// There may be more than one checkout events if there are multiple steps in the checkout process.
    static func sendCheckoutXdmEvent() {
        ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message:"sendCheckoutXdmEvent")
        var itemsList: [ProductListItemsItem] = []
        for item in adbMobileShoppingCart.items {
            let prodData:ProductData = ProductData(sku: item.product.sku, name: item.product.name, details: item.product.description, price: item.product.price, currency: item.product.currency, imageLarge: item.product.imageLarge, imageSmall: item.product.imageSmall)
            let productItem  = createProductListItemsItem(productData: prodData, quantity: item.product.quantity)
            guard let unwrappedProductItem = productItem else {
                ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message:"sendCheckoutXdmEvent - Cannot create '" + EVENT_TYPE_COMMERCE_CHECKOUTS + "' event as given product item is null.")
                return;
            }
            itemsList.append(unwrappedProductItem)
            createAndSendEvent(itemsList: itemsList,eventType: EVENT_TYPE_COMMERCE_CHECKOUTS)
        }
    }
    
    /// Creates and sends a cart purchase event to the Adobe Data Platform.
    /// A commerce.purchases} event is a Commerce} object with
    /// Commerce#setPurchases(Purchases)} and Commerce#setOrder(Order)}
    /// set, along with a ProductListItemsItem} list containing the details of all the
    /// products in the shopping cart. The Order} details the total cost and payment of the purchase.
    /// This method should be called when a final purchase is made of a shopping cart.
    static func sendPurchaseXdmEvent() {
        ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message:"sendPurchaseXdmEvent")
        var itemsList: [ProductListItemsItem] = []
        for item in adbMobileShoppingCart.items {
            let prodData:ProductData = ProductData(sku: item.product.sku, name: item.product.name, details: item.product.description, price: item.product.price, currency: item.product.currency, imageLarge: item.product.imageLarge, imageSmall: item.product.imageSmall)
            let productItem  = createProductListItemsItem(productData: prodData, quantity: item.product.quantity)
            guard let unwrappedProductItem = productItem else {
                ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message:"sendPurchaseXdmEvent - Cannot create '" + EVENT_TYPE_COMMERCE_PURCHASES + "' event as given product item is null.")
                return;
            }
            itemsList.append(unwrappedProductItem)
        }
        
        if(itemsList.isEmpty) {
            ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message:"sendPurchaseXdmEvent - Cannot create '" + EVENT_TYPE_COMMERCE_PURCHASES + "' as no items were found in cart.")
            return
        } else {
            
            /// Create PaymentItem which details the method of payment
            var paymentsItem = PaymentsItem()
            paymentsItem.currencyCode = CURRENCY_CODE_USD
            paymentsItem.paymentAmount = adbMobileShoppingCart.total
            paymentsItem.paymentType = PAYMENT_TYPE
            
            var paymentsItemList = [PaymentsItem]()
            paymentsItemList.append(paymentsItem)
            
            /// Create the Order
            var order = Order()
            order.currencyCode = CURRENCY_CODE_USD
            order.priceTotal = adbMobileShoppingCart.total
            order.payments = paymentsItemList
            
            /// Create Purchases action
            var purchases = Purchases()
            purchases.value  = 1
            
            /// Create Commerce and add Purchases action and Order details
            var commerce = Commerce()
            commerce.order = order
            commerce.purchases = purchases
            
            var xdmData = MobileSDKPlatformEventSchema()
            xdmData.eventType = EVENT_TYPE_COMMERCE_PURCHASES
            xdmData.commerce = commerce
            xdmData.productListItems = itemsList
            
            let event = ExperiencePlatformEvent(xdm:xdmData,data:nil)
            let responseHandler = ResponseHandler()
            ACPExperiencePlatform.sendEvent(experiencePlatformEvent: event, responseHandler: responseHandler)
            if responseHandler.onResponseCalled {
                ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message: String("Platform response has been recieved..."))
            }
        }
    }

   
    
    /// Helper method to construct and send the ExperiencePlatformEvent} to the Experience Platform Extension.
    /// - Parameters:
    ///    - itemsList   : The  list of ProductListItemsItem}s associated with this commerce event.
    ///    - eventType   : event type for the given commerce event.
    private static func createAndSendEvent(itemsList: [ProductListItemsItem], eventType: String) {
        
        var commerce = Commerce()
        
        switch eventType {
        case EVENT_TYPE_COMMERCE_CHECKOUTS:
            print(EVENT_TYPE_COMMERCE_CHECKOUTS)
            var checkouts = Checkouts()
            checkouts.value = 1
            commerce.checkouts = checkouts
            
        case EVENT_TYPE_COMMERCE_PRODUCT_VIEWS:
            print(EVENT_TYPE_COMMERCE_PRODUCT_VIEWS)
            var productViews = ProductViews()
            productViews.value = 1
            commerce.productViews = productViews
            
        case EVENT_TYPE_COMMERCE_PRODUCT_LIST_ADDS:
            print(EVENT_TYPE_COMMERCE_PRODUCT_LIST_ADDS)
            var productListAdds = ProductListAdds()
            productListAdds.value = 1
            commerce.productListAdds = productListAdds
            
        case EVENT_TYPE_COMMERCE_PRODUCT_LIST_REMOVALS:
            print(EVENT_TYPE_COMMERCE_PRODUCT_LIST_REMOVALS)
            var productListRemovals = ProductListRemovals()
            productListRemovals.value = 1
            commerce.productListRemovals = productListRemovals
            
        case EVENT_TYPE_COMMERCE_PURCHASES:
            print(EVENT_TYPE_COMMERCE_PURCHASES)
            var purchases = Purchases()
            purchases.value = 1
            commerce.purchases = purchases
            
        default:
            ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message:"Unknown event type when sending Commerce event. Ignoring event.")
            return
        }
        
        var xdmData = MobileSDKPlatformEventSchema()
        xdmData.eventType = eventType
        xdmData.commerce  = commerce
        xdmData.productListItems = itemsList
        let event = ExperiencePlatformEvent(xdm:xdmData,data:nil)
        let responseHandler = ResponseHandler()
        ACPExperiencePlatform.sendEvent(experiencePlatformEvent: event, responseHandler: responseHandler)
        if responseHandler.onResponseCalled {
            ACPCore.log(ACPMobileLogLevel.debug, tag: LOG_TAG, message:"Platform response has been recieved...")
        }
    }
    
    /// Helper method to convert an com.adobe.marketing.mobile.platform.app.ProductContent.ProductItem} to an
    /// ProductListItemsItem} object.
    /// If quantity} is zero, then only the name} and sku} are added to the ProductItem}.
    /// - Parameters :
    ///     - productData          : Information about a com.adobe.marketing.mobile.platform.app.ProductContent.ProductItem}.
    ///     -  quantity                : The specified quantity of ProductListItemsItem}. If zero, quantity, price, and currency data are not added to the result.
    /// - Returns:
    ///     - ProductListItemsItem : A list of products populated from the given com.adobe.marketing.mobile.platform.app.ProductContent.ProductItem},
    /// or null if item} is null
    private static func createProductListItemsItem(productData : ProductData?, quantity: Int) -> ProductListItemsItem? {
        
        var productItem = ProductListItemsItem()
        guard let productData = productData else {
            return productItem
        }
        productItem.name = productData.name
        productItem.sKU  = productData.sku
        if(quantity > 0) {
            productItem.currencyCode = productData.currency
            productItem.quantity     = Int64(quantity)
            productItem.priceTotal   = computeTotal(price: productData.price, quantity:quantity)
        }
        return productItem
    }
    
    /// Computes the total cost of a number of items.
    /// - Parameters :
    ///     - price              : The price of the product item.
    ///     - quantity      : The quantity of the items.
    /// - Returns:
    ///     - TotalCost         :   The total cost of the items
    private static func computeTotal(price :Float, quantity: Int) -> Float {
        return price * Float(quantity)
    }
}

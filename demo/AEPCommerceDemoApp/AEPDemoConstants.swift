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

struct AEPDemoConstants {
    
    struct Numbers {
        
        static let MIN_QTY = 1
        static let MAX_QTY = 25
    }
    
    struct Strings {
        
        // Commerce App : Labels of UI Components
        static let APP_NAME = "AEP Extension Demo"
        static let TITLE_ITEM_LIST = "Items"
        static let TITLE_ITEM_DETAIL = "Item Detail"
        static let PRODUCT_IMAGE = "Product Image"
        static let QUANTITY = "Quantity:"
        static let PRICE = "Price"
        static let ADD_TO_CART = "Add to Cart"
        static let TITLE_CART_LIST = "Shopping Cart"
        static let REMOVE = "Remove"
        static let SAVE_FOR_LATER = "Save for later"
        static let CHECKOUT = "Checkout"
        static let PURCHASE = "Purchase"
        static let SELECT_PAYMENT_METHOD = "Select Payment Method"
        static let TOTAL_PRICE = "Total Price $ "
        static let PRODUCT_LIST_FILENAME = "product_list_colors"
        
        // Commerce App : Snackbar messages
        static let ITEM_ADDED_MSG = " item added to shopping cart."
        static let PURCHASE_COMPLETE_MSG = "Thank you for your purchase!"
        static let CART_EMPTY_ERROR_MSG  = "Sorry!, No item in the shopping cart to place an order. Add at least one item to place an order."
        static let CART_EMPTY_MSG = "There are no item in the shopping cart to clear."
        static let CART_CLEARING_MSG = "Sure!, all the selected items are removed from the Shopping Cart."
        
        // Griffon : Labels of UI Components
        static let GRIFFON_CONNECT = "Connect"
        static let GRIFFON_DISCONNECT = "Disconnect"
        
        // Griffon : Snackbar messages
        static let GRIFFON_URL_INVALID = "Enter a valid URL of the Griffon Session"
        static let GRIFFON_SESSION_ACTIVE = "Connection to a Griffon Session is already active or in progress. Disconnect before trying to connect..."
        static let GRIFFON_SESSION_DISCONNECTED = "Griffon Session has been disconnected"
        static let GRIFFON_SESSION_NOT_ACTIVE = "Griffon Session is not active..."
        static let GRIFFON_URL_VALIDATION_STRING = "adb_validation_sessionid"
    }
}


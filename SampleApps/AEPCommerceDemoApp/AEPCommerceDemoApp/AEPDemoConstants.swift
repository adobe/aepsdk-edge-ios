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

        static let minQty = 1
        static let maxQty = 25
    }

    struct Strings {

        // MARK: Commerce App : Labels of UI Components
        static let appName = "AEP Extension Demo"
        static let titleItemList = "Items"
        static let titleItemDetail = "Item Detail"
        static let productImage = "Product Image"
        static let quantity = "Quantity:"
        static let price = "Price"
        static let addToCart = "Add to Cart"
        static let titleCartList = "Shopping Cart"
        static let remove = "Remove"
        static let saveForLater = "Save for later"
        static let checkout = "Checkout"
        static let purchase = "Purchase"
        static let selectPaymentMethod = "Select Payment Method"
        static let totalPrice = "Total Price $ "
        static let productListFilename = "product_list_colors"

        // MARK: Commerce App : Snackbar messages
        static let itemAddedMsg = " item added to shopping cart."
        static let purchaseCompleteMsg = "Thank you for your purchase!"
        static let cartEmptyErrorMsg  = "Sorry!, No item in the shopping cart to place an order. Add at least one item to place an order."
        static let cartEmptyMsg = "There are no item in the shopping cart to clear."
        static let cartClearMsg = "Sure!, all the selected items are removed from the Shopping Cart."

        // MARK: Assurance : Labels of UI Components
        static let assuranceConnect = "Connect"
        static let assuranceDisconnect = "Disconnect"

        // MARK: Assurance : Snackbar messages
        static let assuranceUrlInvalid = "Enter a valid URL of the Assurance Session"
        static let assuranceSessionActive = "A connection to an Assurance Session is already or in progress. Disconnect before trying to connect..."
        static let assuranceSessionNotActive = "Assurance Session is not active..."
        static let assuranceUrlValidationString = "adb_validation_sessionid"
    }
}

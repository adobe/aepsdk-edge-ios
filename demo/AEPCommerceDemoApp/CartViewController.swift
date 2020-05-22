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
import UIKit
import ACPExperiencePlatform

class CartViewController: UIViewController {
    
    @IBOutlet var shoppingCartTableView: UITableView!
    @IBOutlet var orderTotalLbl: UILabel!
    @IBOutlet var checkoutBtn: UIButton!
    @IBOutlet var appNameLbl: UILabel!
    @IBOutlet var shoppingCartHeadingLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appNameLbl.text = AEPDemoConstants.Strings.APP_NAME
        shoppingCartHeadingLbl.text = AEPDemoConstants.Strings.TITLE_CART_LIST
        shoppingCartTableView.delegate = self
        shoppingCartTableView.dataSource = self
        shoppingCartTableView.reloadData()
        orderTotalLbl.text = AEPDemoConstants.Strings.TOTAL_PRICE + " $ " + String(format: "%.2f", adbMobileShoppingCart.total)
    }
    
    @IBAction func gotoCheckoutPage(_ sender: UIButton) {
        
        if adbMobileShoppingCart.items.isEmpty {
            Snackbar(message : AEPDemoConstants.Strings.CART_EMPTY_ERROR_MSG)
        } else {
            self.performSegue(withIdentifier: "gotoCheckoutPage", sender: self)
        }
    }
    
    @IBAction func SCartCancelBtn(_ sender: UIButton) {
        if adbMobileShoppingCart.items.isEmpty {
            Snackbar(message : AEPDemoConstants.Strings.CART_EMPTY_MSG)
        } else {
            clearCart()
            Snackbar(message : AEPDemoConstants.Strings.CART_CLEARING_MSG)
        }
    }
    
    func clearCart() {
        
        for item in adbMobileShoppingCart.items {
            let prodData:ProductData = ProductData(sku: item.product.sku, name: item.product.name, details: item.product.description, price: item.product.price, currency: item.product.currency, imageLarge: item.product.imageLarge, imageSmall: item.product.imageSmall)
            CommerceUtil.sendProductListRemoveXdmEvent(productData: prodData, quantity: item.product.quantity)
        }
        adbMobileShoppingCart.clearCart()
        shoppingCartTableView.reloadData()
        orderTotalLbl.text = AEPDemoConstants.Strings.TOTAL_PRICE + String(format: "%.2f", adbMobileShoppingCart.total)
    }
}

extension CartViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return adbMobileShoppingCart.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let product = adbMobileShoppingCart.items[indexPath.row].product
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell") as! ShoppingItemCell
        cell.setProduct(product:product)
        cell.delegate = self
        return cell
    }
}

extension CartViewController: CartDelegate {
    
    // MARK: - CartDelegate
    func remove(cell: ShoppingItemCell) {
        guard let indexPath = shoppingCartTableView.indexPath(for: cell) else { return }
        let product = adbMobileShoppingCart.items[indexPath.row]
        adbMobileShoppingCart.remove(product: product.product)
        
        let prodData:ProductData = ProductData(sku: product.product.sku, name: product.product.name, details: product.product.description, price: product.product.price, currency: product.product.currency, imageLarge: product.product.imageLarge, imageSmall: product.product.imageSmall)
        CommerceUtil.sendProductListRemoveXdmEvent(productData: prodData, quantity: product.product.quantity)
        shoppingCartTableView.reloadData()
        orderTotalLbl.text = AEPDemoConstants.Strings.TOTAL_PRICE + String(format: "%.2f", adbMobileShoppingCart.total)    }
}

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

import AEPEdge
import Foundation
import UIKit

class CartViewController: UIViewController {

    @IBOutlet var shoppingCartTableView: UITableView!
    @IBOutlet var orderTotalLbl: UILabel!
    @IBOutlet var checkoutBtn: UIButton!
    @IBOutlet var appNameLbl: UILabel!
    @IBOutlet var shoppingCartHeadingLbl: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        appNameLbl.text = AEPDemoConstants.Strings.appName
        shoppingCartHeadingLbl.text = AEPDemoConstants.Strings.titleCartList
        shoppingCartTableView.delegate = self
        shoppingCartTableView.dataSource = self
        shoppingCartTableView.reloadData()
        orderTotalLbl.text = AEPDemoConstants.Strings.totalPrice + " $ " + String(format: "%.2f", adbMobileShoppingCart.total)
    }

    @IBAction func gotoCheckoutPage(_ sender: UIButton) {

        if adbMobileShoppingCart.items.isEmpty {
            snackbar(message: AEPDemoConstants.Strings.cartEmptyErrorMsg)
        } else {
            self.performSegue(withIdentifier: "gotoCheckoutPage", sender: self)
        }
    }

    @IBAction func SCartCancelBtn(_ sender: UIButton) {
        if adbMobileShoppingCart.items.isEmpty {
            snackbar(message: AEPDemoConstants.Strings.cartEmptyMsg)
        } else {
            clearCart()
            snackbar(message: AEPDemoConstants.Strings.cartClearMsg)
        }
    }

    func clearCart() {

        CommerceUtil.sendCartClearXdmEvent()
        adbMobileShoppingCart.clearCart()
        shoppingCartTableView.reloadData()
        orderTotalLbl.text = AEPDemoConstants.Strings.totalPrice + String(format: "%.2f", adbMobileShoppingCart.total)
    }
}

extension CartViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return adbMobileShoppingCart.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let product = adbMobileShoppingCart.items[indexPath.row].product
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as? ShoppingItemCell
            ?? ShoppingItemCell(style: .default, reuseIdentifier: "ProductCell")

        cell.setProduct(product: product)
        cell.delegate = self
        return cell
    }
}

extension CartViewController: CartDelegate {

    // MARK: - CartDelegate
    func remove(cell: ShoppingItemCell) {
        guard let indexPath = shoppingCartTableView.indexPath(for: cell) else { return }
        let cartItem = adbMobileShoppingCart.items[indexPath.row]
        adbMobileShoppingCart.remove(product: cartItem.product)
        CommerceUtil.sendProductListRemoveXdmEvent(productData: cartItem.product.productData, quantity: cartItem.product.quantity)
        shoppingCartTableView.reloadData()
        orderTotalLbl.text = AEPDemoConstants.Strings.totalPrice + String(format: "%.2f", adbMobileShoppingCart.total)    }
}

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

class CartViewController: UIViewController {
    
    @IBOutlet var shoppingCartTableView: UITableView!
    @IBOutlet var orderTotalLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("Shopping Cart Page has been loaded...: \(adbMobileShoppingCart.total)" )
        shoppingCartTableView.delegate = self
        shoppingCartTableView.dataSource = self
        orderTotalLbl.text = "Order Total $ " + String(format: "%.2f", adbMobileShoppingCart.total)
    }
    
    @IBAction func SCartCancelBtn(_ sender: UIButton) {
        print("Shopping Cart Cancel Button has been clicked....")
        clearCart()
    }
    
    @IBAction func SCartOrderNowBtn(_ sender: UIButton) {
        print("Shopping Cart Order Now Button has been clicked....")
        
        if adbMobileShoppingCart.items.isEmpty {
            print("Sorry, No item in the shopping cart to place an order.So, add atleast one item to place an order.")
        } else {
            for item in adbMobileShoppingCart.items {
                print(" Sku : " + item.product.sku +  ", Name : " +  item.product.name +  ", Qty : \(item.product.quantity), UnitPrice : \(item.product.price),  Subtotal : \(Float(item.product.quantity)*item.product.price)")
            }
            print("Total Cost : \(adbMobileShoppingCart.total)")
            
            // Todo : Send this Event to Platform - and then clean the cart
            // Call sendEvent()
            // clearCart()
        }
    }
    
    func clearCart() {
        adbMobileShoppingCart.clearCart()
        shoppingCartTableView.reloadData()
        orderTotalLbl.text = "Order Total $ " + String(format: "%.2f", adbMobileShoppingCart.total)
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
        return cell
    }
}

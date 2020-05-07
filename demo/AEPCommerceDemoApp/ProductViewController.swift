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

import UIKit

var adbMobileShoppingCart = ShoppingCart()

class ProductViewController: UIViewController {
    
    @IBOutlet var productImage: UIImageView!
    @IBOutlet var productSku: UILabel!
    @IBOutlet var productName: UILabel!
    @IBOutlet var productDetails: UILabel!
    @IBOutlet var productCurrency: UILabel!
    @IBOutlet var productPrice: UILabel!
    @IBOutlet var productQty: UIPickerView!
    
    // let adbMobileShoppingCart = ShoppingCart()
    
    var productData:ProductData?
    var qtyOrdered: Int = 1
    private let qtySource = [1,2,3,4,5]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\((productData?.imageSmall)!)")
        productImage.image = UIImage(named: "\((productData?.imageSmall)!)")
        productImage.layer.cornerRadius = 30
        productImage.clipsToBounds = true
        productSku.text = productData?.sku
        productName.text = productData?.name
        productDetails.text = productData?.details
        productCurrency.text = productData?.currency
        productPrice.text = "\((productData?.price)!)"
        productQty.dataSource = self
        productQty.delegate = self
        productQty.setValue(UIColor.white, forKey: "textColor")
        
    }
    
    @IBAction func AddToCartBtn(_ sender: UIButton) {
        
        print("Add To Cart Button has been clicked....")
        
        if let unwrappedproductData = productData {
            let product = Product(imageLarge:unwrappedproductData.imageLarge, sku:unwrappedproductData.sku, name: unwrappedproductData.name, price: unwrappedproductData.price, quantity:qtyOrdered )
            adbMobileShoppingCart.add(product: product)
            adbMobileShoppingCart.listTheContentOfCart()
        }
        // Todo : Send this Event to Platform
        
    }
}

extension ProductViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return qtySource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        qtyOrdered = qtySource[row]
        print("From pickerView : qtyOrdered = \(qtyOrdered)")
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(qtySource[row])
    }
}

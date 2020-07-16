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
    @IBOutlet var appNameLbl: UILabel!
    @IBOutlet var itemListLbl: UILabel!
    @IBOutlet var quantityLbl: UILabel!
    @IBOutlet var priceLbl: UILabel!
    @IBOutlet var addToCartBtn: UIButton!

    var productData: ProductData?
    var qtyOrdered: Int = 1
    private var qtySource: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        appNameLbl.text = AEPDemoConstants.Strings.appName
        quantityLbl.text = AEPDemoConstants.Strings.quantity
        priceLbl.text = AEPDemoConstants.Strings.price
        addToCartBtn.setTitle(AEPDemoConstants.Strings.addToCart, for: .normal)
        guard let productData = productData else {
               print("Not a valid product!")
               return
           }
        let prodData = ProductData(sku: productData.sku,
                                   name: productData.name,
                                   details: productData.details,
                                   price: productData.price,
                                   currency: productData.currency,
                                   imageLarge: productData.imageLarge,
                                   imageSmall: productData.imageSmall)
        
        productImage.image = UIImage(named: "\((prodData.imageSmall))")
        productImage.layer.cornerRadius = 30
        productImage.clipsToBounds = true
        productSku.text = prodData.sku
        productName.text = prodData.name
        productDetails.text = prodData.details
        productCurrency.text = prodData.currency
        productPrice.text = "\((prodData.price))"
        for  index in 1...25 {
            qtySource.append(index)
        }
        productQty.dataSource = self
        productQty.delegate = self
        productQty.setValue(UIColor.white, forKey: "textColor")
        CommerceUtil.sendProductViewXdmEvent(productData: prodData)
    }

    @IBAction func addToCartBtn(_ sender: UIButton) {

        guard let productData = productData else {
            print("Not a valid product!")
            return
        }
        let prodData: ProductData = ProductData(sku: productData.sku,
                                                name: productData.name,
                                                details: productData.details,
                                                price: productData.price,
                                                currency: productData.currency,
                                                imageLarge: productData.imageLarge,
                                                imageSmall: productData.imageSmall)
        
        let product = Product(productData: prodData, quantity: qtyOrdered)
        adbMobileShoppingCart.add(product: product)

        let message  = "\(product.quantity) quantities of " + product.productData.name + AEPDemoConstants.Strings.itemAddedMsg
        snackbar(message: message)
        CommerceUtil.sendProductListAddXdmEvent(productData: prodData, quantity: qtyOrdered)
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
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(qtySource[row])
    }
}

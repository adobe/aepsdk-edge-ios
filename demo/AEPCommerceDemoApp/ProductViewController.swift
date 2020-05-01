//
// ADOBE CONFIDENTIAL
//
// Copyright 2020 Adobe
// All Rights Reserved.
//
// NOTICE: All information contained herein is, and remains
// the property of Adobe and its suppliers, if any. The intellectual
// and technical concepts contained herein are proprietary to Adobe
// and its suppliers and are protected by all applicable intellectual
// property laws, including trade secret and copyright laws.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from Adobe.
//


import UIKit


var ADBMobileShoppingCart = ShoppingCart()


class ProductViewController: UIViewController {

    @IBOutlet var ProductImage: UIImageView!
    @IBOutlet var ProductSku: UILabel!
    @IBOutlet var ProductName: UILabel!
    @IBOutlet var ProductDetails: UILabel!
    @IBOutlet var ProductCurrency: UILabel!
    @IBOutlet var ProductPrice: UILabel!
    @IBOutlet var ProductQty: UIPickerView!
    
    // let ADBMobileShoppingCart = ShoppingCart()

    var productData:ProductData?
    var qtyOrdered: Int = 1
    private let qtySource = [1,2,3,4,5]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\((productData?.imageSmall)!)")
        ProductImage.image = UIImage(named: "\((productData?.imageSmall)!)")
        ProductImage.layer.cornerRadius = 30
        ProductImage.clipsToBounds = true
        ProductSku.text = productData?.sku
        ProductName.text = productData?.name
        ProductDetails.text = productData?.details
        ProductCurrency.text = productData?.currency
        ProductPrice.text = "\((productData?.price)!)"
        ProductQty.dataSource = self
        ProductQty.delegate = self
        ProductQty.setValue(UIColor.white, forKey: "textColor")
        
    }
    
    
    @IBAction func AddToCartBtn(_ sender: UIButton) {
        
        print("Add To Cart Button has been clicked....")
        
        let product = Product(imageLarge:productData!.imageLarge, sku:productData!.sku, name: productData!.name, price: productData!.price, quantity:qtyOrdered )
        ADBMobileShoppingCart.add(product: product)
        ADBMobileShoppingCart.printme()
        
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

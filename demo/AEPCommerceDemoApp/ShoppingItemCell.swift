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

class ShoppingItemCell: UITableViewCell {

    @IBOutlet var productImageView: UIImageView!
    @IBOutlet var productNameLbl: UILabel!
    @IBOutlet var productUnitPriceLbl: UILabel!
    @IBOutlet var productQtyLbl: UILabel!
    @IBOutlet var productPriceLbl: UILabel!
 
    func setProduct(product: Product) {

        productImageView.image = UIImage(named:product.imageLarge)
        productNameLbl.text = product.name
        productUnitPriceLbl.text  = String(format: "%.2f", product.price)
        productQtyLbl.text = String(Int(product.quantity))
        productPriceLbl.text = String(format: "%.2f", product.subtotal)
    }

}

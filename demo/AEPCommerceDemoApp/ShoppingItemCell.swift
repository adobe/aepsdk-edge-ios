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

    @IBOutlet var ProductImageView: UIImageView!
    @IBOutlet var ProductNameLbl: UILabel!
    @IBOutlet var ProductUnitPriceLbl: UILabel!
    @IBOutlet var ProductQtyLbl: UILabel!
    @IBOutlet var ProductPriceLbl: UILabel!
 
    func setProduct(product: Product) {

        ProductImageView.image = UIImage(named:product.imageLarge)
        ProductNameLbl.text = product.name
        ProductUnitPriceLbl.text  = String(format: "%.2f", product.price)
        ProductQtyLbl.text = String(Int(product.quantity))
        ProductPriceLbl.text = String(format: "%.2f", product.subTotal())
    }

}

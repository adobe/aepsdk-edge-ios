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


//import Foundation
//
//public class CartItem {
//
//    var product : Product
//    var quantity : Int = 1
//    var subtotal: Float { return product.price * Float(quantity) }
//
//    init(product: Product) {
//        self.product = product
//    }
//}

import Foundation

public class CartItem: CustomStringConvertible {
    
    var product : Product
    public var description: String {
        return "(Product : \(product))"
    }
    
    init(product: Product) {
        self.product = product
    }
}

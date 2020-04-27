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


import Foundation

struct Product: Codable, Equatable {

    var imageLarge: String
    var sku: String
    var name: String
    var price: Float
    var quantity : Int = 1
    func subTotal() -> Float{
        return price * Float(quantity)
    }
 }

extension Product {
    static func ==(lhs: Product, rhs: Product) -> Bool {
        return lhs.sku == rhs.sku   
    }
    
}

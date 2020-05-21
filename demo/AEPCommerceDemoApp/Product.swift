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

struct Product: Codable, Equatable, CustomStringConvertible {
    var description: String {
        return("Image : \(imageLarge): Sku: \(sku) : Name : \(name) : Unit Price :  \(price)")
    }
    var sku: String
    var name: String
    var price: Float
    var quantity : Int = 1
    var currency: String
    var imageSmall: String
    var imageLarge: String
    var subtotal: Float { return price * Float(quantity) }
}

extension Product {
    static func ==(lhs: Product, rhs: Product) -> Bool {
        return lhs.sku == rhs.sku
    }
}

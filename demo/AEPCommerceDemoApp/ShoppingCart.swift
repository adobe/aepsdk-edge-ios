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

class ShoppingCart {
    
    private(set) var items : [CartItem] = []
}

extension ShoppingCart {
    
    func clearCart(){
        items.removeAll()
    }
    
    func listTheContentOfCart() {
        for item in items {
            print(item)
        }
    }
    
    func add(product: Product) {
        
        print("Product added into Cart : \(product)")
        let item = items.filter { $0.product == product }
        if let unwrappedItem = item.first {
            unwrappedItem.product.quantity += product.quantity
            print("Item exists in the cart. So, Quantity has been increased ....")
        } else {
            items.append(CartItem(product: product))
            print("Item Not found - So, added to the cart as a new item....")
        }
    }
    
    var totalQuantity : Float {
           return items.reduce(0) { value, item in
            value + Float(item.product.quantity)
        }
    }
    
    var total: Float {
        return items.reduce(0.0) { value, item in
            value + Float(item.product.quantity)*item.product.price
        }
    }
}

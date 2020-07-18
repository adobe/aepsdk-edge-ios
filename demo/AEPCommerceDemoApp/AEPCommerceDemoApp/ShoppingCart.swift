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

    private(set) var items: [CartItem] = []
}

extension ShoppingCart {

    func clearCart() {
        items.removeAll()
    }

    func add(product: Product) {

        let item = items.filter { $0.product == product }
        if let unwrappedItem = item.first {
            unwrappedItem.product.quantity += product.quantity
        } else {
            items.append(CartItem(product: product))
        }
    }

    func remove(product: Product) {
        guard let index = items.firstIndex(where: { $0.product == product }) else { return}
        items.remove(at: index)
    }

    var totalQuantity: Float {
        return items.reduce(0) { value, item in
            value + Float(item.product.quantity)
        }
    }

    var total: Float {
        return items.reduce(0.0) { value, item in
            value + Float(item.product.quantity) * item.product.productData.price
        }
    }
}

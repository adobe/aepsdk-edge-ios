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

class ShoppingCart {
    
    private(set) var items : [CartItem] = []
}

extension ShoppingCart {
    
    func clearCart(){
        items.removeAll()
    }

    func printme() {
        print(items)
        print("Number of items in the Shopping Cart : \(items.count) " )
        for item in items {
            print(item.product, item.product.quantity, item.quantity, item.subTotal)
        }
    }

    func add(product: Product) {
        
        print("From Add method Product Name : " + product.name + " Price : \(product.price)" + "Qty : \(product.quantity)")
        
        let item = items.filter { $0.product == product }
        if item.first != nil {
            item.first!.product.quantity += product.quantity
            print("Item exists in the cart. So, Quantity has been increased ....")
        } else {
            items.append(CartItem(product: product))
            print("Item Not found - So, added to the cart as a new item....")
        }
    }
    
    

    var totalQuantity : Float {
        get { return items.reduce(0) { value, item in
            value + Float(item.product.quantity)
            }
        }
    }
    
     var total: Float {
           get { return items.reduce(0.0) { value, item in
            value + Float(item.product.quantity)*item.product.price
               }
           }
       }
    

}

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


public class ProductDataLoader {
    
    var productData = [ProductData]()
    
    init() {
        loadProducts()
    }
    
    func loadProducts() {
        
        if let jsonFileLocation = Bundle.main.url(forResource: "product_list_colors", withExtension: "json") {
                let data = try? Data(contentsOf: jsonFileLocation)
                let jsonDecoder = JSONDecoder()
                var productDataFromJson:[ProductData]!
                if let unwrappedData = data {
                     productDataFromJson = try? jsonDecoder.decode([ProductData].self, from: unwrappedData)
                }
                if let unwrappedProductDataFromJson = productDataFromJson {
                    self.productData = unwrappedProductDataFromJson
                }
        }
    }
    
 
}

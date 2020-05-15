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

import UIKit

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var appTitle: UILabel!
    @IBOutlet var productList: UITableView!
    @IBOutlet var cartImage: UIImageView!
    @IBOutlet var griffonImage: UIImageView!
    
    let productData = ProductDataLoader().productData
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cartImage.layer.cornerRadius = cartImage.frame.size.width/3
        cartImage.clipsToBounds = true
        
        let productData = ProductDataLoader().productData
        print(productData)
        productList.reloadData()
        productList.delegate = self
        productList.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundView?.backgroundColor = .black
        cell.imageView?.image = UIImage(named: "\((productData[indexPath.row].imageSmall))")
        cell.textLabel?.text = productData[indexPath.row].name + "     " + productData[indexPath.row].currency + "  \((productData[indexPath.row].price))"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Todo : Send this Event to Platform - and then performSegue
        performSegue(withIdentifier: "showProductDetailsPage", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ProductViewController {
            if let unwrappedIndexPathForSelectedRow = productList.indexPathForSelectedRow {
                destination.productData = productData[unwrappedIndexPathForSelectedRow.row]
            }
        }
    }
    
    @IBAction func CartBtn(_ sender: UIButton) {
        print("Cart Button Clicked....: \(adbMobileShoppingCart.total)" )
        self.performSegue(withIdentifier: "showShoppingCartPage", sender: self)
    }
    
    @IBAction func GriffonBtn(_ sender: UIButton) {
        print("Griffon Connect Btn has been clicked....")
        self.performSegue(withIdentifier: "showGriffonPage", sender: self)
    }
}

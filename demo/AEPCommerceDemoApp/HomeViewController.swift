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




class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
    @IBOutlet var AppTitle: UILabel!    
    @IBOutlet var ProductList: UITableView!
    @IBOutlet var CartImage: UIImageView!
    @IBOutlet var GriffonImage: UIImageView!
    
    let productData = ProductDataLoader().productData
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CartImage.layer.cornerRadius = CartImage.frame.size.width/3
        CartImage.clipsToBounds = true


        let productData = ProductDataLoader().productData
        print(productData)
        ProductList.reloadData()
        ProductList.delegate = self
        ProductList.dataSource = self
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
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ProductViewController {
            destination.productData = productData[ProductList.indexPathForSelectedRow!.row]
        }
    }
    
    
    @IBAction func CartBtn(_ sender: UIButton) {
        print("Cart Button Clicked....: \(ADBMobileShoppingCart.total)" )
        self.performSegue(withIdentifier: "showShoppingCartPage", sender: self)
    }
    
    
    @IBAction func GriffonBtn(_ sender: UIButton) {
        print("Griffon Connect Btn has been clicked....")
        self.performSegue(withIdentifier: "showGriffonPage", sender: self)
    }
    
    
}


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

extension String {
    func frontPadding(toLength length: Int, withPad pad: String, startingAt index: Int) -> String {
        return String(String(self.reversed()).padding(toLength: length, withPad: pad, startingAt: index).reversed())
    }
}

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var appTitle: UILabel!
    @IBOutlet var productList: UITableView!
    @IBOutlet var cartBtn: UIButton!
    @IBOutlet var griffonBtn: UIButton!
    @IBOutlet var appTitleLbl: UILabel!

    let productData = ProductDataLoader().productData

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        appTitleLbl.text = AEPDemoConstants.Strings.APP_NAME

        cartBtn.layer.cornerRadius = 0.5 * cartBtn.bounds.size.width
        cartBtn.clipsToBounds = true
        productList.reloadData()
        productList.delegate = self
        productList.dataSource = self
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let name = productData[indexPath.row].name
        let currency = productData[indexPath.row].currency
        let price = String(productData[indexPath.row].price)
        let textContent = String(format: "%@ %@ %@", name.padding(toLength: 8, withPad: " ", startingAt: 0), currency, price.frontPadding(toLength: 10, withPad: " ", startingAt: 0)  )
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundView?.backgroundColor = .black
        cell.imageView?.image = UIImage(named: "\((productData[indexPath.row].imageSmall))")
        cell.textLabel?.text = textContent
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

    @IBAction func gotoCartPage(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showShoppingCartPage", sender: self)
    }

    @IBAction func gotoGriffonConnectPage(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showGriffonPage", sender: self)
    }
}

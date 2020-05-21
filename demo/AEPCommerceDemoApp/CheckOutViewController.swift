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

class CheckOutViewController: UIViewController {
    
    @IBOutlet var paymentMethod: UIPickerView!
    @IBOutlet var totalPriceLbl: UILabel!
    @IBOutlet var paymentMethoidPicker: UIPickerView!
    @IBOutlet var purchaseNowBtn: UIButton!
    @IBOutlet var appNameLbl: UILabel!
    
    @IBOutlet var totalPriceTextLbl: UILabel!
    @IBOutlet var selectPaymentMethodlbl: UILabel!
    enum paymentMethods: String, CaseIterable {
        case Cash = "Cash"
        case Visa = "Visa"
        case Master = "Master"
        case Amex = "Amex"
        static let allValues = [Cash, Visa, Master, Amex]
    }
    
    private var selectedPaymentMethod: String  = "Cash"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        paymentMethod.delegate = self
        paymentMethod.dataSource = self
        CommerceUtil.sendCheckoutXdmEvent()
        totalPriceTextLbl.text = AEPDemoConstants.Strings.TOTAL_PRICE
        selectPaymentMethodlbl.text = AEPDemoConstants.Strings.SELECT_PAYMENT_METHOD
        totalPriceLbl.text = String(format: "%.2f", adbMobileShoppingCart.total)
        appNameLbl.text = AEPDemoConstants.Strings.APP_NAME
        
    }
    
    @IBAction func purchaseNowBtn(_ sender: UIButton) {
        
        if adbMobileShoppingCart.items.isEmpty {
            Snackbar(message : AEPDemoConstants.Strings.CART_EMPTY_ERROR_MSG)
        } else {
            CommerceUtil.sendPurchaseXdmEvent()
            adbMobileShoppingCart.clearCart()
            totalPriceLbl.text = "\(adbMobileShoppingCart.total)"
            self.performSegue(withIdentifier: "gotoProductListPage", sender: self)
            Snackbar(message : AEPDemoConstants.Strings.PURCHASE_COMPLETE_MSG)
        }
    }
}

extension CheckOutViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return paymentMethods.allValues.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedPaymentMethod = String(describing: paymentMethods.allCases[row])
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(describing: paymentMethods.allCases[row])
    }
}

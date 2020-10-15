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

import AEPEdge
import UIKit

class CheckOutViewController: UIViewController {

    @IBOutlet var paymentMethod: UIPickerView!
    @IBOutlet var totalPriceLbl: UILabel!
    @IBOutlet var paymentMethoidPicker: UIPickerView!
    @IBOutlet var purchaseNowBtn: UIButton!
    @IBOutlet var appNameLbl: UILabel!

    @IBOutlet var totalPriceTextLbl: UILabel!
    @IBOutlet var selectPaymentMethodlbl: UILabel!
    enum PaymentMethods: String, CaseIterable {
        case cash = "Cash"
        case visa = "Visa"
        case master = "Master"
        case amex = "Amex"
        static let allValues = [cash, visa, master, amex]
    }

    private var selectedPaymentMethod: String  = "Cash"

    override func viewDidLoad() {
        super.viewDidLoad()
        paymentMethod.delegate = self
        paymentMethod.dataSource = self
        CommerceUtil.sendCheckoutXdmEvent()
        totalPriceTextLbl.text = AEPDemoConstants.Strings.totalPrice
        selectPaymentMethodlbl.text = AEPDemoConstants.Strings.selectPaymentMethod
        totalPriceLbl.text = String(format: "%.2f", adbMobileShoppingCart.total)
        appNameLbl.text = AEPDemoConstants.Strings.appName

    }

    @IBAction func purchaseNowBtn(_ sender: UIButton) {

        if adbMobileShoppingCart.items.isEmpty {
            snackbar(message: AEPDemoConstants.Strings.cartEmptyErrorMsg)
        } else {
            CommerceUtil.sendPurchaseXdmEvent()
            adbMobileShoppingCart.clearCart()
            totalPriceLbl.text = "\(adbMobileShoppingCart.total)"
            self.performSegue(withIdentifier: "gotoProductListPage", sender: self)
            snackbar(message: AEPDemoConstants.Strings.purchaseCompleteMsg)
        }
    }
}

extension CheckOutViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return PaymentMethods.allValues.count
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedPaymentMethod = String(describing: PaymentMethods.allCases[row])
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(describing: PaymentMethods.allCases[row])
    }
}

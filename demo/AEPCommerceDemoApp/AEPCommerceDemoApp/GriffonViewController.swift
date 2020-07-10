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
import UIKit
import ACPCore
import ACPGriffon

class GriffonViewController: UIViewController {
    
    @IBOutlet var griffonSessionURL: UITextField!
    @IBOutlet var appNameLbl: UILabel!
    
    var isConnected: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appNameLbl.text = AEPDemoConstants.Strings.APP_NAME
    }
    
    @IBAction func GriffonConnectBtn(_ sender: UIButton) {
        if !isConnected {
            guard let griffonURLText = griffonSessionURL.text else {
                return
            }
            if  griffonURLText.contains(AEPDemoConstants.Strings.GRIFFON_URL_VALIDATION_STRING) {
                if let url = URL(string: griffonURLText) {
                    isConnected = true
                    ACPGriffon.startSession(url)
                } else
                {
                    Snackbar(message : AEPDemoConstants.Strings.GRIFFON_URL_INVALID)
                }
            } else {
                Snackbar(message : AEPDemoConstants.Strings.GRIFFON_URL_INVALID)
            }
        } else {
            Snackbar(message : AEPDemoConstants.Strings.GRIFFON_SESSION_ACTIVE)
        }
    }
    
    @IBAction func GriffonDisconnectBtn(_ sender: UIButton) {
        if isConnected {
            ACPGriffon.endSession()
            Snackbar(message : AEPDemoConstants.Strings.GRIFFON_SESSION_DISCONNECTED)
            isConnected = false
        } else {
            Snackbar(message : AEPDemoConstants.Strings.GRIFFON_SESSION_NOT_ACTIVE)
        }
    }
}

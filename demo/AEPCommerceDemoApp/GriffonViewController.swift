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
    var isConnected: Bool = false
    
    @IBAction func GriffonConnectBtn(_ sender: UIButton) {
        if !isConnected {
            if let url = URL(string: griffonSessionURL.text ?? "") {
                print("Griffon Session URL : \(url)")
                ACPGriffon.startSession(url)
                isConnected = true
            }
        } else {
            print("Connection to a Griffon Session is already active. To connect to another Griffon Session, disconnect before trying to connect...")
        }
    }
    
    @IBAction func GriffonDisconnectBtn(_ sender: UIButton) {
        if isConnected {
            ACPGriffon.endSession()
            print("Griffon Session has been disconnected")
            isConnected = false
        } else {
            print("Griffon Session is not active...")
        }
    }
}

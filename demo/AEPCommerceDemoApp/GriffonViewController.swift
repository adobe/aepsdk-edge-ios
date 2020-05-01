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


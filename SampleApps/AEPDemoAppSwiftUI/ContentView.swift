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

import AEPConsent
import AEPCore
import AEPEdge
import AEPIdentity
import AEPServices
import SwiftUI

struct ContentView: View {
    // swiftlint:disable multiple_closures_with_trailing_closure
    @State private var ecid: String = ""

    var body: some View {
        VStack {
            Text("ECID:")
            Text(ecid)
            HStack {
                Text("Privacy: ")
                Button(action: {
                    MobileCore.setPrivacyStatus(PrivacyStatus.optedIn)
                    getECID()
                }) {
                    Text("in")
                }
                Button(action: {
                    MobileCore.setPrivacyStatus(PrivacyStatus.optedOut)
                    getECID()
                }) {
                    Text("out")
                }
                Button(action: {
                    MobileCore.setPrivacyStatus(PrivacyStatus.unknown)
                    getECID()
                }) {
                    Text("unknown")
                }
            }.padding()

            HStack {
                Text("Collect consent: ")
                Button(action: {
                    let consents = Consents()
                    consents.collect = ConsentValue(.yes)
                    Consent.updateConsents(consents: consents)
                    printCurrentConsent()
                }) {
                    Text("yes")
                }
                Button(action: {
                    let consents = Consents()
                    consents.collect = ConsentValue(.no)
                    Consent.updateConsents(consents: consents)
                    printCurrentConsent()
                }) {
                    Text("no")
                }
            }.padding()

            Button(action: {
                let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                                      data: ["data": ["test": "data"]])
                Edge.sendEvent(experienceEvent: experienceEvent, { (handles: [EdgeEventHandle]) in
                    for handle in handles {
                        Log.debug(label: "AEPDemoApp", "Received handle with type \(handle.type ?? "unknown"), payload: \(handle.payload ?? [])")
                    }
                })
                printCurrentConsent()
            }) {
                Text("Ping to ExEdge")
            }
        }
    }

    private func printCurrentConsent() {
        Consent.getConsents { (consents: Consents?, error: Error?) in
            guard error == nil, let consents = consents else { return }
            print("Current consent \(consents.asDictionary(dateEncodingStrategy: .iso8601) ?? [:])")
        }
    }

    private func getECID() {
        Identity.getExperienceCloudId { value, error in
            if error != nil {
                self.ecid = ""
                return
            }

            self.ecid = value ?? ""
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

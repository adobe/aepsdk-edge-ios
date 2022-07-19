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

import AEPCore
import AEPEdge
#if os(ios)
import AEPEdgeConsent
import AEPAssurance
import AEPEdgeIdentity
#endif
import AEPServices
import SwiftUI

struct ContentView: View {
    @State private var ecid: String = ""
    @State private var dataContent: String = "data is displayed here"

    var body: some View {
        NavigationView {

            #if os(iOS)
            VStack {

                NavigationLink(destination: AssuranceView()) {
                    Text("Assurance")
                }
                VStack {
                    Text("Edge").frame(maxWidth: .infinity, alignment: .leading).padding(10).font(.system(size: 24))
                    Button("Send Event", action: {
                        let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                                              data: ["data": ["test": "data"]])
                        Edge.sendEvent(experienceEvent: experienceEvent, { (handles: [EdgeEventHandle]) in
                            let encoder = JSONEncoder()
                            encoder.outputFormatting = .prettyPrinted
                            guard let data = try? encoder.encode(handles) else {
                                self.dataContent = "failed to encode EdgeEventHandle"
                                return
                            }
                            self.dataContent = String(data: data, encoding: .utf8) ?? "failed to encode JSON to string"
                        })
                    })
                    .frame(maxWidth: .infinity)
                    .padding()
                }.background(Color("InputColor1"))
                VStack {
                    Text("Collect Consent").frame(maxWidth: .infinity, alignment: .leading).padding(10).font(.system(size: 24))
                    HStack {
                        Spacer()
                        Button("Yes", action: {
                            Consent.update(with: ["consents": ["collect": ["val": "y"]]])
                            self.getConsents()
                        })
                        Spacer()
                        Button("No", action: {
                            Consent.update(with: ["consents": ["collect": ["val": "n"]]])
                            self.getConsents()
                        })
                        Spacer()
                        Button("Pending", action: {
                            Consent.update(with: ["consents": ["collect": ["val": "p"]]])
                            self.getConsents()
                        })
                        Spacer()
                        Button("Get Consents", action: {
                            self.getConsents()
                        })
                        Spacer()
                    }.padding()
                }.background(Color("InputColor2"))
                VStack {
                    Text("Edge Identity").frame(maxWidth: .infinity, alignment: .leading).padding(10).font(.system(size: 24))
                    HStack(alignment: .top) {
                        Spacer()
                        Button("Update", action: {
                            self.updateIdentities()
                        })
                        Spacer()
                        Button("Remove", action: {
                            self.removeIdentities()
                        })
                        Spacer()
                        Button("Get Identities", action: {
                            self.getIdentities()
                        })
                        Spacer()
                    }.padding()
                }.background(Color("InputColor1"))
                VStack {
                    Text("Mobile Core").frame(maxWidth: .infinity, alignment: .leading).padding(10).font(.system(size: 24))
                    HStack {
                        Button("Reset IDs", action: {
                            MobileCore.resetIdentities()
                        }).padding()
                    }
                }.background(Color("InputColor2"))
                Divider()
                VStack {
                    Text("ECID:").bold().frame(maxWidth: .infinity, alignment: .leading).padding(10)
                    Text(ecid)
                }
                Divider()
                ScrollView {
                    Text(dataContent).frame(maxWidth: .infinity, maxHeight: .infinity)
                }.background(Color(red: 0.97, green: 0.97, blue: 0.97, opacity: 1))
            }.onAppear {
                self.getECID()
            }
            #endif

            // TODO: Revisit this code, once all Edge extensions have tvOS support
            #if os(tvOS)
            VStack {
                Text("Edge").frame(maxWidth: .infinity, alignment: .leading).padding(10).font(.system(size: 24))
                Button("Send Event", action: {
                    let experienceEvent = ExperienceEvent(xdm: ["xdmtest": "data"],
                                                          data: ["data": ["test": "data"]])
                    Edge.sendEvent(experienceEvent: experienceEvent, { (handles: [EdgeEventHandle]) in
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = .prettyPrinted
                        guard let data = try? encoder.encode(handles) else {
                            self.dataContent = "failed to encode EdgeEventHandle"
                            return
                        }
                        self.dataContent = String(data: data, encoding: .utf8) ?? "failed to encode JSON to string"
                    })
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }.background(Color("InputColor1"))
            #endif
        }
    }

    #if os(iOS)
    private func getECID() {
        Identity.getExperienceCloudId { value, error in
            if error != nil {
                self.ecid = ""
                return
            }

            self.ecid = value ?? ""
        }
    }

    private func updateIdentities() {
        let map = IdentityMap()
        map.add(item: IdentityItem.init(id: "primary@email.com", authenticatedState: .ambiguous, primary: true), withNamespace: "Email")
        map.add(item: IdentityItem(id: "secondary@email.com"), withNamespace: "Email")
        map.add(item: IdentityItem(id: "zzzyyyxxx"), withNamespace: "UserId")
        map.add(item: IdentityItem(id: "John Doe"), withNamespace: "UserName")
        Identity.updateIdentities(with: map)
        getIdentities()
    }

    private func removeIdentities() {
        Identity.removeIdentity(item: IdentityItem(id: "secondary@email.com"), withNamespace: "Email")
        getIdentities()
    }

    private func getIdentities() {
        Identity.getIdentities { identityMap, _ in
            if let identityMap = identityMap {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                guard let data = try? encoder.encode(identityMap) else {
                    self.dataContent = "failed to encode IdentityMap"
                    return
                }
                self.dataContent = String(data: data, encoding: .utf8) ?? "failed to encode JSON to string"
            } else {
                self.dataContent = "IdentityMap was nil"
            }
        }
    }

    private func getConsents() {
        Consent.getConsents { consents, error in
            guard error == nil, let consents = consents else { return }
            guard let jsonData = try? JSONSerialization.data(withJSONObject: consents, options: .prettyPrinted) else { return }
            guard let jsonStr = String(data: jsonData, encoding: .utf8) else { return }
            self.dataContent = jsonStr
        }
    }
    #endif

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

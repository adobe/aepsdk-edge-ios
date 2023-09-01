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
import AEPEdgeConsent
import AEPEdgeIdentity
import AEPServices
import SwiftUI

#if os(iOS)
import AEPAssurance
#endif

struct ContentView: View {
    @State private var ecid: String = ""
    @State private var dataContent: String = "Data is displayed here (scrollable)"
    @State private var selectedRegion: RegionId = .nil_value
    @State private var version: String = ""

    #if os(iOS)
    let dividerColor = Color(.black)
    let secondaryBackgroundColor = Color("InputColor2")
    #elseif os(tvOS)
    let dividerColor = Color(.white)
    let secondaryBackgroundColor = Color(.clear)
    #endif

    var body: some View {
        NavigationView {
            VStack {
                edgeDetailsView
                ZStack {
                    ScrollView {
                        Text(dataContent)
                            .fixedSize(horizontal: false, vertical: false)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxHeight: 150)

                    VStack {
                        // Gradient at the top
                        LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0)]), startPoint: .top, endPoint: .bottom)
                                        .frame(height: 15)
                        Spacer()
                        // Gradient at the bottom
                        LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0), Color.gray.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                            .frame(height: 15)
                    }
                    .frame(maxHeight: 150)
                }

                Divider().background(Color.white)
                Spacer()
                ScrollView {
                    VStack {
                        #if os(iOS)
                        NavigationLink(destination: AssuranceView()) {
                            Text("Connect Assurance")
                        }
                        #endif
                        edgeView.background(secondaryBackgroundColor)
                        Divider().background(dividerColor)
                        consentSection
                        Divider().background(dividerColor)
                        edgeIdentitySection.background(secondaryBackgroundColor)
                        Divider().background(dividerColor)
                        coreView
                        Divider().background(dividerColor)
                        identityDirectView.background(secondaryBackgroundColor)
                    }
                }
            }
        }
    }

    var edgeDetailsView: some View {
        Text("Edge Extension Version: \(version)")
            .onAppear(perform: getExtensionVersion)
            .frame(maxWidth: .infinity)
            .padding()
    }

    var edgeView: some View {
        VStack {
            Text("Edge").frame(maxWidth: .infinity, alignment: .leading).padding(10).font(.system(size: 20))
            VStack {
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
                }).padding()

                HStack {
                    Button("Get Location Hint", action: {
                        Edge.getLocationHint({ hint, error in
                            if error != nil {
                                dataContent = "Received error '\((error as? AEPError)?.localizedDescription ?? "nil")"
                            } else {
                                dataContent = "Location hint: '\(hint ?? "nil")'"
                                selectedRegion = RegionId(rawValue: hint ?? "nil") ?? .nil_value
                            }
                        })
                    }).padding()

                    Text("Set Location Hint:")
                    Picker("Set Location Hint", selection: $selectedRegion.onChange(changeLocationHint)) {
                        ForEach(RegionId.allCases) { regionId in
                            Text(regionId.rawValue.capitalized)
                        }
                    }
                }

                Button("Dispach Event & Send Complete", action: {
                    let event = Event(
                        name: "Edge Event Send Completion Request",
                        type: EventType.edge,
                        source: EventSource.requestContent,
                        data: ["xdm": ["testString": "xdm"], "request": [ "sendCompletion": true ]])

                    MobileCore.dispatch(event: event) { responseEvent in
                        guard let responseEvent = responseEvent else {
                            DispatchQueue.main.async {
                                self.dataContent = "Dispatch Event Failed"
                            }
                            return
                        }

                        DispatchQueue.main.async {
                            self.dataContent = "Completion Event received: \(String(describing: responseEvent.data))"
                        }
                    }
                }).padding()
            }
        }
    }

    var consentSection: some View {
        VStack {
            Text("Collect Consent").frame(maxWidth: .infinity, alignment: .leading).padding(10).font(.system(size: 20))
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
        }
    }

    var edgeIdentitySection: some View {
        VStack {
            Text("Edge Identity").frame(maxWidth: .infinity, alignment: .leading).padding(10).font(.system(size: 20))
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
        }
    }

    var coreView: some View {
        VStack {
            Text("Mobile Core").frame(maxWidth: .infinity, alignment: .leading).padding(10).font(.system(size: 20))
            HStack {
                Button("Reset IDs", action: {
                    MobileCore.resetIdentities()
                }).padding()

            }
        }
    }

    var identityDirectView: some View {
        VStack {
            Text("ECID:").bold().frame(maxWidth: .infinity, alignment: .leading).padding(10)
            Text(ecid)
        }
        .onAppear {
            self.getECID()
        }
    }

    private func getExtensionVersion() {
        version = Edge.extensionVersion
    }

    /// Set the Edge Network location hint based on the 'selectedRegion' state variable.
    /// - Parameter tag: the region id
    private func changeLocationHint(_ tag: RegionId) {
        var hint: String?
        switch selectedRegion {
        case .nil_value:
            hint = nil
        case .empty_value:
            hint = ""
        default:
            hint = selectedRegion.rawValue
        }

        Edge.setLocationHint(hint)
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

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().preferredColorScheme(ColorScheme.dark)
    }
}

/// Location hint region ids
enum RegionId: String, CaseIterable, Identifiable {
    case or2, va6, irl1, ind1, jpn3, sgp3, aus3, nil_value = "nil", empty_value = "empty", invalid
    var id: Self { self }
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

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

import ACPCore

public class ACPExperiencePlatform {
    @available(*, unavailable) private init() {}
    
    public static func registerExtension() {
        // TODO: implement me
        ACPCore.log(ACPMobileLogLevel.debug, tag: "ACPExperiencePlatform", message: "registerExtension")
        _ = try? ACPCore.registerExtension(ExperiencePlatformInternal.self)
    }
    
    public static func extensionVersion() -> String {
        // TODO: implement me
        return "1.0.0-alpha"
    }
}

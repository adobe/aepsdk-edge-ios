Pod::Spec.new do |s|
  s.name             = "AEPExperiencePlatform"
  s.version          = "1.0.0-alpha-2"
  s.summary          = "Experience Platform extension for Adobe Experience Platform SDK. Written and maintained by Adobe."

  s.description      = <<-DESC
                       The Experience Platform extension enables sending data to the Adobe Experience Platform from a mobile device using the v5 Adobe Experience Platform SDK.
                       DESC

  s.homepage         = "https://github.com/adobe/aepsdk-platform-ios.git"
  s.license          = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author           = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/adobe/aepsdk-platform-ios.git", :tag => "v#{s.version}-#{s.name}" }
  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  s.dependency 'AEPCore'
  s.dependency 'AEPServices'
  
  s.source_files = 'code/src/**/*.swift'
end

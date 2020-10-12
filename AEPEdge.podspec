Pod::Spec.new do |s|
  s.name             = "AEPEdge"
  s.version          = "1.0.0-alpha-2"
  s.summary          = "Experience Edge extension for Adobe Experience Edge SDK. Written and maintained by Adobe."

  s.description      = <<-DESC
                       The Experience Edge extension enables sending data to the Adobe Experience Edge from a mobile device using the v5 Adobe Experience Edge SDK.
                       DESC

  s.homepage         = "https://github.com/adobe/aepsdk-platform-ios.git"
  s.license          = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author           = "Adobe Experience Edge SDK Team"
  s.source           = { :git => "https://github.com/adobe/aepsdk-platform-ios.git", :tag => "v#{s.version}-#{s.name}" }
  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  s.dependency 'AEPCore'
  s.dependency 'AEPServices'

  s.source_files = 'Sources/**/*.swift'
end

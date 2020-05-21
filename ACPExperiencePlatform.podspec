#
# Be sure to run `pod lib lint ACPExperiencePlatform.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "ACPExperiencePlatform"
  s.version          = "1.0.0-alpha"
  s.summary          = "Experience Platform extension for Adobe Experience Cloud SDK. Written and maintained by Adobe."

  s.description      = <<-DESC
                       The Experience Platform extension enables sending data to the Adobe Experience Platform from a mobile device using the v5 Adobe Experience Cloud SDK.
                       DESC

  s.homepage         = "https://github.com/adobe/platform-extension-ios.git"
  s.license          = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author           = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/adobe/platform-extension-ios.git", :tag => "v#{s.version}-#{s.name}" }
  s.platform = :ios, "10.0"
  s.requires_arc = true
  s.static_framework = true
  
  s.dependency "ACPCore", ">=2.6.1"

  s.default_subspec = "iOS"
  
  s.subspec "iOS" do |ios|
      ios.source_files = "code/src/**/*.swift"
  end
  
end

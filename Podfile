# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPEdge'
project 'AEPEdge.xcodeproj'

target 'AEPEdge' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.0.1'
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.0.1'
  pod 'AEPRulesEngine'
end

target 'UnitTests' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.0.1'
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.0.1'
  pod 'AEPRulesEngine'
end

target 'FunctionalTests' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.0.1'
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.0.1'
  pod 'AEPRulesEngine'
  pod 'AEPIdentity'
end

target 'AEPDemoAppSwiftUI' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.0.1'
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.0.1'
  pod 'AEPRulesEngine'
  pod 'AEPLifecycle'
  pod 'AEPIdentity'
  pod 'AEPSignal'
  pod 'AEPConsent', :git => 'https://github.com/adobe/aepsdk-consentedge-ios.git', :branch => 'dev'
  pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
  pod 'AEPAssurance'
end

target 'AEPCommerceDemoApp' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.0.1'
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.0.1'
  pod 'AEPRulesEngine'
  pod 'AEPLifecycle'
  pod 'AEPIdentity'
  pod 'AEPSignal'
  pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
  pod 'AEPAssurance'
end

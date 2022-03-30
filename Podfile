# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPEdge'
project 'AEPEdge.xcodeproj'

pod 'SwiftLint', '0.44.0'

target 'AEPEdge' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios', :branch => 'staging'
end

target 'UnitTests' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios', :branch => 'staging'
end

target 'FunctionalTests' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios', :branch => 'staging'
  pod 'AEPEdgeIdentity'
  pod 'AEPEdgeConsent'
end

target 'AEPDemoAppSwiftUI' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios', :branch => 'staging'
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios', :branch => 'staging'
  pod 'AEPLifecycle', :git => 'https://github.com/adobe/aepsdk-core-ios', :branch => 'staging'
  pod 'AEPIdentity', :git => 'https://github.com/adobe/aepsdk-core-ios', :branch => 'staging'
  pod 'AEPSignal', :git => 'https://github.com/adobe/aepsdk-core-ios', :branch => 'staging'
  pod 'AEPEdgeIdentity'
  pod 'AEPEdgeConsent'
  pod 'AEPAssurance'
end

target 'AEPCommerceDemoApp' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios', :branch => 'staging'
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios', :branch => 'staging'
  pod 'AEPLifecycle', :git => 'https://github.com/adobe/aepsdk-core-ios', :branch => 'staging'
  pod 'AEPIdentity', :git => 'https://github.com/adobe/aepsdk-core-ios', :branch => 'staging'
  pod 'AEPSignal', :git => 'https://github.com/adobe/aepsdk-core-ios', :branch => 'staging'
  pod 'AEPEdgeIdentity'
  pod 'AEPAssurance'
end

# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPEdge'
project 'AEPEdge.xcodeproj'

target 'AEPEdge' do
  pod 'AEPCore'
end

target 'UnitTests' do
  pod 'AEPCore'
end

target 'FunctionalTests' do
  pod 'AEPCore'
  pod 'AEPEdgeIdentity'
  pod 'AEPEdgeConsent'
end

target 'AEPDemoAppSwiftUI' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPLifecycle'
  pod 'AEPIdentity'
  pod 'AEPSignal'
  pod 'AEPEdgeIdentity'
  pod 'AEPEdgeConsent'
  pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
  pod 'AEPAssurance'
end

target 'AEPCommerceDemoApp' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPLifecycle'
  pod 'AEPIdentity'
  pod 'AEPSignal'
  pod 'AEPEdgeIdentity'
  pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
  pod 'AEPAssurance'
end

# source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPEdge'
project 'AEPEdge.xcodeproj'

target 'AEPEdge' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPRulesEngine'
end

target 'UnitTests' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPRulesEngine'
end

target 'FunctionalTests' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPRulesEngine'
  pod 'AEPIdentity'
end

target 'AEPDemoAppSwiftUI' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPRulesEngine'
  pod 'AEPLifecycle'
  pod 'AEPIdentity'
  pod 'AEPSignal'
  pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
  pod 'AEPAssurance'
end

target 'AEPCommerceDemoApp' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPRulesEngine'
  pod 'AEPLifecycle'
  pod 'AEPIdentity'
  pod 'AEPSignal'
  pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
  pod 'AEPAssurance'
end

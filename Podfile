# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPEdge'
project 'AEPEdge.xcodeproj'

pod 'SwiftLint', '0.44.0'

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
  pod 'AEPEdgeIdentity'
  pod 'AEPEdgeConsent'
  pod 'AEPAssurance'
end

target 'AEPCommerceDemoApp' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPEdgeIdentity'
  pod 'AEPAssurance'
end

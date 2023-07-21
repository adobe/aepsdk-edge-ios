# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPEdge'
project 'AEPEdge.xcodeproj'

pod 'SwiftLint', '0.52.0'

target 'AEPEdge' do
  pod 'AEPCore'
end

target 'UnitTests' do
  pod 'AEPCore'
end

target 'UpstreamIntegrationTests' do
  pod 'AEPCore'
  pod 'AEPEdgeIdentity'
  pod 'AEPEdgeConsent'
  pod 'AEPEdge', :path => './AEPEdge.podspec'
end

target 'FunctionalTests' do
  pod 'AEPCore'
  pod 'AEPEdgeIdentity'
  pod 'AEPEdgeConsent'
  pod 'AEPEdge', :path => './AEPEdge.podspec'
end

target 'TestAppiOS' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPEdgeIdentity'
  pod 'AEPEdgeConsent'
  pod 'AEPEdge', :path => './AEPEdge.podspec'
  pod 'AEPAssurance'
end

target 'TestApptvOS' do
  pod 'AEPCore'
  pod 'AEPServices'
  pod 'AEPEdgeIdentity'
  pod 'AEPEdgeConsent'
  pod 'AEPEdge', :path => './AEPEdge.podspec'
end

post_install do |pi|
  pi.pods_project.targets.each do |t|
    t.build_configurations.each do |bc|
        bc.build_settings['TVOS_DEPLOYMENT_TARGET'] = '11.0'
        bc.build_settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator appletvos appletvsimulator'
        bc.build_settings['TARGETED_DEVICE_FAMILY'] = "1,2,3"
    end
  end
end

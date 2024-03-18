# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPEdge'
project 'AEPEdge.xcodeproj'

pod 'SwiftLint', '0.52.0'

def core_pods
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'staging'
  pod 'AEPRulesEngine', :git => 'https://github.com/adobe/aepsdk-rulesengine-ios.git', :branch => 'staging'
end

def edge_pods
    pod 'AEPEdgeIdentity', :git => 'https://github.com/adobe/aepsdk-edgeidentity-ios.git', :branch => 'staging-cs'
    pod 'AEPEdgeConsent', :git => 'https://github.com/adobe/aepsdk-edgeconsent-ios.git', :branch => 'staging'
    pod 'AEPEdge', :path => './AEPEdge.podspec'
end

target 'AEPEdge' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'staging'
end

target 'UnitTests' do
  core_pods
  pod 'AEPTestUtils', :git => 'https://github.com/adobe/aepsdk-testutils-ios.git', :tag => 'v5.0.0-beta'
end

target 'UpstreamIntegrationTests' do
  core_pods
  edge_pods
  pod 'AEPTestUtils', :git => 'https://github.com/adobe/aepsdk-testutils-ios.git', :tag => 'v5.0.0-beta'
end

target 'FunctionalTests' do
  core_pods
  edge_pods
  pod 'AEPTestUtils', :git => 'https://github.com/adobe/aepsdk-testutils-ios.git', :tag => 'v5.0.0-beta'
end

target 'TestAppiOS' do
  core_pods
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'staging'
  edge_pods
  pod 'AEPAssurance'
end

target 'TestApptvOS' do
  core_pods
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'staging'
  edge_pods
end

post_install do |pi|
  pi.pods_project.targets.each do |t|
    t.build_configurations.each do |bc|
        bc.build_settings['TVOS_DEPLOYMENT_TARGET'] = '12.0'
        bc.build_settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator appletvos appletvsimulator'
        bc.build_settings['TARGETED_DEVICE_FAMILY'] = "1,2,3"
    end
  end
end

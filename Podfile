# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPEdge'
project 'AEPEdge.xcodeproj'

pod 'SwiftLint', '0.44.0'

target 'AEPEdge' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.7.1'
end

target 'UnitTests' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.7.1'
end

target 'FunctionalTests' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.7.1'
  pod 'AEPEdgeIdentity', :git => 'https://github.com/adobe/aepsdk-edgeidentity-ios.git', :branch => 'feature/tvos'
  pod 'AEPEdgeConsent', :git => 'https://github.com/adobe/aepsdk-edgeconsent-ios.git', :branch => 'feature/tvos'
end

target 'TestAppiOS' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.7.1'
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.7.1'
  pod 'AEPEdgeIdentity', :git => 'https://github.com/adobe/aepsdk-edgeidentity-ios.git', :branch => 'feature/tvos'
  pod 'AEPEdgeConsent', :git => 'https://github.com/adobe/aepsdk-edgeconsent-ios.git', :branch => 'feature/tvos'
  pod 'AEPAssurance'
end

target 'TestApptvOS' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.7.1'
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'dev-v3.7.1'
  pod 'AEPEdgeIdentity', :git => 'https://github.com/adobe/aepsdk-edgeidentity-ios.git', :branch => 'feature/tvos'
  pod 'AEPEdgeConsent', :git => 'https://github.com/adobe/aepsdk-edgeconsent-ios.git', :branch => 'feature/tvos'
end

post_install do |pi|
  pi.pods_project.targets.each do |t|
    t.build_configurations.each do |bc|
        bc.build_settings['TVOS_DEPLOYMENT_TARGET'] = '10.0'
        bc.build_settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator appletvos appletvsimulator'
        bc.build_settings['TARGETED_DEVICE_FAMILY'] = "1,2,3"
    end
  end
end

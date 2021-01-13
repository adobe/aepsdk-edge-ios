# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPEdge'
project 'AEPEdge.xcodeproj'

target 'AEPEdge' do
  pod 'AEPCore', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'AEPServices', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'AEPRulesEngine', :git => 'git@github.com:adobe/aepsdk-rulesengine-ios.git', :tag => 'dev'
end

target 'UnitTests' do
  pod 'AEPCore', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'AEPServices', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'AEPRulesEngine', :git => 'git@github.com:adobe/aepsdk-rulesengine-ios.git', :tag => 'dev'
end

target 'FunctionalTests' do
  pod 'AEPCore', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'AEPServices', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'AEPRulesEngine', :git => 'git@github.com:adobe/aepsdk-rulesengine-ios.git', :tag => 'dev'
  pod 'AEPIdentity', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
end

target 'AEPDemoAppSwiftUI' do
  pod 'AEPCore', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'AEPServices', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'AEPRulesEngine', :git => 'git@github.com:adobe/aepsdk-rulesengine-ios.git', :tag => 'dev'
  pod 'AEPLifecycle', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'AEPIdentity', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'AEPSignal', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
  pod 'AEPAssurance'
end

target 'AEPCommerceDemoApp' do
  pod 'AEPCore', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'AEPServices', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'AEPRulesEngine', :git => 'git@github.com:adobe/aepsdk-rulesengine-ios.git', :tag => 'dev'
  pod 'AEPLifecycle', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'AEPIdentity', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'AEPSignal', :git => 'git@github.com:adobe/aepsdk-core-ios.git', :branch => 'dev'
  pod 'ACPCore', :git => 'https://github.com/adobe/aep-sdk-compatibility-ios.git', :branch => 'main'
  pod 'AEPAssurance'
end

platform :ios, '9.0'

workspace 'PayPalCommercePlatform.xcworkspace'
inhibit_all_warnings!

target 'Demo' do
  pod 'PayPalCommercePlatform', :path => './'
  pod 'Braintree', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'InAppSettingsKit'
end

abstract_target 'Tests' do
  pod 'PayPalCommercePlatform', :path => './'
  pod 'Braintree', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'

  target 'UnitTests'
  target 'IntegrationTests'
end

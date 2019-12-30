platform :ios, '9.0'

workspace 'PayPalCommerce.xcworkspace'
use_frameworks!

target 'Demo' do
  pod 'PayPalCommerce', :path => './'
  pod 'Braintree', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/Core', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/Card', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/Apple-Pay', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/PaymentFlow', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'InAppSettingsKit'
end

abstract_target 'Tests' do
  pod 'PayPalCommerce', :path => './'
  pod 'Braintree', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/Core', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/Card', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/Apple-Pay', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/PaymentFlow', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'

  target 'UnitTests'
  target 'IntegrationTests'
end

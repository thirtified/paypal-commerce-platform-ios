platform :ios, '9.0'

workspace 'BraintreePayPalValidator.xcworkspace'
use_frameworks!

target 'Demo' do
  pod 'BraintreePayPalValidator', :path => './'
  pod 'Braintree', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/PayPal', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/Core', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/Card', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/Apple-Pay', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/PaymentFlow', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
end

abstract_target 'Tests' do
  pod 'BraintreePayPalValidator', :path => './'
  pod 'Braintree', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/PayPal', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/Core', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/Card', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/Apple-Pay', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'
  pod 'Braintree/PaymentFlow', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-uat-support'

  target 'UnitTests'
end
@import Braintree.BraintreePaymentFlow;

NS_ASSUME_NONNULL_BEGIN

@interface PPCPayPalCheckoutRequest : BTPaymentFlowRequest <BTPaymentFlowRequestDelegate>

@property (copy, nonatomic) NSURL *checkoutURL;

@end

NS_ASSUME_NONNULL_END

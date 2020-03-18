@import Braintree.BraintreePaymentFlow;
@import Braintree.BraintreeCore;

NS_ASSUME_NONNULL_BEGIN

@interface PPCPayPalCheckoutResult : BTPaymentFlowResult

@property (copy, nonatomic) NSString *payerID;
@property (copy, nonatomic) NSString *token;

- (instancetype)initWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END

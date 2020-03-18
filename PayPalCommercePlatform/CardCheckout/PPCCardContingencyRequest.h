@import Braintree.BraintreePaymentFlow;

NS_ASSUME_NONNULL_BEGIN

@interface PPCCardContingencyRequest : BTPaymentFlowRequest <BTPaymentFlowRequestDelegate>

@property (readonly, nonatomic) NSURL *contingencyURL;

- (instancetype)initWithContingencyURL:(NSURL *)contingencyURL;

@end

NS_ASSUME_NONNULL_END

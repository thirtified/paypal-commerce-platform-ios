@import Braintree.BraintreePaymentFlow;
@import Braintree.BraintreeCore;

NS_ASSUME_NONNULL_BEGIN

@interface PPCCardContingencyResult : BTPaymentFlowResult

@property (copy, nonatomic) NSString *state;
@property (copy, nonatomic) NSString *code;
@property (copy, nonatomic, nullable) NSString *error;
@property (copy, nonatomic, nullable) NSString *errorDescription;

- (instancetype)initWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END

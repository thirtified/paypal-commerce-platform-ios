#if __has_include("BraintreePaymentFlow.h")
#import "BraintreePaymentFlow.h"
#else
#import <BraintreePaymentFlow/BraintreePaymentFlow.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BTPayPalCardContingencyRequest : BTPaymentFlowRequest <BTPaymentFlowRequestDelegate>

@property (readonly, nonatomic) NSURL *contigencyURL;

- (instancetype)initWithContigencyURL:(NSURL *)contigencyURL;

@end

NS_ASSUME_NONNULL_END

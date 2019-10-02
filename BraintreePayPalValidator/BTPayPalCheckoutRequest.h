#if __has_include("BraintreePaymentFlow.h")
#import "BraintreePaymentFlow.h"
#else
#import <BraintreePaymentFlow/BraintreePaymentFlow.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BTPayPalCheckoutRequest : BTPaymentFlowRequest <BTPaymentFlowRequestDelegate>

@property (copy, nonatomic) NSURL *checkoutURL;

@end

NS_ASSUME_NONNULL_END

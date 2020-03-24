@import PassKit;
@import Braintree.BraintreeCard;
@import Braintree.BraintreeApplePay;
@import Braintree.BraintreePaymentFlow;
@import Braintree.PayPalDataCollector;

#import "PPCValidatorResult.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const PPCValidatorErrorDomain;

@interface PPCValidatorClient : NSObject

typedef void (^BTApplePayResultHandler)(BOOL success);

@property (nonatomic, weak) id<BTViewControllerPresentingDelegate> presentingDelegate;

- (nullable instancetype)initWithAccessToken:(NSString *)accessToken;

// TODO: - check Swift names for these methods
- (void)checkoutWithCard:(NSString *)orderId
                    card:(BTCard *)card
              completion:(void (^)(PPCValidatorResult * _Nullable result, NSError * _Nullable error))completion NS_SWIFT_NAME(checkoutWithCard(orderID:card:completion:));

- (void)checkoutWithPayPal:(NSString *)orderId
                completion:(void (^)(PPCValidatorResult * _Nullable result, NSError * _Nullable error))completion NS_SWIFT_NAME(checkoutWithPayPal(orderID:completion:));

- (void)checkoutWithApplePay:(NSString *)orderId
              paymentRequest:(PKPaymentRequest *)paymentRequest
                  completion:(void (^)(PPCValidatorResult * _Nullable result, NSError * _Nullable error, _Nullable BTApplePayResultHandler resultHandler))completion NS_SWIFT_NAME(checkoutWithApplePay(orderID:paymentRequest:completion:));

@end

NS_ASSUME_NONNULL_END

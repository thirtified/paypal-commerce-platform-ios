#import <PassKit/PassKit.h>

#if __has_include(<Braintree/BraintreeCard.h>)
#import <Braintree/BraintreeCard.h>
#endif

#if __has_include("BraintreeApplePay.h")
#import "BraintreeApplePay.h"
#else
#import <BraintreeApplePay/BraintreeApplePay.h>
#endif

#if __has_include("BraintreePaymentFlow.h")
#import "BraintreePaymentFlow.h"
#else
#import <BraintreePaymentFlow/BraintreePaymentFlow.h>
#endif

#import "BTPayPalValidatorResult.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const BTPayPalValidatorErrorDomain;

@interface BTPayPalValidatorClient : NSObject

typedef void (^BTApplePayResultHandler)(BOOL success);

- (instancetype)initWithAccessToken:(NSString *)accessToken;

- (void)checkoutWithCard:(NSString *)orderId
                    card:(BTCard *)card
      presentingDelegate:(id<BTViewControllerPresentingDelegate>)viewControllerPresentingDelegate
              completion:(void (^)(BTPayPalValidatorResult * _Nullable validateResult, NSError * _Nullable error))completion NS_SWIFT_NAME(checkoutWithCard(_:card:presentingDelegate:completion:));

- (void)checkoutWithPayPal:(NSString *)orderId
        presentingDelegate:(id<BTViewControllerPresentingDelegate>)viewControllerPresentingDelegate
                completion:(void (^)(BTPayPalValidatorResult * _Nullable validateResult, NSError * _Nullable error))completion NS_SWIFT_NAME(checkoutWithPayPal(_:presentingDelegate:completion:));

- (void)checkoutWithApplePay:(NSString *)orderId
              paymentRequest:(PKPaymentRequest *)paymentRequest
          presentingDelegate:(id<BTViewControllerPresentingDelegate>)viewControllerPresentingDelegate
                  completion:(void (^)(BTPayPalValidatorResult * _Nullable tokenizedApplePayPayment, NSError * _Nullable error, BTApplePayResultHandler resultHandler))completion NS_SWIFT_NAME(checkoutWithApplePay(_:paymentRequest:presentingDelegate:completion:));

@end

NS_ASSUME_NONNULL_END

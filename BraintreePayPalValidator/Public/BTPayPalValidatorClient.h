#import <PassKit/PassKit.h>

//TODO: What is the proper import syntax here?

//#if __has_include(<Braintree/BraintreeCard.h>)
#import <Braintree/BraintreeCard.h>
//#endif

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

#import "BTPayPalValidateResult.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const BTPayPalValidatorErrorDomain;

@interface BTPayPalValidatorClient : NSObject

typedef void (^BTAppleyPayResultHandler)(BOOL success);

- (instancetype)initWithAccessToken:(NSString *)accessToken
                            orderId:(NSString *)orderId;

- (void)checkoutWithCard:(BTCard *)card
      presentingDelegate:(id<BTViewControllerPresentingDelegate>)viewControllerPresentingDelegate
              completion:(void (^)(BTCardNonce * _Nullable tokenizedCard, NSError * _Nullable error))completion NS_SWIFT_NAME(checkoutWithCard(_:presentingDelegate:completion:));

- (void)checkoutWithPayPalPresentingDelegate:(id<BTViewControllerPresentingDelegate>)viewControllerPresentingDelegate
                                  completion:(void (^)(NSError * _Nullable error))completion NS_SWIFT_NAME(checkoutWithPayPal(presentingDelegate:completion:));

- (void)checkoutWithApplePay:(PKPaymentRequest *)paymentRequest
          presentingDelegate:(id<BTViewControllerPresentingDelegate>)viewControllerPresentingDelegate
                  completion:(void (^)(BTApplePayCardNonce * _Nullable tokenizedApplePayPayment, NSError * _Nullable error, BTAppleyPayResultHandler resultHandler))completion NS_SWIFT_NAME(checkoutWithApplePay(_:presentingDelegate:completion:));

@end

NS_ASSUME_NONNULL_END

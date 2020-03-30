#import "BTAPIClient+Analytics_Internal.h"
#import "PPCValidatorClient_Internal.h"
#import "PPCCardContingencyRequest.h"
#import "PPCPayPalCheckoutRequest.h"
#import "PPCValidatorResult.h"

NSString * const PPCValidatorErrorDomain = @"com.braintreepayments.PPCValidatorErrorDomain";

@interface PPCValidatorClient() <PKPaymentAuthorizationViewControllerDelegate>

@property (nonatomic, copy) NSString *orderId;
@property (nonatomic, copy) void (^applePayCompletionBlock)(PPCValidatorResult * _Nullable validatorResult, NSError * _Nullable, BTApplePayResultHandler successHandler);

@end

@implementation PPCValidatorClient

#pragma mark - Properties

// For testing
static Class PayPalDataCollectorClass;
static NSString *PayPalDataCollectorClassString = @"PPDataCollector";

#pragma mark - Initialization

- (void)setOrderId:(NSString *)orderId {
    _orderId = orderId;
    [PayPalDataCollectorClass clientMetadataID:_orderId];
}

- (nullable instancetype)initWithAccessToken:(NSString *)accessToken {
    self = [super init];
    if (self) {
        // NSString *tokenizationKey = @"sandbox_fwvdxncw_rwwnkqg2xg56hm2n";

        _braintreeAPIClient = [[BTAPIClient alloc] initWithAuthorization:accessToken];
        if (!_braintreeAPIClient) {
            return nil;
        }
        _applePayClient = [[BTApplePayClient alloc] initWithAPIClient:_braintreeAPIClient];
        _cardClient = [[BTCardClient alloc] initWithAPIClient:_braintreeAPIClient];
        _paymentFlowDriver = [[BTPaymentFlowDriver alloc] initWithAPIClient:_braintreeAPIClient];
        _payPalAPIClient = [[PPCAPIClient alloc] initWithAccessToken:accessToken];
    }

    return self;
}

#pragma mark - Checkout with Card

- (void)checkoutWithCard:(NSString *)orderID
                    card:(BTCard *)card
              completion:(void (^)(PPCValidatorResult * _Nullable validationResult, NSError * _Nullable error))completion {
    self.orderId = orderID;
    [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.card-checkout.started"];

    [self.cardClient tokenizeCard:card completion:^(BTCardNonce * tokenizedCard, NSError *error) {
        if (tokenizedCard) {
            [self validateTokenizedCard:tokenizedCard completion:^(BOOL success, NSError *error) {
                if (success) {
                    PPCValidatorResult *validatorResult = [PPCValidatorResult new];
                    validatorResult.orderID = self.orderId;
                    validatorResult.type = PPCValidatorResultTypeCard;

                    [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.card-checkout.succeeded"];
                    completion(validatorResult, nil);
                } else {
                    [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.card-checkout.failed"];
                    completion(nil, error);
                }
            }];
        } else {
            [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.card-checkout.failed"];
            completion(nil, error);
        }
    }];
}

- (void)validateTokenizedCard:(BTCardNonce *)tokenizedCard
                   completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    [self.payPalAPIClient validatePaymentMethod:tokenizedCard
                                     forOrderId:self.orderId
                                        with3DS:YES
                                     completion:^(PPCValidationResult *result, NSError __unused *error) {
                                            if (error) {
                                                completion(NO, error);
                                            } else if (result.contingencyURL) {
                                                PPCCardContingencyRequest *contingencyRequest = [[PPCCardContingencyRequest alloc] initWithContingencyURL:result.contingencyURL];
                                                [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.card-contingency.started"];

                                                self.paymentFlowDriver.viewControllerPresentingDelegate = self.presentingDelegate;
                                                [self.paymentFlowDriver startPaymentFlow:contingencyRequest completion:^(BTPaymentFlowResult *result, NSError *error) {
                                                    if (result) {
                                                        [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.card-contingency.succeeded"];
                                                        completion(YES, nil);
                                                    } else {
                                                        [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.card-contingency.failed"];
                                                        completion(NO, error);
                                                    }
                                                }];
                                            } else {
                                                [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.card-contingency.no-challenge"];
                                                completion(YES, nil);
                                            }
    }];
}

#pragma mark - Checkout with PayPal

- (void)checkoutWithPayPal:(NSString *)orderId
                completion:(void (^)(PPCValidatorResult * _Nullable validationResult, NSError * _Nullable error))completion {
    self.orderId = orderId;
    [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.paypal-checkout.started"];

    // TODO: Use hardcode URL (https://api.paypal.com/checkoutnow?token=) with orderId to complete PayPal flow until BT Config returns PwPP approve URL

    PPCPayPalCheckoutRequest *request = [PPCPayPalCheckoutRequest new];
    request.checkoutURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.ppcpn.stage.paypal.com/checkoutnow?token=%@", self.orderId]];

    self.paymentFlowDriver.viewControllerPresentingDelegate = self.presentingDelegate;
    [self.paymentFlowDriver startPaymentFlow:request completion:^(BTPaymentFlowResult * __unused result, NSError *error) {
        if (error) {
            [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.paypal-checkout.failed"];
            completion(nil, error);
            return;
        }
        PPCValidatorResult *validatorResult = [PPCValidatorResult new];
        validatorResult.orderID = self.orderId;
        validatorResult.type = PPCValidatorResultTypePayPal;

        [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.paypal-checkout.succeeded"];
        completion(validatorResult, nil);
    }];
}

#pragma mark - Checkout with ApplePay

- (void)checkoutWithApplePay:(NSString * __unused)orderId
              paymentRequest:(PKPaymentRequest *)paymentRequest
                  completion:(void (^)(PPCValidatorResult * _Nullable tokenizedApplePayPayment, NSError * _Nullable error, BTApplePayResultHandler resultHandler))completion {
    self.orderId = orderId;
    self.applePayCompletionBlock = completion;
    [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.apple-pay-checkout.started"];

    [self.applePayClient paymentRequest:^(PKPaymentRequest *defaultPaymentRequest, NSError *error) {
        if (defaultPaymentRequest) {
            paymentRequest.countryCode = defaultPaymentRequest.countryCode;
            paymentRequest.currencyCode = defaultPaymentRequest.currencyCode;
            paymentRequest.merchantIdentifier = defaultPaymentRequest.merchantIdentifier;

            // TODO: - revert change after E2E
            // Disabling Discover and Amex support for MVP. PayPal processor interaction is not coded for those 2 card networks.
            // paymentRequest.supportedNetworks = defaultPaymentRequest.supportedNetworks;
            NSMutableArray <PKPaymentNetwork> *supportedNetworks = [NSMutableArray new];
            for (PKPaymentNetwork network in defaultPaymentRequest.supportedNetworks) {
                if (![network isEqualToString:@"Discover"] && ![network isEqualToString:@"AmEx"]) {
                    [supportedNetworks addObject:network];
                }
            }
            paymentRequest.supportedNetworks = supportedNetworks;

            PKPaymentAuthorizationViewController *authorizationViewController = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];

            if (!authorizationViewController) {
                [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.apple-pay-sheet.failed"];
                NSError *error = [[NSError alloc] initWithDomain:PPCValidatorErrorDomain
                                                            code:0
                                                        userInfo:@{NSLocalizedDescriptionKey: @"Apple Pay authorizationViewController failed to initialize"}];
                self.applePayCompletionBlock(nil, error, nil);
                return;
            }

            authorizationViewController.delegate = self;
            [self.presentingDelegate paymentDriver:self requestsPresentationOfViewController:authorizationViewController];
        } else {
            [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.apple-pay-payment-request.failed"];
            self.applePayCompletionBlock(nil, error, nil);
        }
    }];
}

- (void)tokenizeAndValidateApplePayPayment:(PKPayment *)payment completion:(void (^)(PPCValidatorResult * _Nullable result, NSError * _Nullable error))completion {
    [self.applePayClient tokenizeApplePayPayment:payment completion:^(BTApplePayCardNonce *tokenizedApplePayPayment, NSError *error) {
        if (!tokenizedApplePayPayment || error) {
            [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.apple-pay-checkout.failed"];
            completion(nil, error);
            return;
        }

        [self.payPalAPIClient validatePaymentMethod:tokenizedApplePayPayment
                                         forOrderId:self.orderId
                                            with3DS:NO
                                         completion:^(PPCValidationResult * __unused result, NSError *error) {
            if (!result || error) {
                [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.apple-pay-checkout.failed"];
                completion(nil, error);
                return;
            }

            PPCValidatorResult *validatorResult = [PPCValidatorResult new];
            validatorResult.orderID = self.orderId;
            validatorResult.type = PPCValidatorResultTypeApplePay;

            [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.apple-pay-checkout.succeeded"];
            completion(validatorResult, error);
        }];
    }];
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate

- (void)paymentAuthorizationViewControllerDidFinish:(nonnull PKPaymentAuthorizationViewController *)controller {
    [self.presentingDelegate paymentDriver:self requestsDismissalOfViewController:controller];
}

// iOS 11+ delegate method
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController * __unused)controller
                       didAuthorizePayment:(PKPayment *)payment
                                   handler:(void (^)(PKPaymentAuthorizationResult * _Nonnull))completion API_AVAILABLE(ios(11.0)) {
    [self tokenizeAndValidateApplePayPayment:payment completion:^(PPCValidatorResult *result, NSError *error) {
        self.applePayCompletionBlock(result, error, ^(BOOL success) {
            if (success) {
                [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.apple-pay-result-handler.true"];
                completion([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusSuccess errors:nil]);
            } else {
                [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.apple-pay-result-handler.false"];
                completion([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusFailure errors:nil]);
            }
        });
    }];
}

// pre-iOS 11 delegate method
- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus status))completion {
    [self tokenizeAndValidateApplePayPayment:payment completion:^(PPCValidatorResult *result, NSError *error) {
        self.applePayCompletionBlock(result, error, ^(BOOL success) {
            if (success) {
                [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.apple-pay-result-handler.true"];
                completion(PKPaymentAuthorizationStatusSuccess);
            } else {
                [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.apple-pay-result-handler.false"];
                completion(PKPaymentAuthorizationStatusFailure);
            }
        });
    }];
}

#pragma mark - Test Helpers

+ (void)setPayPalDataCollectorClass:(Class)payPalDataCollectorClass {
    PayPalDataCollectorClass = payPalDataCollectorClass;
}

@end

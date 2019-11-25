#import "PPCValidatorClient_Internal.h"
#import "PPCCardContingencyRequest.h"
#import "PPCPayPalCheckoutRequest.h"
#import "PPCValidatorResult.h"

NSString * const PPCValidatorErrorDomain = @"com.braintreepayments.PPCValidatorErrorDomain";

@interface PPCValidatorClient() <PKPaymentAuthorizationViewControllerDelegate>

@property (nonatomic, copy) NSString *orderId;
@property (nonatomic, copy) void (^applePayCompletionBlock)(PPCValidatorResult * _Nullable validatorResult, NSError * _Nullable, BTApplePayResultHandler successHandler);

@end

// TODO: - add delegate as a property instead of parameter to the checkout methods
@implementation PPCValidatorClient

- (nullable instancetype)initWithAccessToken:(NSString *)accessToken {
    self = [super init];
    if (self) {
        // NSString *tokenizationKey = @"sandbox_fwvdxncw_rwwnkqg2xg56hm2n";

        BTAPIClient *braintreeAPIClient = [[BTAPIClient alloc] initWithAuthorization:accessToken];
        if (!braintreeAPIClient) {
            return nil;
        }
        _applePayClient = [[BTApplePayClient alloc] initWithAPIClient:braintreeAPIClient];
        _cardClient = [[BTCardClient alloc] initWithAPIClient:braintreeAPIClient];
        _paymentFlowDriver = [[BTPaymentFlowDriver alloc] initWithAPIClient:braintreeAPIClient];
        _payPalAPIClient = [[PPCAPIClient alloc] initWithAccessToken:accessToken];
    }

    return self;
}

- (void)checkoutWithCard:(NSString *)orderID
                    card:(BTCard *)card
              completion:(void (^)(PPCValidatorResult * _Nullable validationResult, NSError * _Nullable error))completion {
    self.orderId = orderID;

    [self.cardClient tokenizeCard:card completion:^(BTCardNonce * tokenizedCard, NSError *error) {
        if (tokenizedCard) {
            [self validateTokenizedCard:tokenizedCard completion:^(BOOL success, NSError *error) {
                if (success) {
                    PPCValidatorResult *validatorResult = [PPCValidatorResult new];
                    validatorResult.orderID = self.orderId;
                    validatorResult.type = PPCValidatorResultTypeCard;
                    completion(validatorResult, nil);
                } else {
                    completion(nil, error);
                }
            }];
        } else {
            completion(nil, error);
        }
    }];
}

- (void)validateTokenizedCard:(BTCardNonce *)tokenizedCard
                   completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    [self.payPalAPIClient validatePaymentMethod:tokenizedCard
                                     forOrderId:self.orderId
                                     completion:^(PPCValidationResult *result, NSError __unused *error) {
                                            if (error) {
                                                completion(NO, error);
                                            } else if (result.contingencyURL) {
                                                PPCCardContingencyRequest *contingencyRequest = [[PPCCardContingencyRequest alloc] initWithContingencyURL:result.contingencyURL];

                                                self.paymentFlowDriver.viewControllerPresentingDelegate = self.presentingDelegate;
                                                [self.paymentFlowDriver startPaymentFlow:contingencyRequest completion:^(BTPaymentFlowResult *result, NSError *error) {
                                                    if (result) {
                                                        completion(YES, nil);
                                                    } else {
                                                        completion(NO, error);
                                                    }
                                                }];
                                            } else {
                                                // TODO: is this an accurate fallback?
                                                completion(YES, nil);
                                            }
    }];
}

- (void)checkoutWithPayPal:(NSString *)orderId
                completion:(void (^)(PPCValidatorResult * _Nullable validationResult, NSError * _Nullable error))completion {
    self.orderId = orderId;

    // TODO: Use hardcode URL (https://api.paypal.com/checkoutnow?token=) with orderId to complete PayPal flow until orders v2 accepts universal JWT

    PPCPayPalCheckoutRequest *request = [PPCPayPalCheckoutRequest new];
    request.checkoutURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.ppcpn.stage.paypal.com/checkoutnow?token=%@", self.orderId]];

    self.paymentFlowDriver.viewControllerPresentingDelegate = self.presentingDelegate;
    [self.paymentFlowDriver startPaymentFlow:request completion:^(BTPaymentFlowResult * __unused result, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        PPCValidatorResult *validatorResult = [PPCValidatorResult new];
        validatorResult.orderID = self.orderId;
        validatorResult.type = PPCValidatorResultTypePayPal;
        completion(validatorResult, nil);
    }];
}

- (void)checkoutWithApplePay:(NSString * __unused)orderId
              paymentRequest:(PKPaymentRequest *)paymentRequest
                  completion:(void (^)(PPCValidatorResult * _Nullable tokenizedApplePayPayment, NSError * _Nullable error, BTApplePayResultHandler resultHandler))completion NS_SWIFT_NAME(checkoutWithApplePay(_:paymentRequest:completion:)) {
    self.orderId = orderId;
    self.applePayCompletionBlock = completion;

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
            authorizationViewController.delegate = self;
            [self.presentingDelegate paymentDriver:self requestsPresentationOfViewController:authorizationViewController];
        } else {
            self.applePayCompletionBlock(nil, error, nil);
        }
    }];
}

- (void)tokenizeAndValidateApplePayPayment:(PKPayment *)payment completion:(void (^)(PPCValidatorResult * _Nullable result, NSError * _Nullable error))completion {
    [self.applePayClient tokenizeApplePayPayment:payment completion:^(BTApplePayCardNonce *tokenizedApplePayPayment, NSError *error) {
        if (!tokenizedApplePayPayment || error) {
            completion(nil, error);
            return;
        }

        [self.payPalAPIClient validatePaymentMethod:tokenizedApplePayPayment
                                         forOrderId:self.orderId
                                         completion:^(PPCValidationResult * __unused result, NSError *error) {
            if (!result || error) {
                completion(nil, error);
                return;
            }

            PPCValidatorResult *validatorResult = [PPCValidatorResult new];
            validatorResult.orderID = self.orderId;
            validatorResult.type = PPCValidatorResultTypeApplePay;
            completion(validatorResult, error);
        }];
    }];
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate

- (void)paymentAuthorizationViewControllerDidFinish:(nonnull PKPaymentAuthorizationViewController *)controller {
    [self.presentingDelegate paymentDriver:self requestsDismissalOfViewController:controller];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController * __unused)controller
                       didAuthorizePayment:(PKPayment *)payment
                                   handler:(void (^)(PKPaymentAuthorizationResult * _Nonnull))completion API_AVAILABLE(ios(11.0)) {
    [self tokenizeAndValidateApplePayPayment:payment completion:^(PPCValidatorResult *result, NSError *error) {
        self.applePayCompletionBlock(result, error, ^(BOOL success) {
            if (success) {
                completion([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusSuccess errors:nil]);
            } else {
                completion([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusFailure errors:nil]);
            }
        });
    }];
}

- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus status))completion {
    [self tokenizeAndValidateApplePayPayment:payment completion:^(PPCValidatorResult *result, NSError *error) {
        self.applePayCompletionBlock(result, error, ^(BOOL success) {
            if (success) {
                completion(PKPaymentAuthorizationStatusSuccess);
            } else {
                completion(PKPaymentAuthorizationStatusFailure);
            }
        });
    }];
}

@end

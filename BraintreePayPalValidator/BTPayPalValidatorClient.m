#import "BTPayPalValidatorClient_Internal.h"
#import "BTPayPalCardContingencyRequest.h"
#import "BTPayPalCheckoutRequest.h"
#import "BTPayPalValidatorResult.h"

NSString * const BTPayPalValidatorErrorDomain = @"com.braintreepayments.BTPayPalValidatorErrorDomain";

@interface BTPayPalValidatorClient() <PKPaymentAuthorizationViewControllerDelegate>

@property (copy, nonatomic) NSString *accessToken;
@property (copy, nonatomic) NSString *orderId;

@property (weak, nonatomic) id<BTViewControllerPresentingDelegate> presentingDelegate;
@property (nonatomic, copy) void (^applePayCompletionBlock)(BTPayPalValidatorResult * _Nullable validatorResult, NSError * _Nullable, BTApplePayResultHandler successHandler);

@property (nonatomic, strong) BTAPIClient *btAPIClient;

@property (nonatomic, strong) BTPayPalValidatorResult *validatorResult;

@end

// TODO: - add delegate as a property instead of parameter to the checkout methods
@implementation BTPayPalValidatorClient

- (instancetype)initWithAccessToken:(NSString *)accessToken {
    self = [super init];
    if (self) {
        _accessToken = accessToken;

        _payPalAPIClient = [[BTPayPalAPIClient alloc] initWithAccessToken:accessToken];

        NSString *tokenizationKey = @"sandbox_fwvdxncw_rwwnkqg2xg56hm2n";

        _btAPIClient = [[BTAPIClient alloc] initWithAuthorization:tokenizationKey];
        _applePayClient = [[BTApplePayClient alloc] initWithAPIClient:_btAPIClient];
        _cardClient = [[BTCardClient alloc] initWithAPIClient:_btAPIClient];
        _paymentFlowDriver = [[BTPaymentFlowDriver alloc] initWithAPIClient:_btAPIClient];

        _validatorResult = [BTPayPalValidatorResult new];
    }

    return self;
}

- (void)checkoutWithCard:(NSString *)orderID
                    card:(BTCard *)card
      presentingDelegate:(id<BTViewControllerPresentingDelegate>)viewControllerPresentingDelegate
              completion:(void (^)(BTPayPalValidatorResult * _Nullable validateResult, NSError * _Nullable error))completion {
    self.orderId = orderID;

    [self.cardClient tokenizeCard:card completion:^(BTCardNonce * tokenizedCard, NSError *error) {
        if (tokenizedCard) {
            [self validateTokenizedCard:tokenizedCard
                 withPresentingDelegate:viewControllerPresentingDelegate
                             completion:^(BOOL success, NSError *error) {
                if (success) {
                    BTPayPalValidatorResult *validatorResult = [BTPayPalValidatorResult new];
                    validatorResult.orderID = self.orderId;
                    validatorResult.type = BTPayPalValidatorResultTypeCard;
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
       withPresentingDelegate:(id<BTViewControllerPresentingDelegate>)viewControllerPresentingDelegate
                   completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    [self.payPalAPIClient validatePaymentMethod:tokenizedCard
                                     forOrderId:self.orderId
                                     completion:^(BTPayPalValidateResult *result, NSError __unused *error) {
                                            if (error) {
                                                completion(NO, error);
                                            } else if (result.contingencyURL) {
                                                BTPayPalCardContingencyRequest *contingencyRequest = [[BTPayPalCardContingencyRequest alloc] initWithContigencyURL:result.contingencyURL];

                                                self.paymentFlowDriver.viewControllerPresentingDelegate = viewControllerPresentingDelegate;
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
        presentingDelegate:(id<BTViewControllerPresentingDelegate>)viewControllerPresentingDelegate
                completion:(void (^)(BTPayPalValidatorResult * _Nullable validateResult, NSError * _Nullable error))completion {
    self.orderId = orderId;

    // TODO: Use hardcode URL (https://api.paypal.com/checkoutnow?token=) with orderId to complete PayPal flow until orders v2 accepts universal JWT

    BTPayPalCheckoutRequest *request = [BTPayPalCheckoutRequest new];
    request.checkoutURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.ppcpn.stage.paypal.com/checkoutnow?token=%@", self.orderId]];

    self.paymentFlowDriver.viewControllerPresentingDelegate = viewControllerPresentingDelegate;
    [self.paymentFlowDriver startPaymentFlow:request completion:^(BTPaymentFlowResult * __unused result, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        
        BTPayPalValidatorResult *validatorResult = [BTPayPalValidatorResult new];
        validatorResult.orderID = self.orderId;
        validatorResult.type = BTPayPalValidatorResultTypePayPal;
        completion(validatorResult, nil);
    }];
}

- (void)checkoutWithApplePay:(NSString * __unused)orderId
              paymentRequest:(PKPaymentRequest *)paymentRequest
          presentingDelegate:(id<BTViewControllerPresentingDelegate>)viewControllerPresentingDelegate
                  completion:(void (^)(BTPayPalValidatorResult * _Nullable tokenizedApplePayPayment, NSError * _Nullable error, BTApplePayResultHandler resultHandler))completion NS_SWIFT_NAME(checkoutWithApplePay(_:paymentRequest:presentingDelegate:completion:)) {
    self.orderId = orderId;

    self.presentingDelegate = viewControllerPresentingDelegate;
    self.applePayCompletionBlock = completion;

    [self.applePayClient paymentRequest:^(PKPaymentRequest *defaultPaymentRequest, NSError *error) {
        if (defaultPaymentRequest) {
            paymentRequest.countryCode = defaultPaymentRequest.countryCode;
            paymentRequest.currencyCode = defaultPaymentRequest.currencyCode;
            paymentRequest.merchantIdentifier = defaultPaymentRequest.merchantIdentifier;
            paymentRequest.supportedNetworks = defaultPaymentRequest.supportedNetworks;

            PKPaymentAuthorizationViewController *authorizationViewController = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
            authorizationViewController.delegate = self;
            [viewControllerPresentingDelegate paymentDriver:self requestsPresentationOfViewController:authorizationViewController];
        } else {
            self.applePayCompletionBlock(nil, error, nil);
        }
    }];
}

- (void)tokenizeAndValidateApplePayPayment:(PKPayment *)payment completion:(void (^)(BTPayPalValidatorResult * _Nullable result, NSError * _Nullable error))completion {
    [self.applePayClient tokenizeApplePayPayment:payment completion:^(BTApplePayCardNonce *tokenizedApplePayPayment, NSError *error) {
        if (!tokenizedApplePayPayment || error) {
            completion(nil, error);
            return;
        }

        [self.payPalAPIClient validatePaymentMethod:tokenizedApplePayPayment
                                         forOrderId:self.orderId
                                         completion:^(BTPayPalValidateResult * __unused result, NSError *error) {
            if (!result || error) {
                completion(nil, error);
                return;
            }

            BTPayPalValidatorResult *validatorResult = [BTPayPalValidatorResult new];
            validatorResult.orderID = self.orderId;
            validatorResult.type = BTPayPalValidatorResultTypeApplePay;
            completion(validatorResult, error);
        }];
    }];
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate

- (void)paymentAuthorizationViewControllerDidFinish:(nonnull PKPaymentAuthorizationViewController *)controller {
    [self.presentingDelegate paymentDriver:self
         requestsDismissalOfViewController:controller];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController * __unused)controller
                       didAuthorizePayment:(PKPayment *)payment
                                   handler:(void (^)(PKPaymentAuthorizationResult * _Nonnull))completion API_AVAILABLE(ios(11.0)) {
    [self tokenizeAndValidateApplePayPayment:payment completion:^(BTPayPalValidatorResult *result, NSError *error) {
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
    [self tokenizeAndValidateApplePayPayment:payment completion:^(BTPayPalValidatorResult *result, NSError *error) {
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

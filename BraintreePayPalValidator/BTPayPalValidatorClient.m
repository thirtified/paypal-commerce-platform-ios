 #import "BTPayPalValidatorClient.h"
 #import "BTPayPalAPIClient.h"
 #import "BTPayPalCardContingencyRequest.h"
 #import "BTPayPalCheckoutRequest.h"

 NSString * const BTPayPalValidatorErrorDomain = @"com.braintreepayments.BTPayPalValidatorErrorDomain";

 @interface BTPayPalValidatorClient() <PKPaymentAuthorizationViewControllerDelegate>

 @property (copy, nonatomic) NSString *accessToken;
 @property (copy, nonatomic) NSString *orderId;

 @property (weak, nonatomic) id<BTViewControllerPresentingDelegate> presentingDelegate;
 @property (nonatomic, copy) void (^applePayCompletionBlock)(BTApplePayCardNonce * _Nullable tokenizedApplePayPayment, NSError * _Nullable, BTAppleyPayResultHandler successHandler);

 @property (strong, nonatomic) BTPayPalAPIClient *payPalAPIClient;
 @property (nonatomic, strong) BTAPIClient *btAPIClient;
 @property (nonatomic, strong) BTApplePayClient *applePayClient;
 @property (nonatomic, strong) BTPaymentFlowDriver *paymentFlowDriver;

 @end

 @implementation BTPayPalValidatorClient

 - (instancetype)initWithAccessToken:(NSString *)accessToken
                             orderId:(NSString *)orderId {
     self = [super init];
     if (self) {
         _accessToken = accessToken;
         _orderId = orderId;

         _payPalAPIClient = [[BTPayPalAPIClient alloc] initWithAccessToken:accessToken];

         NSString *tokenizationKey = @"sandbox_fwvdxncw_rwwnkqg2xg56hm2n";

         // TO DO: Waiting for tokenize to accept PP access tokens
         _btAPIClient = [[BTAPIClient alloc] initWithAuthorization:tokenizationKey];
         _applePayClient = [[BTApplePayClient alloc] initWithAPIClient:_btAPIClient];
     }

     return self;
 }

 - (void)checkoutWithCard:(BTCard *)card
       presentingDelegate:(id<BTViewControllerPresentingDelegate>)viewControllerPresentingDelegate
               completion:(void (^)(BTCardNonce * _Nullable tokenizedCard, NSError * _Nullable error))completion {
     [self tokenizeCard:card completion:^(BTCardNonce * _Nullable tokenizedCard, NSError * _Nullable error) {
         if (tokenizedCard) {
             [self validateTokenizedCard:tokenizedCard
                  withPresentingDelegate:viewControllerPresentingDelegate
                              completion:^(BOOL success, NSError * _Nullable error) {
                                  if (success) {
                                      completion(tokenizedCard, nil);
                                  } else {
                                      completion(nil, error);
                                  }
                              }];
         } else {
             completion(nil, error);
         }
     }];
 }

 - (void)tokenizeCard:(BTCard *)card completion:(void (^)(BTCardNonce * _Nullable tokenizedCard, NSError * _Nullable error))completion {
     BTCardClient *btCardClient = [[BTCardClient alloc] initWithAPIClient:self.btAPIClient];

     [btCardClient tokenizeCard:card completion:^(BTCardNonce * _Nullable tokenizedCard, NSError * _Nullable error) {
         completion(tokenizedCard, error);
     }];
 }

 - (void)validateTokenizedCard:(BTCardNonce *)tokenizedCard
        withPresentingDelegate:(id<BTViewControllerPresentingDelegate>)viewControllerPresentingDelegate
                    completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
     [self.payPalAPIClient validatePaymentMethod:tokenizedCard
                                      forOrderId:self.orderId
                                      completion:^(BTPayPalValidateResult * _Nullable result, NSError __unused * _Nullable error) {
                                          if (result.contingencyURL) {
                                              BTPayPalCardContingencyRequest *contingencyRequest = [[BTPayPalCardContingencyRequest alloc] initWithContigencyURL:result.contingencyURL];

                                              self.paymentFlowDriver = [[BTPaymentFlowDriver alloc] initWithAPIClient:self.btAPIClient];
                                              self.paymentFlowDriver.viewControllerPresentingDelegate = viewControllerPresentingDelegate;
                                              [self.paymentFlowDriver startPaymentFlow:contingencyRequest completion:^(BTPaymentFlowResult * _Nullable result, NSError __unused * _Nullable error) {
                                                  if (result) {
                                                      completion(YES, nil);
                                                  } else {
                                                      completion(NO, error);
                                                  }
                                              }];
                                          } else {
                                              completion(YES, nil);
                                          }
                                      }];
 }

 - (void)checkoutWithPayPalPresentingDelegate:(id<BTViewControllerPresentingDelegate>)viewControllerPresentingDelegate
                                   completion:(void (^)(NSError * _Nullable error))completion {
     // TODO: Use hardcode URL (https://api.paypal.com/checkoutnow?token=) with orderId to complete PayPal flow until orders v2 accepts universal JWT

     BTPayPalCheckoutRequest *request = [BTPayPalCheckoutRequest new];
     request.checkoutURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.te-ppcp-nativesdk.qa.paypal.com/checkoutnow?token=%@", self.orderId]];

     self.paymentFlowDriver = [[BTPaymentFlowDriver alloc] initWithAPIClient:self.btAPIClient];
     self.paymentFlowDriver.viewControllerPresentingDelegate = viewControllerPresentingDelegate;
     [self.paymentFlowDriver startPaymentFlow:request completion:^(BTPaymentFlowResult * _Nullable result, NSError __unused * _Nullable error) {
         NSLog(@"%@", result);
     }];

     completion(nil);
 }

 - (void)checkoutWithApplePay:(PKPaymentRequest *)paymentRequest
           presentingDelegate:(id<BTViewControllerPresentingDelegate>)viewControllerPresentingDelegate
                   completion:(void (^)(BTApplePayCardNonce * _Nullable tokenizedApplePayPayment, NSError * _Nullable error, BTAppleyPayResultHandler resultHandler))completion {
     self.presentingDelegate = viewControllerPresentingDelegate;
     self.applePayCompletionBlock = completion;

     [self.applePayClient paymentRequest:^(PKPaymentRequest * _Nullable defaultPaymentRequest, NSError * _Nullable error) {
         if (defaultPaymentRequest) {
             paymentRequest.countryCode = defaultPaymentRequest.countryCode;
             paymentRequest.currencyCode = defaultPaymentRequest.currencyCode;
             paymentRequest.merchantIdentifier = defaultPaymentRequest.merchantIdentifier;
             paymentRequest.supportedNetworks = defaultPaymentRequest.supportedNetworks;

             PKPaymentAuthorizationViewController *authorizationViewController = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
             authorizationViewController.delegate = self;
             [viewControllerPresentingDelegate paymentDriver:self
                        requestsPresentationOfViewController:authorizationViewController];
         }
         else {
             completion(nil, error, nil);
         }
     }];
 }

 - (void)paymentRequest:(void (^)(PKPaymentRequest * _Nullable, NSError * _Nullable))completion {
     [self.applePayClient paymentRequest:^(PKPaymentRequest * _Nullable paymentRequest, NSError * _Nullable error) {
         completion(paymentRequest, error);
     }];
 }

 - (void)tokenizeApplePayPayment:(PKPayment *)payment
                      completion:(void (^)(BTApplePayCardNonce * _Nullable tokenizedApplePayPayment, NSError * _Nullable error))completion {
     [self.applePayClient tokenizeApplePayPayment:payment completion:^(BTApplePayCardNonce * _Nullable tokenizedApplePayPayment, NSError * _Nullable error) {
         if (tokenizedApplePayPayment) {
             [self.payPalAPIClient validatePaymentMethod:tokenizedApplePayPayment
                                              forOrderId:self.orderId
                                              completion:^(BTPayPalValidateResult * _Nullable __unused result, NSError * _Nullable error) {
                                                  completion(tokenizedApplePayPayment, error);
                                              }];
         }
         else {
             completion(nil, error);
         }
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
     [self tokenizeApplePayPayment:payment completion:^(BTApplePayCardNonce * _Nullable tokenizedApplePayPayment, NSError * _Nullable error) {
         self.applePayCompletionBlock(tokenizedApplePayPayment, error, ^(BOOL success) {
             if (success) {
                 completion([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusSuccess errors:nil]);
             }
             else {
                 completion([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusFailure errors:nil]);
             }
         });
     }];
 }

 - (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                        didAuthorizePayment:(PKPayment *)payment
                                 completion:(void (^)(PKPaymentAuthorizationStatus status))completion {
     [self tokenizeApplePayPayment:payment completion:^(BTApplePayCardNonce * _Nullable tokenizedApplePayPayment, NSError * _Nullable error) {
         self.applePayCompletionBlock(tokenizedApplePayPayment, error, ^(BOOL success) {
             if (success) {
                 completion(PKPaymentAuthorizationStatusSuccess);
             }
             else {
                 completion(PKPaymentAuthorizationStatusFailure);
             }
         });
     }];
 }

 @end

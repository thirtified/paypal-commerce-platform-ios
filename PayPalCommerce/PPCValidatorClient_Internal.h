#import "PPCValidatorClient.h"
#import "PPCAPIClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface PPCValidatorClient ()

@property (nonatomic, strong) BTApplePayClient *applePayClient;
@property (nonatomic, strong) PPCAPIClient *payPalAPIClient;
@property (nonatomic, strong) BTCardClient *cardClient;
@property (nonatomic, strong) BTPaymentFlowDriver *paymentFlowDriver;

@end

NS_ASSUME_NONNULL_END

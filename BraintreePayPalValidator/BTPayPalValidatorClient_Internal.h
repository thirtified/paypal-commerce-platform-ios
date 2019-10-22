#import "BTPayPalValidatorClient.h"
#import "BTPayPalAPIClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface BTPayPalValidatorClient ()

@property (nonatomic, strong) BTApplePayClient *applePayClient;

@property (nonatomic, strong) BTPayPalAPIClient *payPalAPIClient;

@end

NS_ASSUME_NONNULL_END

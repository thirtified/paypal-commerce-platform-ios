@import Braintree.BraintreeCore;

NS_ASSUME_NONNULL_BEGIN

@interface PPCOrderDetails : NSObject

@property (strong, nonatomic) NSURL *approveURL;

- (nullable instancetype)initWithJSON:(BTJSON *)json;

@end

NS_ASSUME_NONNULL_END

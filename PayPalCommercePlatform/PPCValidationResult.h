@import Braintree.BraintreeCore;

NS_ASSUME_NONNULL_BEGIN

@interface PPCValidationResult : NSObject

@property (nonatomic, readonly, nullable) NSURL *contingencyURL;

@property (nonatomic, copy) NSString *issueType;

@property (nonatomic, copy) NSString *message;

- (instancetype)initWithJSON:(BTJSON *)JSON;

@end

NS_ASSUME_NONNULL_END

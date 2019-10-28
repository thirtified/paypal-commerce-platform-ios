#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BTPayPalUAT : NSObject

/**
 Initialize a PayPalUAT with a PayPal UAT string.
 */
- (nullable instancetype)initWithUATString:(NSString *)payPalUAT error:(NSError **)error NS_DESIGNATED_INITIALIZER;

- (instancetype)init __attribute__((unavailable("Please use initWithPayPalUAT:error: instead.")));

/**
 The extracted authorization fingerprint
 */
@property (nonatomic, readonly, copy) NSString *token;

/**
 The extracted configURL
 */
@property (nonatomic, readonly, strong) NSURL *configURL;

@end

NS_ASSUME_NONNULL_END

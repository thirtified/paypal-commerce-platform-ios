#import <Foundation/Foundation.h>

#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BTPayPalValidateResult : NSObject

@property (nonatomic, readonly, nullable) NSURL *contingencyURL;

- (instancetype)initWithJSON:(BTJSON *)JSON;

@end

NS_ASSUME_NONNULL_END

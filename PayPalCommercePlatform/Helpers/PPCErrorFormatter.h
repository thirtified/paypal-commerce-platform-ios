#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PPCErrorFormatter : NSObject

/** Converts errors from the Braintree SDK into PayPal merchant friendly errors. */
+ (NSError *)convertToPPCError:(NSError *)error withDomain:(NSString *)errorDomain;

@end

NS_ASSUME_NONNULL_END

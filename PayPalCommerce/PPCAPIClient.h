#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif

#if __has_include("BraintreeCard.h")
#import "BraintreeCard.h"
#else
#import <BraintreeCard/BraintreeCard.h>
#endif

#import "PPCValidationResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface PPCAPIClient : NSObject

@property (readonly, nonatomic) NSString *accessToken;
@property (nonatomic, strong) NSURLSession *urlSession;

- (instancetype)initWithAccessToken:(NSString *)accessToken;

- (void)validatePaymentMethod:(BTPaymentMethodNonce *)paymentMethod
                   forOrderId:(NSString *)orderId
                   completion:(void (^)(PPCValidationResult * _Nullable result, NSError * _Nullable error))completion;

- (NSDictionary *)constructValidatePayload:(NSString *)nonce;

- (nullable NSURLRequest *)createValidateURLRequest:(NSURL *)url
                             withPaymentMethodNonce:(NSString *)paymentMethodNonce
                                              error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

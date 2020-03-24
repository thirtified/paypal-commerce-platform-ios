@import Braintree.BraintreeCore;
@import Braintree.BraintreeCard;

#import "PPCValidationResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface PPCAPIClient : NSObject

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) BTAPIClient *braintreeAPIClient;

- (nullable instancetype)initWithAccessToken:(NSString *)accessToken;

- (void)validatePaymentMethod:(BTPaymentMethodNonce *)paymentMethod
                   forOrderId:(NSString *)orderId
                      with3DS:(BOOL)isThreeDSecureRequired
                   completion:(void (^)(PPCValidationResult * _Nullable result, NSError * _Nullable error))completion;

- (NSDictionary *)constructValidatePayload:(NSString *)nonce
                                   with3DS:(BOOL)isThreeDSecureRequired;

- (nullable NSURLRequest *)createValidateURLRequest:(NSURL *)url
                             withPaymentMethodNonce:(NSString *)paymentMethodNonce
                                            with3DS:(BOOL)isThreeDSecureRequired
                                              error:(NSError **)error;

- (void)fetchPayPalApproveURLForOrderId:(NSString *)orderId
                             completion:(void (^)(NSURL * _Nullable approveURL, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END

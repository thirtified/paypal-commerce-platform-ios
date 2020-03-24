#import "BTAPIClient+Analytics_Internal.h"
#import "PPCAPIClient.h"
#import "PPCValidatorClient.h"
#import "PPCOrderDetails.h"

@interface PPCAPIClient()

@property (nonatomic, strong) BTPayPalUAT *payPalUAT;

@end

@implementation PPCAPIClient

- (nullable instancetype)initWithAccessToken:(NSString *)accessToken {
    if (self = [super init]) {
        _urlSession = NSURLSession.sharedSession;
        _braintreeAPIClient = [[BTAPIClient alloc] initWithAuthorization:accessToken];
        
        NSError *error;
        _payPalUAT = [[BTPayPalUAT alloc] initWithUATString:accessToken error:&error];
        if (error || !_payPalUAT) {
            NSLog(@"%@", error.localizedDescription ?: @"Error initializing PayPal UAT");
            return nil;
        }
    }
    
    return self;
}

- (void)validatePaymentMethod:(BTPaymentMethodNonce *)paymentMethod
                   forOrderId:(NSString *)orderId
                      with3DS:(BOOL)isThreeDSecureRequired
                   completion:(void (^)(PPCValidationResult * _Nullable result, NSError * _Nullable error))completion {
    
    NSString *urlString = [NSString stringWithFormat:@"%@/v2/checkout/orders/%@/validate-payment-method", self.payPalUAT.basePayPalURL, orderId];
    NSError *createRequestError;
    
    NSURLRequest *urlRequest = [self createValidateURLRequest:[NSURL URLWithString:urlString]
                                       withPaymentMethodNonce:paymentMethod.nonce
                                                      with3DS:isThreeDSecureRequired
                                                        error:&createRequestError];
    if (!urlRequest) {
        completion(nil, createRequestError);
        return;
    }
    
    [[self.urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.validate.failed"];
                completion(nil, error);
                return;
            }
            
            BTJSON *json = [[BTJSON alloc] initWithData:data];
            NSLog(@"Validate result: %@", json);
            PPCValidationResult *result = [[PPCValidationResult alloc] initWithJSON:json];
            
            NSInteger statusCode = ((NSHTTPURLResponse *) response).statusCode;
            if (statusCode >= 400) {
                // Contingency error represents 3DS challenge required
                if ([result.issueType isEqualToString:@"CONTINGENCY"]) {
                    completion(result, nil);
                    return;
                } else {
                    NSString *errorDescription;
                    if (result.issueType) {
                        errorDescription = result.issueType;
                    } else if (result.message) {
                        errorDescription = result.message;
                    } else {
                        errorDescription = @"Validation Error";
                    }
                    
                    NSError *validateError = [[NSError alloc] initWithDomain:PPCValidatorErrorDomain
                                                                        code:0
                                                                    userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                    
                    [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.validate.failed"];
                    completion(nil, validateError);
                    return;
                }
            }
            
            [self.braintreeAPIClient sendAnalyticsEvent:@"ios.paypal-commerce-platform.validate.succeeded"];
            completion(result, nil);
        });
    }] resume];
}

- (nullable NSURLRequest *)createValidateURLRequest:(NSURL *)url
                             withPaymentMethodNonce:(NSString *)paymentMethodNonce
                                            with3DS:(BOOL)isThreeDSecureRequired
                                              error:(NSError **)error {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.payPalUAT.token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *body = [self constructValidatePayload:paymentMethodNonce with3DS:isThreeDSecureRequired];
    
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:error];
    if (!bodyData) {
        return nil;
    }
    request.HTTPBody = bodyData;
    
    return [request copy];
}

- (NSDictionary *)constructValidatePayload:(NSString *)nonce
                                   with3DS:(BOOL) isThreeDSecureRequired {
    NSMutableDictionary *tokenParameters = [NSMutableDictionary new];
    NSMutableDictionary *validateParameters = [NSMutableDictionary new];
    
    tokenParameters[@"id"] = nonce;
    tokenParameters[@"type"] = @"NONCE";
    
    validateParameters[@"payment_source"] = @{
        @"token" : tokenParameters,
        @"contingencies": (isThreeDSecureRequired ? @[@"3D_SECURE"] : @[])
    };
    
    //TODO - sweep all logging before test pilot
    NSLog(@"🍏Validate Request Params: %@", validateParameters);
    return (NSDictionary *)validateParameters;
}

- (void)fetchPayPalApproveURLForOrderId:(NSString *)orderId
                             completion:(void (^)(NSURL * _Nullable approveURL, NSError * _Nullable error))completion {
    NSString *urlString = [NSString stringWithFormat:@"%@/v2/checkout/orders/%@", self.payPalUAT.basePayPalURL, orderId];
    NSURL *url = [NSURL URLWithString:urlString];
    
    if (!url) {
        NSError *error = [NSError errorWithDomain:PPCValidatorErrorDomain
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey: @"Checkout with PayPal failed. Unable to fetch approve url."}];
        completion(nil, error);
        return;
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.payPalUAT.token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [[self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, __unused NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                completion(nil, error);
                return;
            }
            
            PPCOrderDetails *orderDetails = [[PPCOrderDetails alloc] initWithJSON:[[BTJSON alloc] initWithData:data]];
            
            if (!orderDetails) {
                NSError *error = [NSError errorWithDomain:PPCValidatorErrorDomain
                                                     code:0
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Checkout with PayPal failed. Malformed response from /orders/v2 endpoint."}];
                completion(nil, error);
                return;
            }
            
            completion(orderDetails.approveURL, nil);
            return;
        });
    }] resume];
}

@end

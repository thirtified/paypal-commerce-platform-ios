#import "PPCAPIClient.h"
#import "PPCValidatorClient.h"

@interface PPCAPIClient()

@property (copy, nonatomic) NSString *accessToken;

@end

@implementation PPCAPIClient

- (instancetype)initWithAccessToken:(NSString *)accessToken {
    if (self = [super init]) {
        _accessToken = accessToken;
        _urlSession = NSURLSession.sharedSession;
    }

    return self;
}

- (void)validatePaymentMethod:(BTPaymentMethodNonce *)paymentMethod
                   forOrderId:(NSString *)orderId
                   completion:(void (^)(PPCValidationResult * _Nullable result, NSError * _Nullable error))completion {
    NSString *urlString = [NSString stringWithFormat:@"https://api.ppcpn.stage.paypal.com/v2/checkout/orders/%@/validate-payment-method", orderId];
    NSError *createRequestError;

    NSURLRequest *urlRequest = [self createValidateURLRequest:[NSURL URLWithString:urlString]
                                       withPaymentMethodNonce:paymentMethod.nonce
                                                        error:&createRequestError];
    if (!urlRequest) {
        completion(nil, createRequestError);
        return;
    }

    [[self.urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                completion(nil, error);
                return;
            }

            BTJSON *json = [[BTJSON alloc] initWithData:data];
            NSLog(@"Validate result: %@", json);
            PPCValidationResult *result = [[PPCValidationResult alloc] initWithJSON:json];

            NSInteger statusCode = ((NSHTTPURLResponse *) response).statusCode;
            if (statusCode >= 400) {
                if ([result.issueType isEqualToString:@"CONTINGENCY"]) {
                    completion(result, nil);
                    return;
                } else {
                    NSString *errorDescription = result.message ?: @"Validation Error";
                    NSError *validateError = [[NSError alloc] initWithDomain:PPCValidatorErrorDomain
                        code:0
                    userInfo:@{NSLocalizedDescriptionKey: errorDescription}];

                    completion(nil, validateError);
                    return;
                }
            }

            completion(result, nil);
        });
    }] resume];
}

- (nullable NSURLRequest *)createValidateURLRequest:(NSURL *)url
                             withPaymentMethodNonce:(NSString *)paymentMethodNonce
                                              error:(NSError **)error {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *body = [self constructValidatePayload:paymentMethodNonce];

    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:error];
    if (!bodyData) {
        return nil;
    }
    request.HTTPBody = bodyData;

    return [request copy];
}

- (NSDictionary *)constructValidatePayload:(NSString *)nonce {
    NSDictionary *body = @{@"payment_source":
                               @{@"token":
                                     @{@"id": nonce,
                                       // contingency nonce "tokencc_bf_p5hq9t_2dxqdg_yv8pfw_m6935m_rpz"
                                       // regular nonce "8wgd2f"
                                       @"type": @"NONCE"
                                       },
                                 @"contingencies": @[@"3D_SECURE"]}
                           };

    return body;
}

@end

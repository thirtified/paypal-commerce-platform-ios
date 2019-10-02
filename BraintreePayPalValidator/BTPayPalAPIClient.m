#import "BTPayPalAPIClient.h"

@interface BTPayPalAPIClient()

@property (copy, nonatomic) NSString *accessToken;

@end

@implementation BTPayPalAPIClient

- (instancetype)initWithAccessToken:(NSString *)accessToken {
    if (self = [super init]) {
        _accessToken = accessToken;
    }

    return self;
}

- (void)validatePaymentMethod:(BTPaymentMethodNonce *)paymentMethod
                   forOrderId:(NSString *)orderId
                   completion:(void (^)(BTPayPalValidateResult * _Nullable result, NSError * _Nullable error))completion {
    NSString *urlString = [NSString stringWithFormat:@"https://api.ppcpn.stage.paypal.com/v2/checkout/orders/%@/validate-payment-method", orderId];
    NSError *createRequestError;

    NSURLRequest *urlRequest = [self createValidateURLRequest:[NSURL URLWithString:urlString]
                                       withPaymentMethodNonce:paymentMethod.nonce
                                                        error:&createRequestError];
    if (!urlRequest) {
        completion(nil, createRequestError);
        return;
    }

    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable __unused response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                completion(nil, error);
                return;
            }

            BTJSON *json = [[BTJSON alloc] initWithData:data];

            BTPayPalValidateResult *result = [[BTPayPalValidateResult alloc] initWithJSON:json];
            completion(result, nil);
        });
    }] resume];
}

- (nullable NSURLRequest *)createValidateURLRequest:(NSURL *)url
                             withPaymentMethodNonce:(NSString *)paymentMethodNonce
                                              error:(NSError **)error{
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

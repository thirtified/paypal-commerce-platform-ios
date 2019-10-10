#import "BTPayPalUAT.h"
#import "BTJSON.h"

NSString * const BTPayPalUATErrorDomain = @"com.braintreepayments.BTPayPalUATErrorDomain";

@interface BTPayPalUAT()

@property (nonatomic, readwrite, strong) BTJSON *json;
@property (nonatomic, readwrite, copy) NSString *authorizationFingerprint;

@end

@implementation BTPayPalUAT

- (instancetype)init {
    return nil;
}

- (nullable instancetype)initWithPayPalUAT:(NSString *)payPalUAT error:(NSError **)error {
    self = [super init];
    if (self) {
        _authorizationFingerprint = payPalUAT;
        _json = [self decodePayPalUAT:payPalUAT error:error];
    }

    return self;
}

- (BTJSON *)decodePayPalUAT:(NSString *)payPalUAT error:(NSError * __autoreleasing *)error {
    //TODO: Add error handling for misformed payPalUAT strings
    NSArray *payPalUATComponents = [payPalUAT componentsSeparatedByString:@"."];
    NSString *base64EncodedBody = [NSString stringWithFormat:@"%@==", payPalUATComponents[1]];

    NSError *JSONError = nil;
    NSData *base64DecodedPayPalUAT = [[NSData alloc] initWithBase64EncodedString:base64EncodedBody
                                                                           options:0];

    NSDictionary *rawPayPalUAT;
    if (base64DecodedPayPalUAT) {
        rawPayPalUAT = [NSJSONSerialization JSONObjectWithData:base64DecodedPayPalUAT options:0 error:&JSONError];
    }

    if (!rawPayPalUAT) {
        if (error) {
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithDictionary:@{
                                                                                              NSLocalizedDescriptionKey: @"Invalid PayPal UAT.",
                                                                                              NSLocalizedFailureReasonErrorKey: @"Invalid JSON"
                                                                                              }];
            if (JSONError) {
                userInfo[NSUnderlyingErrorKey] = JSONError;
            }
            *error = [NSError errorWithDomain:BTPayPalUATErrorDomain
                                         code:0
                                     userInfo:userInfo];
        }
        return nil;
    }

    if (![rawPayPalUAT isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:BTPayPalUATErrorDomain
                                         code:0
                                     userInfo:@{
                                                NSLocalizedDescriptionKey: @"Invalid PayPal UAT.",
                                                NSLocalizedFailureReasonErrorKey: @"Invalid JSON. Expected to find an object at JSON root."
                                                }];
        }
        return nil;
    }

    return [[BTJSON alloc] initWithValue:rawPayPalUAT];
}

- (NSURL *)configURL {
    NSArray *externalIds = [self.json[@"external_ids"] asArray];
    NSString *braintreeMerchantID;
    for (NSString *externalId in externalIds) {
        if ([externalId hasPrefix:@"Braintree:"]) {
            braintreeMerchantID = [externalId componentsSeparatedByString:@":"][1];
            break;
        }
    }
    NSString *configString = [NSString stringWithFormat:@"/merchants/%@/client_api/v1/configuration", braintreeMerchantID];
    return [NSURL URLWithString:configString];
}

@end

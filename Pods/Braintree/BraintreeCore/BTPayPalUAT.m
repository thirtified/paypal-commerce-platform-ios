#import "BTPayPalUAT.h"
#import "BTJSON.h"

NSString * const BTPayPalUATErrorDomain = @"com.braintreepayments.BTPayPalUATErrorDomain";

@implementation BTPayPalUAT

- (instancetype)init {
    return nil;
}

- (nullable instancetype)initWithUATString:(NSString *)uatString error:(NSError **)error {
    self = [super init];
    if (self) {
        BTJSON *json = [self decodeUATString:uatString error:error];
        
        if (error && *error) {
            return nil;
        }
        
        NSArray *externalIds = [json[@"external_ids"] asArray];
        NSString *braintreeMerchantID;
        for (NSString *externalId in externalIds) {
            if ([externalId hasPrefix:@"Braintree:"]) {
                braintreeMerchantID = [externalId componentsSeparatedByString:@":"][1];
                break;
            }
        }
        
        if (!braintreeMerchantID) {
            if (error) {
                *error = [NSError errorWithDomain:BTPayPalUATErrorDomain
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey:@"Invalid PayPal UAT: Braintree merchant id not found."}];
            }
            return nil;
        }
        
        // TODO: - get this field from the UAT
        NSString *basePayPalURL = @"https://api.ppcpn.stage.paypal.com"; // [json[@"iss"] asString];
        
        // TODO: - get this field from the UAT
        NSString *baseBraintreeURL = @"https://api.sandbox.braintreegateway.com:443";

        if (!basePayPalURL || !baseBraintreeURL) {
            if (error) {
                *error = [NSError errorWithDomain:BTPayPalUATErrorDomain
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey:@"Invalid PayPal UAT: Issuer missing or unknown."}];
            }
            return nil;
        }
        
        _basePayPalURL = [NSURL URLWithString:basePayPalURL];
        _baseBraintreeURL = [NSURL URLWithString:baseBraintreeURL];
        _configURL = [NSURL URLWithString:[NSString stringWithFormat:@"/merchants/%@/client_api/v1/configuration", braintreeMerchantID]];
        _token = uatString;
    }

    return self;
}

- (BTJSON *)decodeUATString:(NSString *)uatString error:(NSError * __autoreleasing *)error {
    NSArray *payPalUATComponents = [uatString componentsSeparatedByString:@"."];
    
    if (payPalUATComponents.count != 3) {
        if (error) {
            *error = [NSError errorWithDomain:BTPayPalUATErrorDomain
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey:@"Invalid PayPal UAT: Missing payload."}];
        }
        return nil;
    }
    
    NSString *base64EncodedBody = [self base64EncodedStringWithPadding:payPalUATComponents[1]];

    NSData *base64DecodedPayPalUAT = [[NSData alloc] initWithBase64EncodedString:base64EncodedBody options:0];
    if (!base64DecodedPayPalUAT) {
        if (error) {
            *error = [NSError errorWithDomain:BTPayPalUATErrorDomain
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey:@"Invalid PayPal UAT: Unable to base-64 decode payload."}];
        }
        return nil;
    }
    
    NSDictionary *rawPayPalUAT;
    NSError *JSONError = nil;
    rawPayPalUAT = [NSJSONSerialization JSONObjectWithData:base64DecodedPayPalUAT options:0 error:&JSONError];

    if (JSONError) {
        if (error) {
            *error = [NSError errorWithDomain:BTPayPalUATErrorDomain
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Invalid PayPal UAT: %@", JSONError.localizedDescription]}];
        }
        return nil;
    }

    if (![rawPayPalUAT isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:BTPayPalUATErrorDomain
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid PayPal UAT: Expected to find an object at JSON root."}];
        }
        return nil;
    }

    return [[BTJSON alloc] initWithValue:rawPayPalUAT];
}

- (NSString *)base64EncodedStringWithPadding:(NSString *)base64EncodedString {
    if (base64EncodedString.length % 4 == 2) {
        return [NSString stringWithFormat:@"%@==", base64EncodedString];
    } else if (base64EncodedString.length % 4 == 3) {
        return [NSString stringWithFormat:@"%@=", base64EncodedString];
    } else {
        return base64EncodedString;
    }
}

@end

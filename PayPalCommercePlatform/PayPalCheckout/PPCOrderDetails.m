#import "PPCOrderDetails.h"

@implementation PPCOrderDetails

- (nullable instancetype)initWithJSON:(BTJSON *)json {
    self = [super init];
    if (self) {
        NSArray *links = [json[@"links"] asArray];
        for (id link in links) {
            NSDictionary *linkDict = [[[BTJSON alloc] initWithValue:link] asDictionary];
            NSString *relationType = [[[BTJSON alloc] initWithValue:linkDict[@"rel"]] asString];
            
            if ([relationType isEqualToString:@"approve"]) {
                NSString *urlString = [[[BTJSON alloc] initWithValue:linkDict[@"href"]] asString];
                _approveURL = [NSURL URLWithString:urlString];
                break;
            }
        }
        
        if (!_approveURL) {
            NSLog(@"PayPal checkout URL is invalid or missing.");
            return nil;
        }
    }
    return self;
}

@end

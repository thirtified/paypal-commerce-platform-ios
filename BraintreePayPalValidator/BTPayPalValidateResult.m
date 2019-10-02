#import "BTPayPalValidateResult.h"

@implementation BTPayPalValidateResult

- (instancetype)initWithJSON:(BTJSON * __unused)json {
    self = [super init];
    if (self) {
        NSArray *links = [json[@"links"] asArray];
        for (NSDictionary *linkDict in links) {
            if ([linkDict[@"rel"] isEqualToString:@"3ds-contingency-resolution"]) {
                _contingencyURL = [NSURL URLWithString:linkDict[@"href"]];
                break;
            }
        }
    }
    return self;
}

@end

#import "BTPayPalValidateResult.h"

@implementation BTPayPalValidateResult

- (instancetype)initWithJSON:(BTJSON *)json {
    self = [super init];
    if (self) {
        NSArray *links = [json[@"links"] asArray];
        for (NSDictionary *linkDict in links) {
            if ([linkDict[@"rel"] isEqualToString:@"3ds-contingency-resolution"]) {
                _contingencyURL = [NSURL URLWithString:linkDict[@"href"]];
                break;
            }
        }
        _issueType = [json[@"details"][0][@"issue"] asString];
        _message = [json[@"message"] asString];
    }
    return self;
}

@end

#import "PPCCardContingencyResult.h"
#import "BTURLUtils.h"

@implementation PPCCardContingencyResult

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        //TODO: URL's currently only have `undefined` for values. Get real example.
        NSDictionary *queryDictionary = [BTURLUtils queryParametersForURL:url];
        _state = queryDictionary[@"state"];
        _code = queryDictionary[@"code"];
        _error = queryDictionary[@"error"];
        _errorDescription = queryDictionary[@"error_description"];
    }

    return self;
}

@end

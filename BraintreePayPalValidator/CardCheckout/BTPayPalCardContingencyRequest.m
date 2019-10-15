#import "BTPayPalCardContingencyRequest.h"
#import "BTPayPalCardContingencyResult.h"
#import "BTPayPalValidatorClient.h"

@interface BTPayPalCardContingencyRequest ()

@property (strong, nonatomic) NSURL *contigencyURL;
@property (nonatomic, weak) id<BTPaymentFlowDriverDelegate> paymentFlowDriverDelegate;

@end

@implementation BTPayPalCardContingencyRequest

- (instancetype)initWithContigencyURL:(NSURL *)contigencyURL {
    self = [super init];
    if (self) {
        _contigencyURL = contigencyURL;
    }

    return self;
}

- (void)handleRequest:(BTPaymentFlowRequest *)request client:(__unused BTAPIClient *)apiClient paymentDriverDelegate:(id<BTPaymentFlowDriverDelegate>)delegate {
    self.paymentFlowDriverDelegate = delegate;
    BTPayPalCardContingencyRequest *validateRequest = (BTPayPalCardContingencyRequest *)request;

    NSString *redirectURLString = [NSString stringWithFormat:@"%@://x-callback-url/braintree/paypal-validator", [BTAppSwitch sharedInstance].returnURLScheme];
    NSURLQueryItem *redirectQueryItem = [NSURLQueryItem queryItemWithName:@"redirect_uri" value:redirectURLString];

    NSURLComponents *contingencyURLComponents = [NSURLComponents componentsWithURL:validateRequest.contigencyURL resolvingAgainstBaseURL:NO];
    contingencyURLComponents.queryItems = [contingencyURLComponents.queryItems arrayByAddingObject:redirectQueryItem];

    [delegate onPaymentWithURL:contingencyURLComponents.URL error:nil];
}

- (BOOL)canHandleAppSwitchReturnURL:(NSURL *)url sourceApplication:(__unused NSString *)sourceApplication {
    return [url.host isEqualToString:@"x-callback-url"] && [url.path hasPrefix:@"/braintree/paypal-validator"];
}

- (void)handleOpenURL:(nonnull NSURL *)url {
    BTPayPalCardContingencyResult *result = [[BTPayPalCardContingencyResult alloc] initWithURL:url];

    if (result.error.length) {
        NSError *validateError = [[NSError alloc] initWithDomain:BTPayPalValidatorErrorDomain
                                                    code:0
                                                userInfo:@{NSLocalizedDescriptionKey: result.errorDescription}];

        [self.paymentFlowDriverDelegate onPaymentComplete:nil error:validateError];
    } else {
        [self.paymentFlowDriverDelegate onPaymentComplete:result error:nil];
    }
}

- (nonnull NSString *)paymentFlowName {
    return @"PayPalValidateCard";
}

@end

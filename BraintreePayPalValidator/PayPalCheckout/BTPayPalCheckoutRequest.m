#import "BTPayPalCheckoutRequest.h"
#import "BTPayPalCheckoutResult.h"

@interface BTPayPalCheckoutRequest ()

@property (nonatomic, weak) id<BTPaymentFlowDriverDelegate> paymentFlowDriverDelegate;

@end

@implementation BTPayPalCheckoutRequest

- (void)handleRequest:(BTPaymentFlowRequest *)request client:(__unused BTAPIClient *)apiClient paymentDriverDelegate:(id<BTPaymentFlowDriverDelegate>)delegate {
    self.paymentFlowDriverDelegate = delegate;
    BTPayPalCheckoutRequest *checkoutRequest = (BTPayPalCheckoutRequest *)request;

    NSString *redirectURLString = [NSString stringWithFormat:@"%@://x-callback-url/braintree/paypal-checkout", [BTAppSwitch sharedInstance].returnURLScheme];
    NSURLQueryItem *redirectQueryItem = [NSURLQueryItem queryItemWithName:@"redirect_uri" value:redirectURLString];
    NSURLQueryItem *nativeXOQueryItem = [NSURLQueryItem queryItemWithName:@"native_xo" value:@"1"];

    NSURLComponents *checkoutURLComponents = [NSURLComponents componentsWithURL:checkoutRequest.checkoutURL resolvingAgainstBaseURL:NO];
    checkoutURLComponents.queryItems = [checkoutURLComponents.queryItems arrayByAddingObject:redirectQueryItem];
    checkoutURLComponents.queryItems = [checkoutURLComponents.queryItems arrayByAddingObject:nativeXOQueryItem];

    [delegate onPaymentWithURL:checkoutURLComponents.URL error:nil];
}

- (BOOL)canHandleAppSwitchReturnURL:(nonnull NSURL *)url sourceApplication:(__unused NSString *)sourceApplication {
    return [url.host isEqualToString:@"x-callback-url"] && [url.path hasPrefix:@"/braintree/paypal-checkout"];
}

- (void)handleOpenURL:(nonnull NSURL *)url {
    BTPayPalCheckoutResult *result = [[BTPayPalCheckoutResult alloc] initWithURL:url];

    [self.paymentFlowDriverDelegate onPaymentComplete:result error:nil];
}

- (nonnull NSString *)paymentFlowName {
    return @"PayPalCheckout";
}

@end

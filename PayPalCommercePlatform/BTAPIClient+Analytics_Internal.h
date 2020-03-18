@import Braintree.BraintreeCore;

@interface BTAPIClient (Analytics)

- (void)sendAnalyticsEvent:(NSString *)eventName;

@end

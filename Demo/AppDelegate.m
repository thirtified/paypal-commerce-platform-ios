#import "AppDelegate.h"
#import "Demo-Swift.h"

NSString *BraintreeDemoAppDelegatePaymentsURLScheme = @"com.braintreepayments.Demo.payments";

@implementation AppDelegate

- (BOOL)application:(__unused UIApplication *)application didFinishLaunchingWithOptions:(__unused NSDictionary *)launchOptions {
    [BTAppSwitch setReturnURLScheme: BraintreeDemoAppDelegatePaymentsURLScheme];

    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {

    if ([[url.scheme lowercaseString] isEqualToString:[BraintreeDemoAppDelegatePaymentsURLScheme lowercaseString]]) {
        return [BTAppSwitch handleOpenURL:url options:options];
    }

    return YES;
}

@end

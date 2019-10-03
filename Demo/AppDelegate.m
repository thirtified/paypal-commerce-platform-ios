#import "AppDelegate.h"
#import "Demo-Swift.h"

@interface AppDelegate ()

// TODO: Make constant for PaymentsURLScheme, @"com.braintreepayments.Demo.payments"

@end

@implementation AppDelegate

- (BOOL)application:(__unused UIApplication *)application didFinishLaunchingWithOptions:(__unused NSDictionary *)launchOptions {
    [BTAppSwitch setReturnURLScheme:@"com.braintreepayments.Demo.payments"];

    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {

    if ([url.scheme.lowercaseString  isEqualToString:@"com.braintreepayments.Demo.payments"]) {
        return [BTAppSwitch handleOpenURL:url options:options];
    }

    return YES;
}

@end

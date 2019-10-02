//
//  AppDelegate.m
//  BraintreePayPalValidator
//
//  Created by Cannillo, Sammy on 10/2/19.
//  Copyright © 2019 Braintree Payments. All rights reserved.
//

#import "AppDelegate.h"
#import "Demo-Swift.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(__unused UIApplication *)application didFinishLaunchingWithOptions:(__unused NSDictionary *)launchOptions {
    SammyViewController *rootViewController = [[SammyViewController alloc] init];
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    [self.window setRootViewController:rootViewController];
    [self.window makeKeyAndVisible];

    return YES;
}

@end

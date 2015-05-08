//
//  AirViewAppDelegate.m
//  AirView
//
//  Created by Clément Vasseur on 12/18/10.
//  Copyright 2010 Clément Vasseur. All rights reserved.
//

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"

#import "AirViewAppDelegate.h"
#import "AirViewController.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation AirViewAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	// Configure our logging framework.
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	[DDLog addLogger:[DDASLLogger sharedInstance]];

	// Override point for customization after application launch.
	[window makeKeyAndVisible];
	return YES;
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (airplay == nil) {
		airplay = [[AirViewController alloc] initWithWindow:window];
        [airplay startServer];
    }
}


- (void)applicationWillResignActive:(UIApplication *)application {
	[airplay stopPlayer];
}


- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [airplay stopPlayer];
    [airplay stopServer];
	airplay = nil;
}

@end

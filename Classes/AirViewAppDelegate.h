//
//  AirViewAppDelegate.h
//  AirView
//
//  Created by Clément Vasseur on 12/18/10.
//  Copyright 2010 Clément Vasseur. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AirViewController.h"

@interface AirViewAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
	AirViewController *airplay;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

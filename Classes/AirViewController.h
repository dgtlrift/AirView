//
//  AirPlayController.h
//  AirView
//
//  Created by Clément Vasseur on 12/16/10.
//  Copyright 2010 Clément Vasseur. All rights reserved.
//

#import <UiKit/UIWindow.h>
#import <MediaPlayer/MPMusicPlayerController.h>
#import <MediaPlayer/MPMoviePlayerController.h>
#import <MediaPlayer/MPMoviePlayerViewController.h>
#import "AirPlayHTTPServer.h"
#import "AirPlayMirroringHTTPServer.h"
#import "raopserver.h"
#import "dacpclient.h"

@interface AirViewController : NSObject {
    dacp_client_p _dacp_client;
    AirPlayHTTPServer *airPlayServer;
    AirPlayMirroringHTTPServer *airPlayMirroringServer;
    MPMoviePlayerViewController *playerView;
    MPMoviePlayerController *player;
    UIWindow *window;
    float start_position;
}

@property (nonatomic, assign) raop_server_p server;

- (id)initWithWindow:(UIView *)uiWindow;
- (void)startServer;
- (void)stopServer;
- (void)stopPlayer;
- (void)play:(NSURL *)location atRelativePosition:(float)position;
- (void)stop;
- (void)setVolume:(float)volume;
- (void)setPosition:(float)position;
- (float)position;
- (void)setRate:(float)value;
- (float)rate;
- (NSTimeInterval)duration;
- (BOOL)playable;

@end

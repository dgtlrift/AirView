//
//  AirPlayController.m
//  AirView
//
//  Created by Clément Vasseur on 12/16/10.
//  Copyright 2010 Clément Vasseur. All rights reserved.
//

#import "AirViewController.h"
#import "AirPlayHTTPConnection.h"
#import "DeviceInfo.h"
#import "DDLog.h"
#import "dacpclient.h"
#import "raopsession.h"
#import "AirViewServerInfo.h"
#import "airtunesd_wrapper.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_INFO;

@implementation AirViewController

- (instancetype)initWithWindow:(UIWindow *)uiWindow {
    if ((self = [super init])) {
        window = uiWindow;

		DDLogVerbose(@"AirPlayController: init");
        
        loadAirtunesd();
        
        struct raop_server_settings_t settings;
        settings.name = [[[DeviceInfo new] deviceName] cStringUsingEncoding:NSUTF8StringEncoding];
        settings.password = NULL;
        self.server = raop_server_create(settings);
        
		airPlayServer = [[AirPlayHTTPServer alloc] init];
		airPlayServer.airplay = self;

        if ([AirViewServerInfo new].mirroringEnabled) {
            airPlayMirroringServer = [[AirPlayMirroringHTTPServer alloc] init];
            airPlayMirroringServer.airplay = self;
        }

		playerView = [[MPMoviePlayerViewController alloc] initWithContentURL:nil];
		player = playerView.moviePlayer;
        player.allowsAirPlay = NO;
        [window setRootViewController:playerView];
    }

    return self;
}

- (void)startServer {
	DDLogVerbose(@"AirPlayController: startServer");
    
    uint16_t port = 5000;
    while (port < 5010 && !raop_server_start(self.server, port++));
    raop_server_set_new_session_callback(self.server, newServerSession, (__bridge void *)(self));
    
    NSError *error = nil;
    if(![airPlayServer start:&error]) {
		DDLogError(@"Error starting HTTP Server: %@", error);
    }
    
    error = nil;
    if([AirViewServerInfo new].mirroringEnabled && ![airPlayMirroringServer start:&error]) {
        DDLogError(@"Error starting HTTP Server: %@", error);
    }
}

- (void)stopServer {
	DDLogVerbose(@"AirPlayController: stopServer");
    
    raop_server_stop(self.server);
    raop_server_destroy(self.server);
	[airPlayServer stop];
    [airPlayMirroringServer stop];
}

- (void)play:(NSURL *)location atRelativePosition:(float)position {
	DDLogVerbose(@"AirPlayController: play %@", location);
    NSLog(@"%@", location);

	dispatch_async(dispatch_get_main_queue(), ^{
		if (playerView == nil) {
			playerView = [[MPMoviePlayerViewController alloc] initWithContentURL:location];
			player = playerView.moviePlayer;
            if([player respondsToSelector:@selector(setAllowsAirPlay:)]) {
                player.allowsAirPlay = NO;
            }	
		} else {
			[player setContentURL:location];
		}
		start_position = position;

		player.fullscreen = YES;

		[[NSNotificationCenter defaultCenter] addObserver:self
							 selector:@selector(movieFinishedCallback:)
							     name:MPMoviePlayerPlaybackDidFinishNotification
							   object:player];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(durationAvailableCallback:)
													 name:MPMovieDurationAvailableNotification
												   object:player];

		[player play];
	});
}

- (void)movieFinishedCallback:(NSNotification *)notification {
	DDLogVerbose(@"AirPlayController: movie finished");

	[[NSNotificationCenter defaultCenter] removeObserver:self
							name:MPMoviePlayerPlaybackDidFinishNotification
						      object:[notification object]];

	[self stopPlayer];
}

- (void)durationAvailableCallback:(NSNotification *)notification {
	DDLogVerbose(@"AirPlayController: duration available");

	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:MPMovieDurationAvailableNotification
												  object:[notification object]];

    MPMoviePlayerController *controller = [notification object];
	NSTimeInterval duration = [controller duration];

	if (player.playbackState ==  MPMoviePlaybackStateStopped)
		player.initialPlaybackTime = duration * start_position;
	else
		player.currentPlaybackTime = duration * start_position;
}

- (void)stopPlayer {
	DDLogVerbose(@"AirPlayController: stop player");

	[player stop];
	player.initialPlaybackTime = 0;
}

- (void)stop {
	DDLogVerbose(@"AirPlayController: stop");

	dispatch_sync(dispatch_get_main_queue(), ^{
		[self stopPlayer];
	});
}

- (void)setVolume:(float)volume {
    DDLogVerbose(@"AirPlayController: set volume %f", volume);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MPMusicPlayerController applicationMusicPlayer] setVolume:volume];
    });
}

- (void)setPosition:(float)position {
    DDLogVerbose(@"AirPlayController: set position %f", position);

	dispatch_async(dispatch_get_main_queue(), ^{
		if (player.playbackState ==  MPMoviePlaybackStateStopped)
			player.initialPlaybackTime = position;
		else
			player.currentPlaybackTime = position;
	});
}

- (float)position {
	__block float position;

	if (player == nil)
		return 0;

	dispatch_sync(dispatch_get_main_queue(), ^{
		position = player.currentPlaybackTime;
	});

	return position;
}

- (NSTimeInterval)duration {
	__block NSTimeInterval duration;

	if (player == nil)
		return 0;

	dispatch_sync(dispatch_get_main_queue(), ^{
		duration = player.duration;
	});

	return duration;
}

- (float)rate {
    __block float rate;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        rate = player.currentPlaybackRate;
    });
    
    return rate;
}

- (void)setRate:(float)value {
    DDLogVerbose(@"AirPlayController: rate %f", value);

	dispatch_async(dispatch_get_main_queue(), ^{
		player.currentPlaybackRate = value;
	});
}

- (BOOL)playable {
    return [player playbackState] & MPMovieLoadStatePlayable;
}

#pragma mark - DACP

- (void)updateControlsAvailability {
    BOOL isAvailable = (_dacp_client != NULL && dacp_client_is_available(_dacp_client));
    if (isAvailable) {
        dacp_client_update_playback_state(_dacp_client);
    }
}

- (void)setDacpClient:(NSValue*)pointer {
    _dacp_client = (dacp_client_p)[pointer pointerValue];
}

- (void)clientStartedRecording {
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [playerView becomeFirstResponder];
    [self updateControlsAvailability];
}

- (void)clientEndedRecording {
    _dacp_client = NULL;
}

- (void)clientEnded {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground && backgroundTask > 0) {
        raop_server_stop(self.server);
        [self performSelector:@selector(stopBackgroundTask) withObject:nil afterDelay:1.0];
    }
}

- (void)clientUpdatedArtwork:(UIImage *)image {
    NSLog(@"artwork size %@", NSStringFromCGSize(image.size));
}

- (void)updatePlaybackState {
    if (_dacp_client != NULL) {
        bool playing = (dacp_client_get_playback_state(_dacp_client) == dacp_client_playback_state_playing);
        NSLog(@"%@", playing ? @"playing" : @"stopped");
    }
}

- (void)stopBackgroundTask {
    UIBackgroundTaskIdentifier identifier = backgroundTask;
    backgroundTask = 0;
    [[UIApplication sharedApplication] endBackgroundTask:identifier];
}

UIBackgroundTaskIdentifier backgroundTask = 0;

void dacpClientControlsBecameAvailable(dacp_client_p client, void* ctx) {
    
    AirViewController* airPlayController = (__bridge AirViewController*)ctx;
    
    [airPlayController performSelectorOnMainThread:@selector(updateControlsAvailability) withObject:nil waitUntilDone:NO];
    
}

void dacpClientPlaybackStateUpdated(dacp_client_p client, enum dacp_client_playback_state state, void* ctx) {
    
    AirViewController* airPlayController = (__bridge AirViewController*)ctx;
    
    [airPlayController performSelectorOnMainThread:@selector(updatePlaybackState) withObject:nil waitUntilDone:NO];
    
}

void dacpClientControlsBecameUnavailable(dacp_client_p client, void* ctx) {
    
    AirViewController* airPlayController = (__bridge AirViewController*)ctx;
    
    [airPlayController performSelectorOnMainThread:@selector(updateControlsAvailability) withObject:nil waitUntilDone:NO];
    
}

void clientStartedRecording(raop_session_p raop_session, void* ctx) {
    
    AirViewController* airPlayController = (__bridge AirViewController*)ctx;
    
    dacp_client_p client = raop_session_get_dacp_client(raop_session);
    
    if (client != NULL) {
        
        @autoreleasepool {
            [airPlayController performSelectorOnMainThread:@selector(setDacpClient:) withObject:[NSValue valueWithPointer:client] waitUntilDone:NO];
        }
        
        dacp_client_set_controls_became_available_callback(client, dacpClientControlsBecameAvailable, ctx);
        dacp_client_set_playback_state_changed_callback(client, dacpClientPlaybackStateUpdated, ctx);
        dacp_client_set_controls_became_unavailable_callback(client, dacpClientControlsBecameUnavailable, ctx);
        
    }
    
    [airPlayController performSelectorOnMainThread:@selector(clientStartedRecording) withObject:nil waitUntilDone:NO];
    
}

void clientEndedRecording(raop_session_p raop_session, void* ctx) {
    
    AirViewController* airPlayController = (__bridge AirViewController*)ctx;
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    }
    
    [airPlayController performSelectorOnMainThread:@selector(clientEndedRecording) withObject:nil waitUntilDone:NO];
    
}

void clientEnded(raop_session_p raop_session, void* ctx) {
    
    AirViewController* airPlayController = (__bridge AirViewController*)ctx;
    
    [airPlayController performSelectorOnMainThread:@selector(clientEnded) withObject:nil waitUntilDone:NO];

}

void clientUpdatedArtwork(raop_session_p raop_session, const void* data, size_t data_size, const char* mime_type, void* ctx) {
    
    @autoreleasepool {
        AirViewController* airPlayController = (__bridge AirViewController*)ctx;
        
        UIImage* image = nil;
        
        if (strcmp(mime_type, "image/none") != 0) {
            NSData* imageData = [[NSData alloc] initWithBytes:data length:data_size];
            image = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
        }
        
        [airPlayController performSelectorOnMainThread:@selector(clientUpdatedArtwork:) withObject:image waitUntilDone:NO];
    }
}

void clientUpdatedTrackInfo(raop_session_p raop_session, const char* title, const char* artist, const char* album, void* ctx) {
    
    @autoreleasepool {
        AirViewController* airPlayController = (__bridge AirViewController*)ctx;
        
        NSString* trackTitle = [[NSString alloc] initWithCString:title encoding:NSUTF8StringEncoding];
        NSString* artistTitle = [[NSString alloc] initWithCString:artist encoding:NSUTF8StringEncoding];
        NSString* albumTitle = [[NSString alloc] initWithCString:album encoding:NSUTF8StringEncoding];
        
        NSLog(@"artist: %@\nalbum: %@\ntrack title: %@", artistTitle, albumTitle, trackTitle);
        
//        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[viewController methodSignatureForSelector:@selector(clientUpdatedTrackInfo:artistName:andAlbumTitle:)]];
//        [invocation setSelector:@selector(clientUpdatedTrackInfo:artistName:andAlbumTitle:)];
//        [invocation setTarget:viewController];
//        [invocation setArgument:&trackTitle atIndex:2];
//        [invocation setArgument:&artistTitle atIndex:3];
//        [invocation setArgument:&albumTitle atIndex:4];
//        [invocation retainArguments];
//        
//        [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];
    }
}

void newServerSession(raop_server_p server, raop_session_p new_session, void* ctx) {
    
    raop_session_set_client_started_recording_callback(new_session, clientStartedRecording, ctx);
    raop_session_set_client_ended_recording_callback(new_session, clientEndedRecording, ctx);
    raop_session_set_client_updated_artwork_callback(new_session, clientUpdatedArtwork, ctx);
    raop_session_set_client_updated_track_info_callback(new_session, clientUpdatedTrackInfo, ctx);
    raop_session_set_ended_callback(new_session, clientEnded, ctx);
    
}


@end

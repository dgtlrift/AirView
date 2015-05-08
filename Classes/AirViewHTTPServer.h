//
//  AirViewHTTPServer.h
//  AirView
//
//  Created by Łukasz Przytuła on 06.05.2015.
//
//

#import "HTTPServer.h"

@class AirViewController;
@class HTTPConfig;

@interface AirViewHTTPServer : HTTPServer

@property (nonatomic, strong) AirViewController *airplay;
@property (nonatomic, readonly) HTTPConfig *config;

@end

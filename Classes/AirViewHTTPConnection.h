//
//  AirViewHTTPConnection.h
//  AirView
//
//  Created by Łukasz Przytuła on 06.05.2015.
//
//

#import "HTTPConnection.h"

@class AirViewController;
@class AirViewServerInfo;

extern const int httpLogLevel;

@interface AirViewHTTPConnection : HTTPConnection

@property (nonatomic, strong) NSDictionary *supportedMethodsAndPaths;
@property (nonatomic, strong) NSDictionary *supportedGETEndpoints;
@property (nonatomic, strong) NSDictionary *supportedPOSTEndpoints;
@property (nonatomic, strong) NSDictionary *supportedPUTEndpoints;
@property (nonatomic, strong) AirViewServerInfo *serverInfo;
@property (nonatomic, readonly) AirViewController *airplay;

- (NSDictionary *)dictFromPlistBody;

@end

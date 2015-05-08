//
//  AirPlayMirroringHTTPServer.m
//  AirView
//
//  Created by Łukasz Przytuła on 06.05.2015.
//
//

#import "AirPlayMirroringHTTPServer.h"
#import "AirPlayMirroringHTTPConnection.h"
#import "AirViewServerInfo.h"
#import "DeviceInfo.h"

@implementation AirPlayMirroringHTTPServer

- (instancetype)init {
    self = [super init];
    if (self) {
        DeviceInfo *deviceInfo = [[DeviceInfo alloc] init];
        [self setConnectionClass:[AirPlayMirroringHTTPConnection class]];
        [self setDocumentRoot:@"/dummy"];
        [self setPort:7100];
        [self setName:[deviceInfo deviceName]];
    }
    return self;
}

@end

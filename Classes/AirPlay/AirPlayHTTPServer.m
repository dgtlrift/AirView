//
//  AirPlayHTTPServer.m
//  AirView
//
//  Created by Clément Vasseur on 12/16/10.
//  Copyright 2010 Clément Vasseur. All rights reserved.
//

#import "AirPlayHTTPServer.h"
#import "AirPlayHTTPConnection.h"
#import "AirViewServerInfo.h"
#import "DeviceInfo.h"

@implementation AirPlayHTTPServer

- (instancetype)init {
    self = [super init];
    if (self) {
        DeviceInfo *deviceInfo = [[DeviceInfo alloc] init];
        [self setType:@"_airplay._tcp."];
        [self setTXTRecordDictionary:[[AirViewServerInfo alloc] init].airPlayInfoDict];
        [self setConnectionClass:[AirPlayHTTPConnection class]];
        [self setDocumentRoot:@"/dummy"];
        [self setPort:7000];
        [self setName:[deviceInfo deviceName]];
    }
    return self;
}

@end

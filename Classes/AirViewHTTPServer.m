//
//  AirViewHTTPServer.m
//  AirView
//
//  Created by Łukasz Przytuła on 06.05.2015.
//
//

#import "AirViewHTTPServer.h"
#import "GCDAsyncSocket.h"
#import "AirViewHTTPConfig.h"

@implementation AirViewHTTPServer

- (instancetype)init {
    self = [super init];
    if (self) {
        [asyncSocket setIPv6Enabled:NO];
    }
    return self;
}

- (HTTPConfig *)config {
    return [[AirViewHTTPConfig alloc] initWithServer:self documentRoot:documentRoot queue:connectionQueue airplay:self.airplay];
}

@end

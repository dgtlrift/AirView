//
//  AirPlayMirroringHTTPConnection.m
//  AirView
//
//  Created by Łukasz Przytuła on 06.05.2015.
//
//

#import "AirPlayMirroringHTTPConnection.h"
#import "HTTPDataResponse.h"
#import "AirViewServerInfo.h"

@implementation AirPlayMirroringHTTPConnection

- (NSDictionary *)supportedGETEndpoints {
    NSMutableDictionary *dict = [[super supportedGETEndpoints] mutableCopy];
    if (dict == nil) {
        dict = [[NSMutableDictionary alloc] init];
    }
    [dict addEntriesFromDictionary:@{
                                     @"/stream.xml": @"streamPlist",
                                     }];
    return dict;
}

- (NSDictionary *)supportedPOSTEndpoints {
    NSMutableDictionary *dict = [[super supportedPOSTEndpoints] mutableCopy];
    if (dict == nil) {
        dict = [[NSMutableDictionary alloc] init];
    }
    [dict addEntriesFromDictionary:@{
                                     @"/stream": @"stream",
                                     }];
    NSLog(@"%@", dict);
    return dict;
}

- (id)GET_streamPlist {
    UIScreen *screen = [UIScreen mainScreen];
    NSDictionary *dict = @{
                           @"height": @(screen.applicationFrame.size.height),
                           @"width": @(screen.applicationFrame.size.width),
                           @"refreshRate": @(0.016666666666666666),
                           @"version": [[AirViewServerInfo alloc] init].srcvers,
                           @"overscanned": @(YES),
                           };
    
    NSError *error = nil;
    NSData *response = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    HTTPDataResponse *res = [[HTTPDataResponse alloc] initWithData:response];
    [res setHttpHeaderValue:@"text/x-apple-plist+xml" forKey:@"Content-Type"];
    return res;
}

- (id)POST_stream {
    return [[HTTPDataResponse alloc] initWithData:nil];
}

@end

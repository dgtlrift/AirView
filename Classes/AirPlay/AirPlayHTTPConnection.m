//
//  AirPlayHTTPConnection.m
//  AirView
//
//  Created by Clément Vasseur on 12/15/10.
//  Copyright 2010 Clément Vasseur. All rights reserved.
//

#import <Foundation/NSCharacterSet.h>
#import "AirPlayHTTPConnection.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "HTTPReverseResponse.h"
#import "HTTPLogging.h"
#import "DeviceInfo.h"
#import "AirViewHTTPConfig.h"
#import "AirViewServerInfo.h"

@implementation AirPlayHTTPConnection

- (NSDictionary *)supportedGETEndpoints {
    NSMutableDictionary *dict = [[super supportedGETEndpoints] mutableCopy];
    if (dict == nil) {
        dict = [[NSMutableDictionary alloc] init];
    }
    [dict addEntriesFromDictionary:@{
                                     @"/scrub": @"scrub",
                                     @"/server-info": @"serverInfo",
                                     @"/playback-info": @"playbackInfo",
                                     @"/slideshow-features": @"slideshowFeatures",
                                     }];
    return dict;
}

- (NSDictionary *)supportedPOSTEndpoints {
    NSMutableDictionary *dict = [[super supportedGETEndpoints] mutableCopy];
    if (dict == nil) {
        dict = [[NSMutableDictionary alloc] init];
    }
    [dict addEntriesFromDictionary:@{
                                     @"/reverse": @"response",
                                     @"/play": @"play",
                                     @"/stop": @"stop",
                                     @"/scrub?position=": @"scrubPosition",
                                     @"/rate?value=": @"rateValue",
                                     @"/getProperty?playbackAccessLog": @"getPropertyPlaybackAccessLog",
                                     @"/getProperty?playbackErrorLog": @"getPropertyPlaybackErrorLog",
                                     @"/volume": @"volume",
                                     }];
    return dict;
}

- (NSDictionary *)supportedPUTEndpoints {
    NSMutableDictionary *dict = [[super supportedGETEndpoints] mutableCopy];
    if (dict == nil) {
        dict = [[NSMutableDictionary alloc] init];
    }
    [dict addEntriesFromDictionary:@{
                                     @"/photo": @"photo",
                                     @"/setProperty?forwardEndTime": @"setPropertyForwardEndTime",
                                     @"/setProperty?reverseEndTime": @"setPropertyReverseEndTime",
                                     @"/setProperty?selectedMediaArray": @"setPropertySelectedMediaArray",
                                     }];
    return dict;
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    HTTPLogTrace();
    HTTPLogVerbose(@"%@[%p]: %@ (%qu) %@", THIS_FILE, self, method, requestContentLength, path);
    
    AirViewController *airplay = [self airplay];
    
    if ([method isEqualToString:@"GET"] && [path isEqualToString:@"/scrub"])
    {
        NSString *str = [NSString stringWithFormat:@"duration: %f\nposition: %f\n",
                         airplay.duration, airplay.position];
        NSLog(@"GET /scrub data: %@", str);
        NSData *response = [str dataUsingEncoding:NSUTF8StringEncoding];
        HTTPDataResponse *res = [[HTTPDataResponse alloc] initWithData:response];
        [res setHttpHeaderValue:@"text/parameters" forKey:@"Content-Type"];
        return res;
    }
    
    if ([method isEqualToString:@"GET"] && [path isEqualToString:@"/server-info"])
    {
        DeviceInfo *deviceInfo = [[DeviceInfo alloc] init];
        NSString *str = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>deviceid</key><string>%@</string><key>features</key><integer>%@</integer><key>model</key><string>%@</string><key>protovers</key><string>1.0</string><key>srcvers</key><string>%@</string></dict></plist>", [deviceInfo deviceId], [self.serverInfo featuresDec], [self.serverInfo model], [self.serverInfo srcvers]];
        
        NSData *response = [str dataUsingEncoding:NSUTF8StringEncoding];
        HTTPDataResponse *res = [[HTTPDataResponse alloc] initWithData:response];
        [res setHttpHeaderValue:@"text/x-apple-plist+xml" forKey:@"Content-Type"];
        return res;
    }
    
    if ([method isEqualToString:@"GET"] && [path isEqualToString:@"/playback-info"])
    {
        NSDictionary *dict = @{
                               @"duration": @([airplay duration]),
                               @"position": @([airplay position]),
                               @"rate": @([airplay rate]),
                               @"readyToPlay": @([airplay playable]),
                               @"playbackBufferEmpty": @(YES),
                               @"playbackBufferFull": @(NO),
                               @"playbackLikelyToKeepUp": @(NO),
                               };
        
        NSError *error = nil;
        NSData *response = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
        HTTPDataResponse *res = [[HTTPDataResponse alloc] initWithData:response];
        [res setHttpHeaderValue:@"text/x-apple-plist+xml" forKey:@"Content-Type"];
        return res;
    }
    
    if ([method isEqualToString:@"GET"] && [path isEqualToString:@"/slideshow-features"])
    {
        NSString *str = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>themes</key><array>    <dict>    <key>key</key>    <string>KenBurns</string>    <key>name</key>    <string>Ken Burns</string>    <key>transitions</key>    <array> <dict> <key>key</key> <string>None</string> <key>name</key> <string>None</string> </dict> <dict> <key>directions</key> <array> <string>up</string> <string>down</string> <string>left</string> <string>down</string> </array> <key>key</key> <string>Cube</string> <key>name</key> <string>Cube</string> </dict> <dict> <key>key</key> <string>Dissolve</string> <key>name</key> <string>Dissolve</string> </dict> <dict> <key>key</key> <string>Droplet</string> <key>name</key> <string>Droplet</string> </dict> <dict> <key>key</key> <string>FadeThruColor</string> <key>name</key> <string>Fade Through White</string> </dict> <dict> <key>directions</key> <array> <string>up</string> <string>down</string> <string>left</string> <string>down</string> </array> <key>key</key> <string>Flip</string> <key>name</key> <string>Flip</string> </dict> <dict> <key>key</key> <string>TileFlip</string> <key>name</key> <string>Mosaic Flip</string> </dict> <dict> <key>directions</key> <array> <string>up</string> <string>down</string> <string>left</string> <string>down</string> </array> <key>key</key> <string>MoveIn</string> <key>name</key> <string>Move In</string> </dict> <dict> <key>directions</key> <array> <string>left</string> <string>down</string> </array> <key>key</key> <string>PageFlip</string> <key>name</key> <string>Page Flip</string> </dict> <dict> <key>directions</key> <array> <string>up</string> <string>down</string> <string>left</string> <string>down</string> </array> <key>key</key> <string>Push</string> <key>name</key> <string>Push</string> </dict> <dict> <key>directions</key> <array> <string>up</string> <string>down</string> <string>left</string> <string>down</string> </array> <key>key</key> <string>Reveal</string> <key>name</key> <string>Reveal</string> </dict> <dict> <key>key</key> <string>Twirl</string> <key>name</key> <string>Twirl</string> </dict> <dict> <key>directions</key> <array> <string>up</string> <string>down</string> <string>left</string> <string>down</string> </array> <key>key</key> <string>Wipe</string> <key>name</key> <string>Wipe</string> </dict>    </array>    </dict>    <dict>    <key>key</key>    <string>Origami</string>    <key>name</key>    <string>Origami</string>    </dict>    <dict>    <key>key</key>    <string>Reflections</string>    <key>name</key>    <string>Reflections</string>    </dict>    <dict>    <key>key</key>    <string>Snapshots</string>    <key>name</key>    <string>Snapshots</string>    </dict>    <dict>    <key>key</key>    <string>Classic</string>    <key>name</key>    <string>Classic</string>    <key>transitions</key>    <array> <dict> <key>key</key> <string>None</string> <key>name</key> <string>None</string> </dict> <dict> <key>directions</key> <array> <string>up</string> <string>down</string> <string>left</string> <string>down</string> </array> <key>key</key> <string>Cube</string> <key>name</key> <string>Cube</string> </dict> <dict> <key>key</key> <string>Dissolve</string> <key>name</key> <string>Dissolve</string> </dict> <dict> <key>key</key> <string>Droplet</string> <key>name</key> <string>Droplet</string> </dict> <dict> <key>key</key> <string>FadeThruColor</string> <key>name</key> <string>Fade Through White</string> </dict> <dict> <key>directions</key> <array> <string>up</string> <string>down</string> <string>left</string> <string>down</string> </array> <key>key</key> <string>Flip</string> <key>name</key> <string>Flip</string> </dict> <dict> <key>key</key> <string>TileFlip</string> <key>name</key> <string>Mosaic Flip</string> </dict> <dict> <key>directions</key> <array> <string>up</string> <string>down</string> <string>left</string> <string>down</string> </array> <key>key</key> <string>MoveIn</string> <key>name</key> <string>Move In</string> </dict> <dict> <key>directions</key> <array> <string>left</string> <string>down</string> </array> <key>key</key> <string>PageFlip</string> <key>name</key> <string>Page Flip</string> </dict> <dict> <key>directions</key> <array> <string>up</string> <string>down</string> <string>left</string> <string>down</string> </array> <key>key</key> <string>Push</string> <key>name</key> <string>Push</string> </dict> <dict> <key>directions</key> <array> <string>up</string> <string>down</string> <string>left</string> <string>down</string> </array> <key>key</key> <string>Reveal</string> <key>name</key> <string>Reveal</string> </dict> <dict> <key>key</key> <string>Twirl</string> <key>name</key> <string>Twirl</string> </dict> <dict> <key>directions</key> <array> <string>up</string> <string>down</string> <string>left</string> <string>down</string> </array> <key>key</key> <string>Wipe</string> <key>name</key> <string>Wipe</string> </dict>    </array>    </dict></array></dict></plist>";
        
        NSData *response = [str dataUsingEncoding:NSUTF8StringEncoding];
        HTTPDataResponse *res = [[HTTPDataResponse alloc] initWithData:response];
        [res setHttpHeaderValue:@"text/x-apple-plist+xml" forKey:@"Content-Type"];
        return res;
    }
    
    if ([method isEqualToString:@"PUT"])
    {
        if ([path isEqualToString:@"/photo"])
        {
            HTTPLogVerbose(@"%@[%p]: PUT (%qu) %@", THIS_FILE, self, requestContentLength, path);
            
            return [[HTTPDataResponse alloc] initWithData:nil];
        }
        else if ([path isEqualToString:@"/setProperty?forwardEndTime"])
        {
            // In iOS 5 this command is accompanied by a dictionary
            //{
            //  value =     {
            //    epoch = 0;
            //    flags = 0;
            //    timescale = 0;
            //    value = 0;
            //};}
            
            NSString *error;
            NSDictionary *dict = (NSDictionary *)[NSPropertyListSerialization
                                                  propertyListFromData:[request body]
                                                  mutabilityOption:NSPropertyListImmutable
                                                  format:NULL
                                                  errorDescription:&error ];
            HTTPLogVerbose(@"%@[%p]: PUT (%qu) %@\n%@\n%@\n", THIS_FILE, self, requestContentLength, path, [dict description], error);
            return [[HTTPDataResponse alloc] initWithData:nil];
        }
        else if ([path isEqualToString:@"/setProperty?reverseEndTime"])
        {
            // In iOS 5 this command is accompanied by a dictionary
            //{
            //  value =     {
            //    epoch = 0;
            //    flags = 0;
            //    timescale = 0;
            //    value = 0;
            //};}
            
            NSString *error;
            NSDictionary *dict = (NSDictionary *)[NSPropertyListSerialization
                                                  propertyListFromData:[request body]
                                                  mutabilityOption:NSPropertyListImmutable
                                                  format:NULL
                                                  errorDescription:&error ];
            HTTPLogVerbose(@"%@[%p]: PUT (%qu) %@\n%@\n%@\n", THIS_FILE, self, requestContentLength, path, [dict description], error);
            return [[HTTPDataResponse alloc] initWithData:nil];
        }
        else if ([path isEqualToString:@"/setProperty?selectedMediaArray"])
        {
            // In iOS 5 this command is accompanied by a dictionary
            //{
            //  value =     {
            //    MediaSelectionGroupMediaType = soun;
            //    MediaSelectionOptionsPersistentID = 0;
            //  },
            //  {
            //    MediaSelectionGroupMediaType = sbtl;
            //  };}
            
            NSString *error;
            NSDictionary *dict = (NSDictionary *)[NSPropertyListSerialization
                                                  propertyListFromData:[request body]
                                                  mutabilityOption:NSPropertyListImmutable
                                                  format:NULL
                                                  errorDescription:&error ];
            HTTPLogVerbose(@"%@[%p]: PUT (%qu) %@\n%@\n%@\n", THIS_FILE, self, requestContentLength, path, [dict description], error);
            return [[HTTPDataResponse alloc] initWithData:nil];
        }
        
    }
    
    if (![method isEqualToString:@"POST"])
        return [super httpResponseForMethod:method URI:path];
    
    if ([path hasPrefix:@"/volume"])
    {
        if ([path hasPrefix:@"/volume?volume="]) {
            CGFloat volume = [[path stringByReplacingOccurrencesOfString:@"/volume?volume=" withString:@""] floatValue];
            [airplay setVolume:volume];
        }
        return [[HTTPDataResponse alloc] initWithData:nil];
    }
//    else if ([path isEqualToString:@"/fp-setup"])
//    {
//        NSString *error;
//        NSDictionary *dict = (NSDictionary *)[NSPropertyListSerialization
//                                              propertyListFromData:[request body]
//                                              mutabilityOption:NSPropertyListImmutable
//                                              format:NULL
//                                              errorDescription:&error ];
//        HTTPLogVerbose(@"%@[%p]: PUT (%qu) %@\n%@\n%@\n", THIS_FILE, self, requestContentLength, path, [dict description], error);
//        return [[HTTPDataResponse alloc] initWithData:nil];
//    }
    else if ([path isEqualToString:@"/reverse"])
    {
        return [[HTTPReverseResponse alloc] init];
    }
    else if ([path hasPrefix:@"/scrub?position="])
    {
        NSString *str = [path substringFromIndex:16];
        float value = [str floatValue];
        [airplay setPosition:value];
        
        return [[HTTPDataResponse alloc] initWithData:nil];
    }
    else if ([path hasPrefix:@"/rate?value="])
    {
        NSString *str = [path substringFromIndex:12];
        float value = [str floatValue];
        [airplay setRate:value];
        
        return [[HTTPDataResponse alloc] initWithData:nil];
    }
    else if ([path isEqualToString:@"/getProperty?playbackAccessLog"])
    {
        HTTPLogVerbose(@"%@[%p]: POST (%qu) %@", THIS_FILE, self, requestContentLength, path);
        return [[HTTPDataResponse alloc] initWithData:nil];
    }
    else if ([path isEqualToString:@"/getProperty?playbackErrorLog"])
    {
        HTTPLogVerbose(@"%@[%p]: POST (%qu) %@", THIS_FILE, self, requestContentLength, path);
        return [[HTTPDataResponse alloc] initWithData:nil];
    }
    else if ([path isEqualToString:@"/stop"])
    {
        [airplay stop];
        
        return [[HTTPDataResponse alloc] initWithData:nil];
    }
    else if ([path isEqualToString:@"/play"])
    {
        NSString *postStr = nil;
        NSData *postData = [request body];
        NSURL *url = nil;
        float start_position = 0;
        
        if ([request.allHeaderFields[@"Content-Type"] isEqualToString:@"application/x-apple-binary-plist"]) {
            NSString *error;
            NSDictionary *dict = (NSDictionary *)[NSPropertyListSerialization
                                                  propertyListFromData:[request body]
                                                  mutabilityOption:NSPropertyListImmutable
                                                  format:NULL
                                                  errorDescription:&error ];
            HTTPLogVerbose(@"%@[%p]: POST (%qu) %@\n%@\n%@\n", THIS_FILE, self, requestContentLength, path, [dict description], error);
            if ([dict.allKeys containsObject:@"Content-Location"]) {
                url = [NSURL URLWithString:dict[@"Content-Location"]];
            } else if ([dict.allKeys containsObject:@"host"] && [dict.allKeys containsObject:@"path"]) {
                url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@", dict[@"host"], dict[@"path"], nil]];
            }
            if ([dict.allKeys containsObject:@"Start-Position"]) {
                start_position = [dict[@"Start-Position"] floatValue];
            }
            if ([dict.allKeys containsObject:@"volume"]) {
                [airplay setVolume:[dict[@"volume"] floatValue]];
            }
        } else {
            NSArray *headers;
            if (postData)
                postStr = [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding];
            
            headers = [postStr componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            
            for (id h in headers) {
                NSArray *a = [h componentsSeparatedByString:@": "];
                
                if ([a count] >= 2) {
                    NSString *key = [a objectAtIndex:0];
                    NSString *value = [a objectAtIndex:1];
                    
                    if ([key isEqualToString:@"Content-Location"])
                        url = [NSURL URLWithString:value];
                    else if ([key isEqualToString:@"Start-Position"])
                        start_position = [value floatValue];
                }
            }
            
        }
        if (url) {
            [airplay play:url atRelativePosition:start_position];
        }
        
        return [[HTTPDataResponse alloc] initWithData:nil];
    }
    
    return [super httpResponseForMethod:method URI:path];
}

@end

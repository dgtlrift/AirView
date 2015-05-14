//
//  AirViewServerInfo.m
//  AirView
//
//  Created by Łukasz Przytuła on 06.05.2015.
//
//

#import "AirViewServerInfo.h"
#import "DeviceInfo.h"

@implementation AirViewServerInfo

- (NSDictionary *)airPlayInfoDict {
    DeviceInfo *deviceInfo = [[DeviceInfo alloc] init];
    return @{
            @"features": self.featuresHex,
            @"model": self.model,
            @"rmodel": [deviceInfo platform],
            @"deviceid": [deviceInfo deviceId],
            @"srcvers": self.srcvers,
            @"rrv": @"1.01",
            @"pw": @"0",
            };
}

- (NSUInteger)features {
    int video = 1;
    int photo = 1;
    int videoFairPlay = 1;
    int videoVolumeControl = 0;
    int videoHTTPLiveStreams = 1;
    int slideshow = 1;
    int screen = 1;
    int screenRotate = 1;
    int audio = 1;
    int audioRedundant = 0;
    int FPSAPv2pt5_AES_GCM = 0;
    int photoCaching = 1;
    int unknown1 = 1;
    int unknown2 = 1;
    
    return
    video                   << 0 |
    photo                   << 1 |
    videoFairPlay           << 2 |
    videoVolumeControl      << 3 |
    videoHTTPLiveStreams    << 4 |
    slideshow               << 5 |
    screen                  << 6 |
    screenRotate            << 7 |
    audio                   << 8 |
    audioRedundant          << 9 |
    FPSAPv2pt5_AES_GCM      << 10 |
    photoCaching            << 11 |
    unknown1                << 12 |
    unknown2                << 13;
}

- (NSString *)featuresHex {
    return [NSString stringWithFormat:@"0x%X", self.features];
}

- (NSString *)featuresDec {
    return [NSString stringWithFormat:@"%i", self.features];
}

- (NSString *)srcvers {
//    return @"104.29";
    return @"120.2";
//    return @"130.14";
//    return @"150.33";
}

- (NSString *)model {
    return @"AppleTV2,1";
}

- (BOOL)mirroringEnabled {
    return (self.features & (1 << 6)) > 0;
}

@end

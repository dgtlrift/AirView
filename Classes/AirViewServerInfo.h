//
//  AirViewServerInfo.h
//  AirView
//
//  Created by Łukasz Przytuła on 06.05.2015.
//
//

#import <Foundation/Foundation.h>

@interface AirViewServerInfo : NSObject

@property(nonatomic, readonly) NSDictionary *airPlayInfoDict;

@property(nonatomic, readonly) NSString *srcvers;
@property(nonatomic) NSUInteger features;
@property(nonatomic, readonly) NSString *featuresHex;
@property(nonatomic, readonly) NSString *featuresDec;
@property(nonatomic, readonly) NSString *model;
@property(nonatomic, readonly) BOOL mirroringEnabled;

@end
